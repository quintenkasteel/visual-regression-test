#!/usr/bin/env stack
-- stack --resolver lts-12.21 script

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml

urls :: [String]
urls =
  [ "https://hanos-accept.floydhamilton.net/vacatures",
    "https://welkoop-accept.floydhamilton.net/vacatures"
  ]

file :: String
file = "snapshots.yaml"

main :: IO ()
main = do
  encodedUrls <- encodeUrls
  encodeFile file encodedUrls
  resDecoder encodedUrls

encodeUrls :: IO (Vector Text)
encodeUrls =
  case decodeEither' (encode urls) of
    Left exc -> error $ "Could not parse: " ++ show exc
    Right urls' -> return urls'

resDecoder :: Vector Text -> IO ()
resDecoder encodedUrls = do
  res <- decodeFileEither file
  case res of
    Left exc -> error $ "Could not parse file: " ++ show exc
    Right encodedUrls2
      | encodedUrls == encodedUrls2 -> mapM_ print encodedUrls
      | otherwise -> error "Mismatch!"
