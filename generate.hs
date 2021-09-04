{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

import Control.Exception
import Data.List.Split
import Data.String.Interpolate
import Data.Text (Text)
import Data.Vector (Vector)
import Data.Yaml
import GHC.IO.Handle
import System.Environment
import System.Exit
import System.Process
import Text.Regex.PCRE.Heavy

main :: IO ()
main = do
  _ <- runCmds
  return ()

-- DOMAINS
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

-- CMDS
runCmds :: IO [()]
runCmds = do
  _ <- callCommand "yarn install"
  traverse
    ( \domain@(Domain {name, url}) -> do
        encodedUrls <- encodeUrls [url]
        encodeFile (file name) encodedUrls
        resDecoder encodedUrls name
        snapShotRes <- snapshotCmd domain
        awaitBuildCmd domain snapShotRes
    )
    urls

awaitBuildCmd :: Domain -> String -> IO ()
awaitBuildCmd Domain {token} snapShotRes = do
  setEnv "PERCY_TOKEN" token
  runCmdWithWarning
    "yarn"
    [ "percy",
      "build:wait",
      [i|--build=#{buildNumber snapShotRes}|],
      "--fail-on-changes"
    ]

--  callCommand
--     [i|#{percy_token token} yarn percy build:wait --build=#{buildNumber} --fail-on-changes|]
buildNumber :: String -> String
buildNumber snapShotRes = last' $ splitOn "/" $ scanurlRgx snapShotRes

try' :: IO a -> IO (Either IOException a)
try' = try

runCmdWithWarning :: String -> [String] -> IO ()
runCmdWithWarning str args = do
  result <- try' $ createProcess (proc str args)
  case result of
    Left ex -> putStrLn $ "::warning ::Error:" ++ show ex
    Right (_, _, _, p) -> do
      exitCode <- waitForProcess p
      exitWith exitCode

snapshotCmd :: Domain -> IO String
snapshotCmd Domain {name, token} =
  eval [i|#{percy_token token} yarn percy snapshot #{file name}|]

file :: String -> String
file name = [i|snapshots-#{name}.yaml|]

percy_token :: String -> String
percy_token value = [i|PERCY_TOKEN=#{value}|]

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

-- UTILS
last' :: [a] -> a
last' ys = foldl1 (\_ -> \x -> x) ys

first' :: [a] -> a
first' ys = last' (reverse ys)

-- RGX
rgx :: Regex
rgx = [re|(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})|]

scanurlRgx :: String -> String
scanurlRgx str =
  let scanned = scan rgx (show str)
   in first' $ splitOn "\\" $ fst $ first' scanned
