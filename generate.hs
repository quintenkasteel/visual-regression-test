#!/usr/bin/env stack
-- stack --resolver lts-12.21 script

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

import Data.Aeson (withObject) -- should be provided by yaml...
import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml

data Person = Person
  { personName :: !Text,
    personAge :: !Int
  }
  deriving (Show, Eq)

-- Could use Generic deriving, doing it by hand
instance ToJSON Person where
  toJSON Person {..} =
    object
      [ "name" .= personName,
        "age" .= personAge
      ]

instance FromJSON Person where
  parseJSON = withObject "Person" $ \o ->
    Person
      <$> o .: "name"
      <*> o .: "age"

main :: IO ()
main = do
  let bs =
        encode
          [ Person "Alice" 25,
            Person "Bob" 30,
            Person "Charlie" 35
          ]
  people <-
    case decodeEither' bs of
      Left exc -> error $ "Could not parse: " ++ show exc
      Right people -> return people

  let fp = "people.yaml"
  encodeFile fp (people :: Vector Person)
  res <- decodeFileEither fp
  case res of
    Left exc -> error $ "Could not parse file: " ++ show exc
    Right people2
      | people == people2 -> mapM_ print people
      | otherwise -> error "Mismatch!"
