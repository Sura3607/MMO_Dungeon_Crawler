module ServerApp (runServer) where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.MVar
import Control.Monad (forever)
import Network.Socket

import Core.Types (initialGameState, GameState(..), Command(..))
import Network.UDPServer (udpListenLoop)
import Systems.PhysicsSystem (updatePhysics)
import Network.Packet (WorldSnapshot(..))
import Data.Binary (encode)

-- 1. Import các module cần thiết
import qualified Data.ByteString.Lazy as LBS
import qualified Network.Socket.ByteString as BS -- Dùng cho bản Strict
import Data.ByteString.Lazy.Internal (toStrict) -- Dùng để chuyển đổi

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
  gameLoop sock gameStateRef

gameLoop :: Socket -> MVar GameState -> IO ()
gameLoop sock gameStateRef = forever $ do
  -- Lấy và cập nhật state
  gs <- takeMVar gameStateRef

  -- 1. Xử lý vật lý
  let newGameState = updatePhysics (fromIntegral tickInterval / 1000000.0) gs

  -- 2. Tạo snapshot và gửi cho client
  let snapshot = WorldSnapshot { wsPlayers = gsPlayers newGameState }
  let clientAddrs = uniqueClientAddrs (gsCommands gs)
  
  -- 2. Sửa lỗi tại đây
  let lazySnapshot = encode snapshot
  let strictSnapshot = toStrict lazySnapshot -- Chuyển sang Strict

  -- Gửi snapshot tới tất cả client bằng hàm của module Strict
  mapM_ (\addr -> BS.sendTo sock strictSnapshot addr) clientAddrs

  -- 3. Reset commands và tăng tick
  let finalGameState = newGameState { gsTick = gsTick gs + 1, gsCommands = [] }
  putMVar gameStateRef finalGameState
  
  threadDelay tickInterval

-- Lấy danh sách địa chỉ client không trùng lặp
uniqueClientAddrs :: [Command] -> [SockAddr]
uniqueClientAddrs = foldr (\(Command addr _) acc -> if addr `elem` acc then acc else addr : acc) []