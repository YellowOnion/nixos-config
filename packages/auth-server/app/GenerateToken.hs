{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as B
import qualified Data.Text as T
import qualified Data.Text.IO as T

import System.IO
import System.Environment

import qualified Secrets as Secrets

import Data.ByteArray.Encoding
import Util
import Crypto.Random


genRTMP :: IO ()
genRTMP = do 
    salt  :: B.ByteString <- getRandomBytes 16
    token :: B.ByteString <- getRandomBytes 16
    let
      hashedToken = unsafeHashRTMP token salt
      rtmpSecret = Secrets.RTMPv1 salt hashedToken

    Secrets.writeRTMPFile rtmpSecret
    rtmpSecret' <- Secrets.readRTMPFile
    case rtmpSecret' of
      Left e -> putStrLn e
      Right s -> do
        B.putStrLn $ "Token: " <> convertToBase Base64URLUnpadded token
        T.putStrLn $ "rtmp.json is: " <>
          if rtmpSecret == s
          then "valid" else "invalid"


genHTTP = do
  signKey' :: B.ByteString <- getRandomBytes 32
  authKey' :: B.ByteString <- getRandomBytes 16
  let httpSecret' = Secrets.HTTPv1 signKey' authKey'
  Secrets.writeHTTPFile httpSecret'
  httpSecret'' <- Secrets.readHTTPFile
  case httpSecret'' of
    Left e -> putStrLn e
    Right s -> do
      B.putStrLn $ "TOTP: key: " <> convertToBase Base32 authKey'
      T.putStrLn $ "http.json is: " <>
        if httpSecret' == s
        then "valid" else "invalid"
    
    
main = do
  args <- getArgs
  case args of
    [] -> putStrLn "ERROR"
    ft : _ | ft == "rtmp" -> genRTMP
           | ft == "http" -> genHTTP
