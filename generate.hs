{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

import Data.List.Split
import Data.String.Interpolate
import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml
import GHC.IO.Handle
import System.Process
import Text.Regex.PCRE.Heavy

last' :: [a] -> a
last' ys = foldl1 (\_ -> \x -> x) ys

first' :: [a] -> a
first' ys = last' (reverse ys)

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
        token = "7e4576385b692083f8054052bc5cb0c80ea5c8fdb486354d2fb74bd6cc53711b"
      }
  ]

rgx :: Regex
rgx = [re|(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})|]

scanurlRgx :: String -> String
scanurlRgx str =
  let scanned = scan rgx (show str)
   in first' $ splitOn "\\" $ fst $ first' scanned

snapshot :: Domain -> IO String
snapshot Domain {name, token} =
  eval [i|#{percy_token token} yarn percy snapshot #{file name}|]

file :: String -> String
file name = [i|snapshots-#{name}.yaml|]

percy_token :: String -> String
percy_token value = [i|PERCY_TOKEN=#{value}|]

awaitBuildCmd :: Domain -> String -> IO ()
awaitBuildCmd Domain {token} snapShotRes =
  let buildNumber = last' $ splitOn "/" $ scanurlRgx snapShotRes
   in callCommand [i|#{percy_token token} yarn percy build:wait --build=#{buildNumber}|]

main :: IO ()
main = do
  _ <- callCommand "yarn install"
  _ <- runCmds
  return ()

runCmds :: IO [()]
runCmds =
  traverse
    ( \domain@(Domain {name, url}) -> do
        encodedUrls <- encodeUrls [url]
        encodeFile (file name) encodedUrls
        resDecoder encodedUrls name
        snapShotRes <- snapshot domain
        awaitBuildCmd domain snapShotRes
    )
    urls

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

eval :: String -> IO String
eval s = do
  (_, hOutput, _, hProcess) <- runInteractiveCommand s
  sOutput <- hGetContents hOutput
  _ <- foldr seq (waitForProcess hProcess) sOutput
  return sOutput
