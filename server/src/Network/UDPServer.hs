module Network.UDPServer where

import Network.Socket
-- Import module cho chuỗi byte 'Strict' và đặt tên là BS
import qualified Network.Socket.ByteString as BS
-- Import module cho chuỗi byte 'Lazy' để chuyển đổi
import qualified Data.ByteString.Lazy as LBS
import Data.Binary (decode)
import Control.Monad (forever)
import Control.Concurrent.MVar (MVar, modifyMVar_)
import Core.Types (GameState(..))
import Types.Player (PlayerCommand)

udpListenLoop :: Socket -> MVar GameState -> IO ()
udpListenLoop sock gameStateRef = forever $ do
  -- Dùng BS.recvFrom (từ module Strict), nó trả về một chuỗi byte Strict
  (strictMsg, addr) <- BS.recvFrom sock 1024

  -- Chuyển đổi chuỗi byte Strict thành Lazy trước khi decode
  let command = decode (LBS.fromStrict strictMsg) :: PlayerCommand

  -- Cập nhật GameState một cách an toàn
  modifyMVar_ gameStateRef $ \gs -> do
    let newCommands = (addr, command) : gsCommands gs
    pure gs { gsCommands = newCommands }