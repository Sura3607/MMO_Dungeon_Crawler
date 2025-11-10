{-# LANGUAGE OverloadedStrings #-}

module Network.Discovery
  ( startDiscoveryLoop
  , stopDiscoveryLoop
  ) where

import Control.Concurrent (MVar, ThreadId, forkIO, killThread, threadDelay, modifyMVar_)
import Control.Monad (forever, when)
import qualified Data.ByteString.Char8 as BS
import Network.Socket.ByteString (recvFrom, sendTo)
import qualified Data.Set as Set
import Data.List.Split (splitOn)
import Text.Read (readMaybe)
import Control.Exception (try, SomeException, throwIO)

import Network.Socket ( withSocketsDo
                      , socket
                      , setSocketOption
                      , bind
                      , SockAddr(..)
                      , tupleToHostAddress
                      , getAddrInfo
                      , defaultHints
                      , AddrInfo(..)
                      , Family(AF_INET)
                      , SocketType(Datagram)
                      , defaultProtocol
                      , addrFamily
                      , addrSocketType
                      , SocketOption(Broadcast)
                      )

import Types

-- Cổng và tin nhắn phải khớp với Server
discoveryPort :: String
discoveryPort = "8889"

pingMsg :: BS.ByteString
pingMsg = "MMO_DISCOVERY_PING"

pongMsg :: BS.ByteString
pongMsg = "MMO_DISCOVERY_PONG"

-- | Dừng vòng lặp discovery cũ (nếu có)
stopDiscoveryLoop :: MVar ClientState -> IO ()
stopDiscoveryLoop cStateRef = do
  modifyMVar_ cStateRef $ \cState -> do
    case csDiscoveryThread cState of
      Nothing -> pure cState
      Just tid -> do
        putStrLn "[Discovery] Stopping old discovery thread"
        killThread tid
        pure cState { csDiscoveryThread = Nothing }

-- | Bắt đầu một vòng lặp discovery mới
startDiscoveryLoop :: MVar ClientState -> IO ()
startDiscoveryLoop cStateRef = withSocketsDo $ do
  -- Lấy địa chỉ broadcast
  addrInfo <- head <$> getAddrInfo
    (Just (defaultHints { addrFamily = AF_INET, addrSocketType = Datagram }))
    (Just "255.255.255.255") -- Địa chỉ broadcast
    (Just discoveryPort)
  
  let bcastAddr = addrAddress addrInfo

  -- 1. Tạo socket
  sock <- socket AF_INET Datagram defaultProtocol
  setSocketOption sock Broadcast 1
  -- Bind để nhận replies on any local address (ephemeral port)
  bind sock (SockAddrInet 0 (tupleToHostAddress (0,0,0,0)))

  putStrLn "[Discovery] Starting discovery loop"
  
  -- 2. Fork thread chính
  tid <- forkIO $ do
    -- 2a. Fork thread Pinger (Gửi Ping mỗi 3s)
    _ <- forkIO $ forever $ do
      _ <- sendTo sock pingMsg bcastAddr
      -- Mỗi lần ping, xóa danh sách phòng cũ
      modifyMVar_ cStateRef (clearDiscoveredRooms)
      threadDelay (3 * 1000 * 1000) -- 3 giây
      
    -- 2b. Vòng lặp Listener (Chặn và nhận Pong)
    forever $ do
      eResult <- try (recvFrom sock 1024) :: IO (Either SomeException (BS.ByteString, SockAddr))
      case eResult of
        Left _ -> pure () -- Lỗi (ví dụ: socket bị đóng), vòng lặp sẽ dừng
        Right (msg, _) ->
          -- 3. Xử lý Pong
          when (pongMsg `BS.isPrefixOf` msg) $ do
            case parsePong msg of
              Nothing -> putStrLn $ "[Discovery] Received malformed Pong: " ++ BS.unpack msg
              Just room -> modifyMVar_ cStateRef (addDiscoveredRoom room)

  -- 4. Lưu ThreadId để có thể kill
  modifyMVar_ cStateRef $ \cState -> 
    pure cState { csDiscoveryThread = Just tid }

-- | Helper: Xóa danh sách phòng cũ
clearDiscoveredRooms :: ClientState -> IO ClientState
clearDiscoveredRooms cState =
  case csState cState of
    S_RoomSelection rsd -> 
      pure cState { csState = S_RoomSelection (rsd { rsdDiscoveredRooms = Set.empty }) }
    _ -> pure cState

-- | Helper: Thêm phòng mới vào danh sách
addDiscoveredRoom :: DiscoveredRoom -> ClientState -> IO ClientState
addDiscoveredRoom room cState =
  case csState cState of
    S_RoomSelection rsd ->
      let newSet = Set.insert room (rsdDiscoveredRooms rsd)
      in pure cState { csState = S_RoomSelection (rsd { rsdDiscoveredRooms = newSet }) }
    _ -> pure cState

-- | Helper: Parse "MMO_DISCOVERY_PONG|ROOM_ID|PLAYER_COUNT"
parsePong :: BS.ByteString -> Maybe DiscoveredRoom
parsePong msg =
  case splitOn "|" (BS.unpack msg) of
    [_, roomId, sCount] ->
      case readMaybe sCount of
        Nothing -> Nothing
        Just count -> Just (DiscoveredRoom roomId count)
    _ -> Nothing