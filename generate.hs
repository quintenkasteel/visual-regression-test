#!/usr/bin/env stack
-- stack --resolver lts-12.21 script

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

import Data.Aeson (withObject) -- should be provided by yaml...
import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml

-- data Person = Person
--   { personName :: !Text,
--     personAge :: !Int
--   }
--   deriving (Show, Eq)

-- -- Could use Generic deriving, doing it by hand
-- instance ToJSON Person where
--   toJSON Person {..} =
--     object
--       [ "name" .= personName,
--         "age" .= personAge
--       ]

-- instance FromJSON Person where
--   parseJSON = withObject "Person" $ \o ->
--     Person
--       <$> o .: "name"
--       <*> o .: "age"
urls :: [String]
urls =
  [ "https://quintenkasteel.github.io/visual-regression-test"
  ]

file :: String
file = "snapshots.yaml"

main :: IO ()
main = do
  encodedUrls <- encodeUrls urls
  encodeFile file (encodedUrls :: Vector Text)
  resDecoder encodedUrls

encodeUrls :: [String] -> IO (Vector Text)
encodeUrls urls =
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
