{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE DeriveGeneric #-}

module Main where

import Data.Proxy

import Data.Function
import Data.Maybe
import Control.Monad
import Control.Monad.Reader

import Control.Exception hiding (Handler)
import System.IO.Error ( isDoesNotExistError ) 
import Network.Wai
import Network.Wai.Handler.Warp (setPort, setHost, defaultSettings, runSettings)
import Network.Wai.Middleware.RequestLogger (logStdout)
import Servant
import Servant.Server
import Servant.Auth.Server

import Data.ByteString (ByteString)
import Data.ByteArray.Encoding -- Base64
import Data.ByteArray -- Base64
import Data.Aeson (FromJSON, ToJSON, decodeFileStrict, encodeFile)

import GHC.Generics ( Generic )

import Util
import API hiding (app)
import qualified Secrets as Secrets
import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.Encoding  as T
import qualified Data.Text.IO as T

import Data.Time.Clock.POSIX
import Crypto.OTP
  
getOTPTime :: IO OTPTime
getOTPTime = getPOSIXTime >>= \t -> return (floor t :: OTPTime)

data AppCtx = AppCtx
  { rtmp       :: !Secrets.RTMP
  , otp        :: !BS.ByteString
  , cookieCfgs :: !CookieSettings
  , jwtCfgs    :: !JWTSettings
  }

data Settings = Settings
  { port   :: !Int
  , domain :: !T.Text
  } deriving (Show, Eq, Generic)

instance FromJSON Settings
instance ToJSON Settings

type AppM = ReaderT AppCtx Handler

rtmpServer :: ServerT RTMPRoute AppM
rtmpServer = postServer
  where
    postServer :: RTMPOnPublish -> AppM NoContent
    postServer RTMPOnPublish{..} = do
      (Secrets.RTMPv1 salt hashedToken) <- asks rtmp
      case convertFromBase Base64URLUnpadded $ T.encodeUtf8 name of
        Left _ -> throwAll err404
        Right (n :: ByteString) -> if unsafeHashRTMP n salt == hashedToken
          then pure NoContent
          else throwAll err404

httpServer :: ServerT HTTPRoute AppM
httpServer = authServer :<|> loginHtmlServer :<|> loginSubmitServer
  where
    authServer :: AuthResult User -> AppM NoContent
    authServer (Authenticated User) = return NoContent
    authServer _ = throwAll err401

    loginHtmlServer :: Maybe T.Text -> AppM LoginPage
    loginHtmlServer a = return $ LoginPage a

    loginSubmitServer :: LoginPost
                      -> AppM ( Headers '[ Header "Set-Cookie" SetCookie
                                         , Header "Set-Cookie" SetCookie
                                         , Header "Location"   T.Text ]
                                NoContent)
    loginSubmitServer (LoginPost attempt mUrl) = do
      c <- asks cookieCfgs
      j <- asks jwtCfgs
      o <- asks otp
      t <- liftIO getOTPTime
      let
        isCorrect = totpVerify defaultTOTPParams o t attempt
        url = fromMaybe "https://www.youtube.com/watch?v=dQw4w9WgXcQ" mUrl
      case isCorrect of
        False -> throwError err401
        True  -> do
          etoken <- liftIO $ makeJWT User j Nothing
          mApplyCookies <- liftIO $ acceptLogin c j User
          case () of
            () | (Left e) <- etoken  -> do
                       liftIO $ putStrLn $ "error making JWT " ++ show e
                       throwError err401
               | Nothing <- mApplyCookies -> do
                   liftIO $ putStrLn "Can't Apply Cookies"
                   throwError err401
               | Just applyCookies <- mApplyCookies
                 -> pure $ applyCookies $ addHeader url NoContent
    

server :: ServerT API AppM
server = rtmpServer :<|> httpServer

appAPI :: Proxy API
appAPI = Proxy

mkApp :: Context '[CookieSettings, JWTSettings]
      -> AppCtx
      -> Application
mkApp cfg ctx =
  serveWithContext appAPI cfg $
    hoistServerWithContext appAPI (Proxy :: Proxy '[CookieSettings, JWTSettings])
       (flip runReaderT ctx) server


logReqHeaders app req respond = do
  print (requestHeaders req)
  app req respond


main :: IO ()
main = do
  ss <- Secrets.readSecretsFile
  mSettings :: Maybe Settings  <-  fmap (either (const Nothing) id)
                               <$> tryJust (guard . isDoesNotExistError) $
                                     decodeFileStrict "settings.json"

  settings <- case mSettings of
      Nothing -> let s = (Settings 8081 "example.com") in do
        putStrLn "writing default settings"
        encodeFile "settings.json" s
        return s
      Just s -> return s

  case ss of
    Left e -> error "failed to open secrets"
    Right ss' -> do
      let
        jwtCfg = defaultJWTSettings (fromSecret . Secrets.signKey $ Secrets.http ss')
        ccfg   = defaultCookieSettings
          { cookieDomain = Just (T.encodeUtf8 $ domain settings)
          , cookieXsrfSetting = Nothing
          }
        cfg    = ccfg :. jwtCfg :. EmptyContext
        ctx    = AppCtx (Secrets.rtmp ss')
                        (Secrets.authKey $ Secrets.http ss')
                        (ccfg)
                        jwtCfg
      putStrLn "starting auth-server"
      runSettings (defaultSettings & setPort (port settings)
                                   & setHost "localhost")
                  (logStdout $ mkApp cfg ctx)
