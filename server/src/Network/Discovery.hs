{-# LANGUAGE OverloadedStrings #-}

module Network.Discovery (startDiscoveryService) where

import Control.Concurrent (forkIO, MVar, readMVar, threadDelay)
import Control.Monad (forever, when)
import Network.Socket ( withSocketsDo
                      , socket
                      , Socket
                      , setSocketOption
                      , bind
                      , SockAddr(..)
                      , tupleToHostAddress
                      , defaultProtocol
                      , PortNumber
                      , SocketOption(ReuseAddr)
                      , SocketType(Datagram)
                      , Family(AF_INET)
                      )
import qualified Data.Map as Map
import qualified Data.ByteString.Char8 as BS
import Core.Types (ServerState(..), Room(..))
import Network.Socket.ByteString (recvFrom, sendTo)

-- Cổng riêng cho discovery
discoveryPort :: PortNumber
discoveryPort = 8889

pingMsg :: BS.ByteString
pingMsg = "MMO_DISCOVERY_PING"

pongMsg :: BS.ByteString
pongMsg = "MMO_DISCOVERY_PONG"

startDiscoveryService :: MVar ServerState -> IO ()
startDiscoveryService sStateRef = withSocketsDo $ do
  -- 1. Tạo socket
  sock <- socket AF_INET Datagram defaultProtocol
  setSocketOption sock ReuseAddr 1
  -- 2. Bind vào cổng discovery on any interface
  bind sock (SockAddrInet discoveryPort (tupleToHostAddress (0,0,0,0)))
  
  putStrLn $ "[Discovery] Listening for pings on port " ++ show discoveryPort
  
  -- 3. Vòng lặp lắng nghe Ping
  _ <- forkIO $ forever $ do
    (msg, clientAddr) <- recvFrom sock 1024
    
    -- 4. Nếu là Ping, gửi lại Pong
    when (msg == pingMsg) $ do
      -- Đọc state server để lấy danh sách phòng
      sState <- readMVar sStateRef
      let publicRooms = Map.filter roomIsPublic (ssRooms sState)
      
      -- Gửi Pong cho từng phòng public
      mapM_ (sendPong sock clientAddr) (Map.elems publicRooms)
      
  pure ()

-- | Gửi thông tin của 1 phòng về cho client
sendPong :: Socket -> SockAddr -> Room -> IO ()
sendPong sock clientAddr room = do
  let playerCount = Map.size (roomPlayers room)
  -- Format: "MMO_DISCOVERY_PONG|ROOM_ID|PLAYER_COUNT"
  let reply = BS.concat [ pongMsg, "|", BS.pack (roomMsgId room), "|", BS.pack (show playerCount) ]
  _ <- sendTo sock reply clientAddr
  pure ()