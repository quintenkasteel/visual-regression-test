#!/usr/bin/env stack
-- stack --resolver lts-12.21 script

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

import Data.String.Interpolate
import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml
import System.Process

data Domain = Domain
  { name :: String,
    url :: String,
    token :: String
  }
  deriving (Eq, Show)

urls :: [Domain]
urls =
  [ Domain
      { name = "test",
        url = "https://quintenkasteel.github.io/visual-regression-test",
        token = "33ae625f5325f75d6e7166bc913224399f4a411ee23f9e5d7f118b4f7840e20e"
      }
  ]

command :: Domain -> IO ()
command Domain {name, token} =
  callCommand [i|#{percy_token token} yarn percy snapshot #{file name}|]

file :: String -> String
file name = [i|snapshots-#{name}.yaml|]

percy_token :: String -> String
percy_token value = [i|PERCY_TOKEN=#{value}|]

main :: IO ()
main = do
  _ <- callCommand "yarn install"
  _ <-
    traverse
      ( \domain'@(Domain {name, url}) -> do
          encodedUrls <- encodeUrls [url]
          encodeFile (file name) encodedUrls
          resDecoder encodedUrls name
          command domain'
      )
      urls
  return ()

encodeUrls :: [String] -> IO (Vector Text)
encodeUrls urls' =
  case decodeEither' (encode urls') of
    Left exc -> error $ "Could not parse: " ++ show exc
    Right urls_ -> return urls_

resDecoder :: Vector Text -> String -> IO ()
resDecoder encodedUrls name = do
  res <- decodeFileEither (file name)
  case res of
    Left exc -> error $ "Could not parse file: " ++ show exc
    Right encodedUrls2
      | encodedUrls == encodedUrls2 -> mapM_ print encodedUrls
      | otherwise -> error "Mismatch!"
