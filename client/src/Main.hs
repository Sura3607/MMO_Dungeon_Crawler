module Main where

import Network.Socket
-- Import module cho chuỗi byte 'Strict' và đặt tên là BS
import qualified Network.Socket.ByteString as BS
-- Import module cho chuỗi byte 'Lazy' và đặt tên là LBS
import qualified Data.ByteString.Lazy as LBS
import Data.Binary (encode)
import Control.Concurrent (threadDelay)
import Types.Player (PlayerCommand(..))

main :: IO ()
main = withSocketsDo $ do
  putStrLn "Starting client..."
  sock <- socket AF_INET Datagram defaultProtocol

  let hints = defaultHints { addrSocketType = Datagram }
  addr <- head <$> getAddrInfo (Just hints) (Just "127.0.0.1") (Just "8888")

  putStrLn "Sending packets to server..."
  loop sock (addrAddress addr)
  where
    loop :: Socket -> SockAddr -> IO ()
    loop sock serverAddr = do
      let command = Move { velX = 10.0, velY = 5.0 }
      -- encode tạo ra một chuỗi byte LAZY
      let lazyMsg = encode command

      -- Dùng BS.sendTo (từ module Strict)
      -- và chuyển đổi chuỗi byte Lazy thành Strict bằng LBS.toStrict
      _ <- BS.sendTo sock (LBS.toStrict lazyMsg) serverAddr
      putStrLn $ "Sent command: " ++ show command

      threadDelay (2 * 1000000)
      loop sock serverAddr