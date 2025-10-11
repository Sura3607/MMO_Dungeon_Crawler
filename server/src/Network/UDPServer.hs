{-# LANGUAGE ScopedTypeVariables #-}

module Network.UDPServer (udpListenLoop) where

import Control.Concurrent.MVar (MVar, modifyMVar_)
import Control.Exception (SomeException, catch)
import Control.Monad (forever)
import Data.Binary (decodeOrFail)
import Network.Socket

-- 1. Import module ByteString STRICT và hàm chuyển đổi
import qualified Network.Socket.ByteString as BS (recvFrom)
import qualified Data.ByteString.Lazy as LBS
import Data.ByteString.Lazy.Internal (fromStrict)

-- Import các kiểu dữ liệu cần thiết
import Core.Types (Command(..), GameState(..))
import Types.Player (PlayerCommand)

-- Vòng lặp chính để lắng nghe các gói tin UDP
udpListenLoop :: Socket -> MVar GameState -> IO ()
udpListenLoop sock gameStateRef = forever $ do
  -- 2. Dùng BS.recvFrom để nhận một Strict ByteString
  (strictMsg, addr) <- BS.recvFrom sock 8192 `catch` \(e :: SomeException) -> do
    putStrLn $ "Error in recvFrom: " ++ show e
    -- Return a dummy value to avoid crashing the loop
    pure (mempty, SockAddrInet 0 0)

  -- Chỉ xử lý nếu nhận được tin nhắn
  if not (LBS.null (fromStrict strictMsg))
    then do
      -- 3. Chuyển đổi từ Strict sang Lazy để decode
      let lazyMsg = fromStrict strictMsg
      case decodeOrFail lazyMsg of
        Left _ -> pure () -- Bỏ qua gói tin không hợp lệ
        Right (_, _, command) -> do
          -- Dùng modifyMVar_ để cập nhật trạng thái một cách an toàn
          modifyMVar_ gameStateRef $ \gs -> do
            let newCommand = Command addr (command :: PlayerCommand)
            let newCommands = newCommand : gsCommands gs
            pure gs { gsCommands = newCommands }
    else pure ()