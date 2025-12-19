#!/usr/bin/env nix-shell
#! nix-shell -i runghc -p 'ghc.withPackages (ps: [ ps.typed-process ps.http-conduit ps.optics ps.aeson-optics ps.base64 ps.base16 ps.natural-sort ps.aeson-pretty])'

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedLabels      #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE PackageImports        #-}
{-# LANGUAGE RecordWildCards       #-}
{- HLINT ignore "Use camelCase" -}

module Main where

import           Optics
import           Optics.Operators.Unsafe ((^?!))
import           Data.Aeson.Optics
import           Data.Aeson.Encode.Pretty (encodePretty)

import           Data.Aeson
import           GHC.Generics (Generic)

import           Control.Monad (forM)
import           Control.Applicative ((<|>))

import           Data.List (sortBy)
import           Data.Maybe
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString as BS

import "base64"  Data.ByteString.Base64
import           Data.Base64.Types
import "base16"  Data.ByteString.Base16
import           Data.Base16.Types

import           System.Process.Typed
import           Network.HTTP.Simple

import           Prelude hiding (compare, comparing)
import           Algorithms.NaturalSort (compare)

data Release' = Release'
  { url    :: T.Text
  , name   :: T.Text
  , digest :: Maybe T.Text
  } deriving (Eq, Show, Generic)

data Release = Release
  { url    :: T.Text
  , name   :: T.Text
  , hash   :: SRI
  , sha256 :: T.Text
  } deriving (Eq, Show, Generic)

instance ToJSON Release where
  toEncoding = genericToEncoding defaultOptions

-- | I don't need this much pedantic type safety...
--   But I wanted explore optics more
newtype SRI = SRI (Base64 'StdPadded T.Text) deriving (Eq, Show, Generic)

instance ToJSON SRI
instance ToJSON (Base64 'StdPadded T.Text) where
  toJSON = extractBase64 . fmap toJSON


extractSri (SRI a) = a
assertSri = SRI

encodeSri = assertSri . fmap ("sha256-"<>)

decodeSri = fmap (fromJust . T.stripPrefix "sha256-") . extractSri

asSri = iso assertSri extractSri
_sri = iso encodeSri decodeSri

-- | I need Base16 -> Base64
-- | tf. assertBase16 ->  Base16Decode -> Base64Encode -> extractBase64

asBase16 = iso assertBase16 extractBase16
asBase64 = iso assertBase64 extractBase64

_b16 = iso decodeBase16' (fmap T.decodeUtf8 . encodeBase16')

_b64 = iso
          (decodeBase64 @'StdPadded . fmap T.encodeUtf8)
          (fmap T.decodeUtf8 . encodeBase64')


rELEASE_URL = "https://api.github.com/repos/"
            ++ "GloriousEggroll/proton-ge-custom/releases"
hEADERS = [ ("Accept","application/vnd.github+json")
          , ("User-Agent","YellowOnion/nixos-config") ]

-- | Dead Code
addToNixStore _rel = let rel = T.unpack _rel :: String
  in readProcessStdout
  (proc "nix"
        [ "store", "prefetch-file"
        , "--unpack"
        , "--json"
        , "--hash-type", "sha256"
        , "https://github.com/GloriousEggroll/"
          ++ "proton-ge-custom/releases/download/"
          ++ rel ++ "/" ++ rel ++ ".tar.gz"
        ])

processRelease (Release'{..}) = do
  digest' <- digest
  hash'   <- T.stripPrefix "sha256:" digest'
          <|> error "WTF no digest header"
  return $ Release
             url
             name
             (view (asBase16 % _b16 % re _b64 % _sri) hash')
             hash'

comparing p x y = compare (p x) (p y)

main = do
  req       <- setRequestHeaders hEADERS <$> parseRequest rELEASE_URL
  response  <- getResponseBody           <$> httpLBS req
  let assets = response
             -- | Concat all "assets" lists together
             & toListOf (values % key "assets" % _Array % traversed)
             -- | Drop files that are probably not what we want
             & filter (T.isSuffixOf ".tar.zst" . (^?! key "name" % _String))
             -- | sort them
             & (sortBy . comparing) (^?! key "name" % _String)
      toRelease =
        Release' <$> (^?! key "browser_download_url" % _String)
                 <*> (^?! key "name"                 % _String)
                 <*> (^?  key "digest"               % _String)
      releases = mapMaybe (processRelease . toRelease) assets
  LBS.writeFile "versions.json"
    . encodePretty $ object $ foldMap
    (\r ->
       [(r ^?! #name % _Key)
         .= object [ "hash" .= (r ^. #hash)
                   , "url" .= (r ^. #url)
                   ]
       ])
    releases
