module Main (main) where

import System.Environment (getArgs)
import ServerApp (runServer)
import CLI (runCLI)

main :: IO ()
main = do
  -- Lấy các tham số dòng lệnh
  args <- getArgs
  case args of
    -- Nếu có tham số (ví dụ: "migrate"), thì chạy CLI
    (_:_) -> runCLI args
    -- Nếu không có tham số, chạy game server
    []    -> runServer