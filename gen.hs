{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Data.List
import Data.List.Split
import GHC.IO.Handle
import System.Process
import Text.Regex.PCRE.Heavy

main :: IO ()
main =
  let url = (scanurlRgx txt)
   in print url

-- eval :: String -> IO String
-- eval s = do
--   (_, hOutput, _, hProcess) <- runInteractiveCommand s
--   sOutput <- hGetContents hOutput
--   foldr seq (waitForProcess hProcess) sOutput
--   return sOutput
txt2 :: String
txt2 = "https://percy.io/9b758d91/visual-regression-test/builds/12518458"

txt :: String
txt = show "yarn run v1.22.11\n$ /Users/quintenkasteel/projects/visual-regression-test/node_modules/.bin/percy snapshot snapshots-test.yaml\n[\ESC[35mpercy\ESC[39m] Percy has started!\n[\ESC[35mpercy\ESC[39m] Processing 1 snapshot...\n[\ESC[35mpercy\ESC[39m] Snapshot taken: /visual-regression-test\n[\ESC[35mpercy\ESC[39m] Finalized build #28: \ESC[34mhttps://percy.io/9b758d91/visual-regression-test/builds/12518458\ESC[39m\nDone in 4.54s.\n"

scanurlRgx :: String -> String
scanurlRgx str =
  let scanned = scan [re|(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})|] str
   in scannedToUrl scanned

scannedToUrl :: [(String, [String])] -> String
scannedToUrl = \case
  [(x, _)] ->
    case splitOn "\\" x of
      url : _ -> url
      [url] -> url
      _ -> ""
  _ -> ""
