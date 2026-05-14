{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Secrets ( Secrets(..)
               , RTMP(..)
               , HTTP(..)
               , readSecretsFile
               , readRTMPFile
               , readHTTPFile
               , writeRTMPFile
               , writeHTTPFile
               ) where

import GHC.Generics ( Generic )

import qualified Data.Aeson as JSON ( Value(String) )
import qualified Data.ByteString as BS
import qualified Data.Text  as T

import Data.Aeson
    ( eitherDecodeFileStrict,
      withText,
      FromJSON(parseJSON),
      ToJSON(toJSON),
      encodeFile )

import Data.Text.Encoding ( decodeUtf8, encodeUtf8 )
import Data.ByteArray.Encoding

import Control.Applicative
import qualified Data.Bifunctor as BF

import Util
import Debug.Trace
import System.IO.Error (isDoesNotExistError)
import Control.Monad (guard, join)
import Control.Exception (handle, displayException, SomeException (SomeException))

data Secrets = Secrets
  { rtmp :: !RTMP
  , http  :: !HTTP
  } deriving (Show, Eq, Generic)

data RTMP = RTMPv1
  { salt        :: !BS.ByteString
  , hashedToken :: !BS.ByteString
  } deriving (Show, Eq, Generic)

data HTTP = HTTPv1
  { signKey :: !BS.ByteString
  , authKey :: !BS.ByteString
  } deriving (Show, Eq, Generic)


instance ToJSON BS.ByteString where
  toJSON = JSON.String . decodeUtf8 . convertToBase Base64URLUnpadded

instance FromJSON BS.ByteString where
  parseJSON = withText "ByteString" $ \v ->
    case toBs v of
      Left e -> fail e
      Right r -> return r
    where
      toBs = convertFromBase Base64URLUnpadded . encodeUtf8

instance ToJSON Secrets
instance FromJSON Secrets

instance FromJSON RTMP
instance ToJSON RTMP

instance FromJSON HTTP
instance ToJSON HTTP


safeDecodeFile :: FromJSON a => FilePath -> IO (Either String a)
safeDecodeFile f = (handle (\(e :: SomeException) -> return . Left $ show e) (eitherDecodeFileStrict f))


__readFile :: FromJSON b => FilePath -> IO (Either String b)
__readFile fn =  (eitherDecodeFileStrict $ "/var/lib/auth-server/" <> fn)
             <|> (eitherDecodeFileStrict fn)
             <|> return (Left $ "Can't Load: " <> fn)

readRTMPFile :: IO (Either String RTMP)
readRTMPFile = __readFile "rtmp.json"

writeRTMPFile :: RTMP -> IO ()
writeRTMPFile = encodeFile "rtmp.json"

readHTTPFile :: IO (Either String HTTP)
readHTTPFile = __readFile "http.json" 
     
writeHTTPFile :: HTTP -> IO ()
writeHTTPFile = encodeFile "http.json"

readSecretsFile :: IO (Either String Secrets)
readSecretsFile = liftA2 Secrets.Secrets <$> Secrets.readRTMPFile <*> Secrets.readHTTPFile
