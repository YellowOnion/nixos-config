{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DuplicateRecordFields #-}

module API where
import Data.Text (Text)


import Data.Aeson

import GHC.Generics ( Generic )
import Web.FormUrlEncoded (FromForm, ToForm)
import Data.Data (Typeable)

import Data.Word 
import Servant.HTML.Blaze
import Servant.Auth.Server
import Servant.API
  
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Text.Blaze


data RTMPOnPublish = RTMPOnPublish
  { call     :: Maybe Text
  , addr     :: Maybe Text
  , clientid :: Maybe Text
  , app      :: Maybe Text
  , flashVer :: Maybe Text
  , swfUrl   :: Maybe Text
  , tcUrl    :: Maybe Text
  , pageUrl  :: Maybe Text
  , name     :: Text
  } deriving (Show, Eq, Generic, Typeable)
instance FromForm RTMPOnPublish

data LoginPost = LoginPost
  { attempt :: Word32
  , returnTo :: Maybe Text
  } deriving (Eq, Show, Generic)

instance FromForm LoginPost
instance ToForm LoginPost

data LoginPage = LoginPage
  { returnTo :: Maybe Text
  } deriving (Eq, Show, Generic)

data User      = User      deriving (Eq, Show, Generic)

instance ToJSON User
instance ToJWT User
instance FromJSON User
instance FromJWT User

instance ToMarkup LoginPage where
  toMarkup (LoginPage mUrl) = H.docTypeHtml $ do
    H.head $ do
      H.title "LOGIN"
    H.body $ do
     H.p "hello my friend"
     H.form ! A.action "/login" ! A.method "POST" $ do
       case mUrl of
         Nothing -> pure ()
         Just url -> H.input ! A.type_ "hidden" ! A.name "returnTo"
               ! A.value (toValue url)
       H.input ! A.type_ "text" ! A.name "attempt"
               ! A.minlength "6" ! A.maxlength "6"


type RTMPRoute = "rtmp" :> ReqBody '[FormUrlEncoded] RTMPOnPublish
                           :> Post '[PlainText] NoContent

type AuthRoute = "auth" :> Auth '[Cookie] User
                           :> Get '[PlainText] NoContent

type LoginRoute = "login"
  :> (QueryParam "returnTo" Text :> Get '[HTML] LoginPage
      :<|> (ReqBody '[FormUrlEncoded] LoginPost
            :> Verb 'POST 303 '[PlainText]
               (Headers '[ Header "Set-Cookie" SetCookie
                         , Header "Set-Cookie" SetCookie
                         , Header "Location"   Text ]
                 NoContent)))

type HTTPRoute = AuthRoute :<|> LoginRoute

type API = RTMPRoute :<|> HTTPRoute
