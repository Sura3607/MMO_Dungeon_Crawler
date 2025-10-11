-- client/src/Main.hs
module Main where

import Network.Socket
import Data.Binary (encode, decodeOrFail)
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Graphics.Gloss.Interface.IO.Game
import Graphics.Gloss.Juicy
import qualified Data.Set as Set

import qualified Network.Socket.ByteString as BS (recvFrom, sendTo)
import qualified Data.ByteString.Lazy as LBS
import Data.ByteString.Lazy.Internal (fromStrict, toStrict)

import Types.Player
import Types.Common
import Network.Packet
import Input (KeyMap, calculateMoveVector)
import Core.Renderer (render)

-- | Trạng thái của client
data ClientState = ClientState
  { csKeys        :: KeyMap
  , csMousePos    :: (Float, Float)
  , csWorld       :: WorldSnapshot
  }

initialClientState :: ClientState
initialClientState = ClientState
  { csKeys = Set.empty
  , csMousePos = (0, 0)
  , csWorld = WorldSnapshot { wsPlayers = [] }
  }

main :: IO ()
main = withSocketsDo $ do
  putStrLn "Starting client..."
  -- Load assets trước
  eResources <- loadResources
  case eResources of
    Left err -> putStrLn $ "Failed to load resources: " ++ err
    Right (tankBody, tankTurret) -> do
      -- Nếu load thành công, thiết lập network và chạy game
      putStrLn "Assets loaded successfully. Starting game..."
      sock <- socket AF_INET Datagram defaultProtocol
      addr <- head <$> getAddrInfo (Just defaultHints { addrSocketType = Datagram }) (Just "127.0.0.1") (Just "8888")
      runGame (addrAddress addr) sock (tankBody, tankTurret)

-- | Tách riêng hàm load resources để làm rõ kiểu dữ liệu
loadResources :: IO (Either String (Picture, Picture))
loadResources = do
  mTankBody <- loadJuicyPNG "client/assets/textures/tanks/rapid_tank/body.png"
  case mTankBody of
    Nothing -> return $ Left "Failed to load tank body: client/assets/textures/tanks/rapid_tank/body.png"
    Just tankBody -> do
      mTankTurret <- loadJuicyPNG "client/assets/textures/tanks/rapid_tank/turret.png"
      case mTankTurret of
        Nothing -> return $ Left "Failed to load tank turret: client/assets/textures/tanks/rapid_tank/turret.png"
        Just tankTurret -> return $ Right (tankBody, tankTurret)

-- | Hàm chạy game chính sau khi đã có đủ mọi thứ
runGame :: SockAddr -> Socket -> (Picture, Picture) -> IO ()
runGame serverAddr sock (tankBody, tankTurret) = do
  clientStateRef <- newMVar initialClientState
  _ <- forkIO $ networkListenLoop sock clientStateRef
  playIO
    (InWindow "MMO Dungeon Crawler" (800, 600) (10, 10))
    white
    60
    initialClientState
    (\_ -> render (tankBody, tankTurret) . csWorld <$> readMVar clientStateRef)
    (handleInput serverAddr sock)
    updateClient

-- | Vòng lặp nhận dữ liệu từ server
networkListenLoop :: Socket -> MVar ClientState -> IO ()
networkListenLoop sock stateRef = do
  (strictMsg, _) <- BS.recvFrom sock 8192
  let lazyMsg = fromStrict strictMsg
  case decodeOrFail lazyMsg of
    Left _ -> networkListenLoop sock stateRef
    Right (_, _, newSnapshot) -> do
      modifyMVar_ stateRef (\cs -> pure cs { csWorld = newSnapshot })
      networkListenLoop sock stateRef

-- | Xử lý input từ Gloss
handleInput :: SockAddr -> Socket -> Event -> ClientState -> IO ClientState
handleInput serverAddr sock (EventKey key Down _ _) cs = do
  let newKeys = Set.insert key (csKeys cs)
  sendCmdToServer serverAddr sock newKeys (csMousePos cs)
  return cs { csKeys = newKeys }
handleInput serverAddr sock (EventKey key Up _ _) cs = do
  let newKeys = Set.delete key (csKeys cs)
  sendCmdToServer serverAddr sock newKeys (csMousePos cs)
  return cs { csKeys = newKeys }
handleInput serverAddr sock (EventMotion pos) cs = do
  sendCmdToServer serverAddr sock (csKeys cs) pos
  return cs { csMousePos = pos }
handleInput _ _ _ cs = return cs

-- | Gửi lệnh tới server
sendCmdToServer :: SockAddr -> Socket -> KeyMap -> (Float, Float) -> IO ()
sendCmdToServer serverAddr sock keys (mouseX, mouseY) = do
  let moveVec = calculateMoveVector keys
  let turretAngle = atan2 mouseY mouseX
  let command = MoveAndAim moveVec turretAngle
  let lazyMsg = encode command
  let strictMsg = toStrict lazyMsg
  _ <- BS.sendTo sock strictMsg serverAddr
  return ()

-- | Update state của client mỗi frame
updateClient :: Float -> ClientState -> IO ClientState
updateClient _dt cs = return cs