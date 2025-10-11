-- client/src/Main.hs
module Main where

import Network.Socket
import Data.Binary (encode)
import Control.Concurrent (threadDelay)

-- Import module cho chuỗi byte 'Lazy'
import qualified Data.ByteString.Lazy as LBS
-- Import module cho chuỗi byte 'Strict'
import qualified Network.Socket.ByteString as BS

-- Import các kiểu dữ liệu dùng chung
import Types.Player (PlayerCommand(..))
import Types.Common (Vec2(..))

main :: IO ()
main = withSocketsDo $ do
  putStrLn "Starting client..."
  -- Tạo socket cho giao thức UDP
  sock <- socket AF_INET Datagram defaultProtocol

  let hints = defaultHints { addrSocketType = Datagram }
  addr <- head <$> getAddrInfo (Just hints) (Just "127.0.0.1") (Just "8888")

  putStrLn "Sending packets to server..."
  loop sock (addrAddress addr)
  where
    loop :: Socket -> SockAddr -> IO ()
    loop sock serverAddr = do
      -- Tạo câu lệnh di chuyển
      let moveVector = Vec2 { vecX = 1.0, vecY = 0.5 }
      let command = Move moveVector
      
      -- 1. Mã hóa câu lệnh thành một chuỗi byte LAZY
      let lazyMsg = encode command
      
      -- 2. Chuyển chuỗi LAZY thành STRICT và gửi đi bằng BS.sendTo
      _ <- BS.sendTo sock (LBS.toStrict lazyMsg) serverAddr
      
      putStrLn $ "Sent command: " ++ show command

      threadDelay (2 * 1000000) -- Chờ 2 giây
      loop sock serverAddr