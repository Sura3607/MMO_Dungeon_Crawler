module ServerApp (runServer) where

import Control.Concurrent (forkIO, threadDelay)
-- Sửa lại dòng import này để bao gồm cả kiểu MVar
import Control.Concurrent.MVar (MVar, newMVar, takeMVar, putMVar)
import Control.Monad (forever)
import Network.Socket
import Core.Types (initialGameState, GameState(..))
import Network.UDPServer (udpListenLoop)

tickRate :: Int
tickRate = 30

tickInterval :: Int
tickInterval = 1000000 `div` tickRate

runServer :: IO ()
runServer = withSocketsDo $ do
  putStrLn "Starting MMO Dungeon Crawler server..."

  gameStateRef <- newMVar initialGameState

  sock <- socket AF_INET Datagram defaultProtocol
  bind sock (SockAddrInet 8888 0)
  _ <- forkIO $ udpListenLoop sock gameStateRef
  putStrLn "UDP Server is listening on port 8888"

  putStrLn $ "Starting game loop with tick rate: " ++ show tickRate
  gameLoop gameStateRef

-- Dòng này bây giờ sẽ hợp lệ
gameLoop :: MVar GameState -> IO ()
gameLoop gameStateRef = forever $ do
  gs <- takeMVar gameStateRef

  if not (null (gsCommands gs))
    then putStrLn $ "Tick " ++ show (gsTick gs) ++ ": Processing " ++ show (length $ gsCommands gs) ++ " commands."
    else pure ()

  let newGameState = gs
        { gsTick = gsTick gs + 1
        , gsCommands = []
        }

  putMVar gameStateRef newGameState

  threadDelay tickInterval