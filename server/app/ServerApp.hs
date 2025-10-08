module ServerApp (runServer) where

import qualified Control.Concurrent as C

runServer :: IO ()
runServer = do
  putStrLn "Starting MMO Dungeon Crawler server..."
  -- Initialize systems: config, DB, network, tick loop
  C.threadDelay (1 * 1000000)
  putStrLn "Server initialized (placeholder)"