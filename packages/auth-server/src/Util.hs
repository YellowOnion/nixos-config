{-# LANGUAGE OverloadedStrings #-}
module Util where

import qualified Data.ByteString        as B

import qualified Crypto.KDF.Argon2 as Argon2

import Crypto.Error (throwCryptoError)
import Data.Maybe (fromJust)
import Data.Either (fromRight)

unsafeHashRTMP password salt = throwCryptoError $ Argon2.hash Argon2.defaultOptions password salt 16
