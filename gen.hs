{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Control.Exception
import Data.List
import Data.List.Split
import GHC.IO.Handle
import System.Environment
import System.Process
import Text.Regex.PCRE.Heavy

-- [i|#{percy_token token} yarn percy build:wait --build=#{buildNumber} --fail-on-changes|]

main :: IO ()
main = do
  setEnv "PERCY_TOKEN" "7e4576385b692083f8054052bc5cb0c80ea5c8fdb486354d2fb74bd6cc53711b"
  runCmdWithWarning
    "yarn"
    [ "percy",
      "snapshot",
      "snapshots-test.yaml"
      -- "build:wait",
      -- "--build=abc",
      -- "--fail-on-changes"
    ]

try' :: IO a -> IO (Either IOException a)
try' = try

runCmdWithWarning :: String -> [String] -> IO ()
runCmdWithWarning str args = do
  result <- try' $ createProcess (proc str args)
  case result of
    Left ex -> putStrLn $ "::warning ::Error:" ++ show ex
    Right (_, _, _, p) -> return ()
