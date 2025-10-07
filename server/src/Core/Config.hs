module Core.Config where

import System.IO (readFile)

loadConfig :: FilePath -> IO String
loadConfig path = readFile path
