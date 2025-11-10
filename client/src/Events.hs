{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Redundant bracket" #-}
module Events (handleInputIO) where

import Graphics.Gloss.Interface.IO.Game
import Control.Concurrent (MVar, modifyMVar_)
import qualified Data.Set as Set
import Data.Char (isPrint)

import Types
import Network.Client (sendTcpPacket)
import Types.Tank (TankType(..))
import Network.Packet (ClientTcpPacket(..))
import Core.Animation (startAnimation)
import Types.GameMode (GameMode(..))

-- INPUT CHÍNH (Router)
handleInputIO :: Event -> MVar ClientState -> IO (MVar ClientState)
handleInputIO event mvar = do
  modifyMVar_ mvar $ \cState -> do
    case (csState cState) of
      S_Login data_ -> handleInputLogin event cState
      S_Menu        -> handleInputMenu event cState
      S_RoomSelection data_ -> handleInputRoomSelection event cState
      S_Lobby data_   -> handleInputLobby event cState
      S_DungeonLobby _ -> handleInputDungeonLobby event cState
      S_InGame gdata  -> 
        case event of
          (EventKey (SpecialKey KeyEsc) Down _ _) ->
            if (igsMode gdata == PvE)
            then do
              putStrLn "[Input] Pausing PvE game"
              sendTcpPacket (csTcpHandle cState) (CTP_PauseGame True)
              pure cState { csState = S_Paused gdata False }
            else 
              pure cState
          
          _ -> if (igsMatchState gdata == InProgress)
                 then pure $ cState { csState = S_InGame (handleInputGame event gdata) }
                 else case (igsMatchState gdata) of
                        (GameOver _) -> handleInputPostGame event cState
                        _ -> pure cState 
      
      S_PostGame data_ -> handleInputPostGame event cState
      S_Paused gdata isConfirming -> handleInputPaused event cState
  return mvar

-- === LOGIN ===
handleInputLogin :: Event -> ClientState -> IO ClientState
handleInputLogin event cState@(ClientState { csTcpHandle = h, csState = (S_Login ld) }) =
  case event of
    -- 1. Bắt phím Backspace (Special Key)
    (EventKey (SpecialKey KeyBackspace) Down _ _) ->
      pure $ cState { csState = S_Login (doBackspace) }

    -- 2. Bắt ký tự Backspace (Char '\b')
    (EventKey (Char '\b') Down _ _) ->
      pure $ cState { csState = S_Login (doBackspace) }

    -- Bắt các ký tự in được (a, b, c, 1, 2, 3, etc.)
    (EventKey (Char c) Down _ _) | isPrint c ->
      pure $ cState { csState = S_Login (addChar c) }
    
    -- Xử lý phím Tab
    (EventKey (SpecialKey KeyTab) Down _ _) ->
      pure $ cState { csState = S_Login (toggleField) }

    -- Xử lý Click chuột
    (EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -20 && x < 180 && y > 25 && y < 75) ->
          pure cState { csState = S_Login (ld { ldActiveField = UserField }) }
      | (x > -20 && x < 180 && y > -55 && y < -5) ->
          pure cState { csState = S_Login (ld { ldActiveField = PassField }) }
      | (x > -200 && x < 0 && y > -175 && y < -125) -> do
          sendTcpPacket h (CTP_Login (ldUsername ld) (ldPassword ld))
          pure cState { csState = S_Login ld { ldStatus = "Logging in..." } }
      | (x > 0 && x < 200 && y > -175 && y < -125) -> do
          sendTcpPacket h (CTP_Register (ldUsername ld) (ldPassword ld))
          pure cState { csState = S_Login ld { ldStatus = "Registering..." } }
      | otherwise -> pure cState
      
    _ -> pure cState -- Bỏ qua các phím khác (như Shift, Ctrl, ...)
  
  where
    -- Hàm helper để tránh lặp code
    doBackspace = case ldActiveField ld of
      UserField -> ld { ldUsername = if null (ldUsername ld) then "" else init (ldUsername ld) }
      PassField -> ld { ldPassword = if null (ldPassword ld) then "" else init (ldPassword ld) }
      
    addChar c = case ldActiveField ld of
      UserField -> ld { ldUsername = ldUsername ld ++ [c] }
      PassField -> ld { ldPassword = ldPassword ld ++ [c] }
      
    toggleField = case ldActiveField ld of
      UserField -> ld { ldActiveField = PassField }
      PassField -> ld { ldActiveField = UserField }

handleInputLogin _ cState = pure cState

-- === MAIN MENU ===
handleInputMenu :: Event -> ClientState -> IO ClientState
handleInputMenu event cState@(ClientState { csTcpHandle = h }) =
  case event of
    EventKey (MouseButton LeftButton) Down _ (x, y)
      | x > -100 && x < 100 && y > -25 && y < 25 -> do
          putStrLn "[Input] Clicked Start PvP"
          pure cState { csState = S_RoomSelection "" }
      | x > -100 && x < 100 && y > -85 && y < -35 -> do
          putStrLn "[Input] Clicked Start PvE (Disabled)"
          pure cState
      | x > -100 && x < 100 && y > -145 && y < -95 -> do
          putStrLn "[Input] Clicked Start 2PvE (Disabled)"
          pure cState
      | otherwise -> pure cState
    _ -> pure cState

handleInputDungeonLobby :: Event -> ClientState -> IO ClientState
handleInputDungeonLobby event cState@(ClientState { csTcpHandle = h, csState = (S_DungeonLobby mTank) }) =
  case event of
    (EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -200 && x < 0 && y > -25 && y < 25) -> 
          pure cState { csState = S_DungeonLobby (Just Rapid) }
      | (x > 0 && x < 200 && y > -25 && y < 25) -> 
          pure cState { csState = S_DungeonLobby (Just Blast) }
      | (x > -100 && x < 100 && y > -225 && y < -175) -> do 
          putStrLn "[Input] Start Dungeon pressed, but PvE is disabled."
          pure cState
      | (x > -100 && x < 100 && y > -285 && y < -235) -> do
          putStrLn "[Input] Back to Menu"
          pure cState { csState = S_Menu }
      | otherwise -> pure cState
    _ -> pure cState
handleInputDungeonLobby _ cState = pure cState

-- === ROOM SELECTION ===
handleInputRoomSelection :: Event -> ClientState -> IO ClientState
handleInputRoomSelection event cState@(ClientState { csTcpHandle = h, csState = (S_RoomSelection roomId) }) =
  case event of
    (EventKey (SpecialKey KeyBackspace) Down _ _) -> 
      pure cState { csState = S_RoomSelection (if null roomId then "" else init roomId) }
    (EventKey (Char '\b') Down _ _) ->
      pure cState { csState = S_RoomSelection (if null roomId then "" else init roomId) }

    (EventKey (Char c) Down _ _) | isPrint c -> 
      pure cState { csState = S_RoomSelection (roomId ++ [c]) }
      
    (EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -100 && x < 100 && y > -25 && y < 25) -> do 
          sendTcpPacket h CTP_CreateRoom
          pure cState
      | (x > -100 && x < 100 && y > -85 && y < -35) -> do 
          sendTcpPacket h (CTP_JoinRoom roomId)
          pure cState
      | (x > -100 && x < 100 && y > -235 && y < -185) -> do
          putStrLn "[Input] Back to Menu"
          pure cState { csState = S_Menu }
    _ -> pure cState
handleInputRoomSelection _ cState = pure cState

-- === LOBBY ===
handleInputLobby :: Event -> ClientState -> IO ClientState
handleInputLobby event cState@(ClientState { csTcpHandle = h, csState = (S_Lobby ld) }) =
  case event of
    (EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -200 && x < 0 && y > -75 && y < -25) -> do -- "Select Rapid"
          let newTank = Just Rapid
          sendTcpPacket h (CTP_UpdateLobbyState newTank (ldMyReady ld))
          pure cState { csState = S_Lobby ld { ldMyTank = newTank } }
      | (x > 0 && x < 200 && y > -75 && y < -25) -> do -- "Select Blast"
          let newTank = Just Blast
          sendTcpPacket h (CTP_UpdateLobbyState newTank (ldMyReady ld))
          pure cState { csState = S_Lobby ld { ldMyTank = newTank } }
      | (x > -100 && x < 100 && y > -225 && y < -175) -> do -- "Ready"
          let newReady = not (ldMyReady ld)
          sendTcpPacket h (CTP_UpdateLobbyState (ldMyTank ld) newReady)
          pure cState { csState = S_Lobby ld { ldMyReady = newReady } }
      | (x > -100 && x < 100 && y > -285 && y < -235) -> do
          putStrLn "[Input] Back (Leaving Room)..."
          sendTcpPacket h CTP_LeaveRoom
          pure cState
    _ -> pure cState
handleInputLobby _ cState = pure cState

-- === POST GAME ===
handleInputPostGame :: Event -> ClientState -> IO ClientState
handleInputPostGame event cState@(ClientState { csTcpHandle = h, csState = (S_PostGame pgData) }) =
  case event of
    (EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -100 && x < 100 && y > -25 && y < 25) -> do 
          if Set.notMember (csMyId cState) (pgRematchRequesters pgData)
            then do
              putStrLn "[Input] Requesting Rematch..."
              sendTcpPacket h CTP_RequestRematch
              let newSet = Set.insert (csMyId cState) (pgRematchRequesters pgData)
              pure cState { csState = S_PostGame (pgData { pgRematchRequesters = newSet }) }
            else 
              pure cState
      | (x > -100 && x < 100 && y > -85 && y < -35) -> do -- "Exit to Menu"
          putStrLn "[Input] Exiting to Menu."
          sendTcpPacket h CTP_LeaveRoom
          pure cState { csState = S_Menu } 
    _ -> pure cState
handleInputPostGame _ cState = pure cState

-- === IN GAME ===
handleInputGame :: Event -> InGameState -> InGameState
handleInputGame event gdata =
  case event of
    EventKey (MouseButton LeftButton) Down _ _ ->
      gdata { igsDidFire = True
            , igsTurretAnimRapid = startAnimation (igsTurretAnimRapid gdata)
            , igsTurretAnimBlast = startAnimation (igsTurretAnimBlast gdata)
            }
    EventKey key Down _ _ ->
      let newKeys = Set.insert key (igsKeys gdata)
      in gdata { igsKeys = newKeys }
    EventKey key Up _ _ ->
      let newKeys = Set.delete key (igsKeys gdata)
      in gdata { igsKeys = newKeys }
    EventMotion pos ->
      gdata { igsMousePos = pos }
    _ -> gdata

-- === PAUSE MENU ===
handleInputPaused :: Event -> ClientState -> IO ClientState
handleInputPaused event cState@(ClientState { csTcpHandle = h, csState = (S_Paused gdata isConfirming) }) =
  case (isConfirming, event) of
    
    (True, EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -200 && x < 0 && y > -125 && y < -75) -> do
          putStrLn "[Input] Confirmed Exit to Menu."
          sendTcpPacket h (CTP_PauseGame False)
          sendTcpPacket h CTP_LeaveRoom
          pure cState { csState = S_Menu }
      | (x > 0 && x < 200 && y > -125 && y < -75) -> do
          putStrLn "[Input] Cancelled Exit."
          pure cState { csState = S_Paused gdata False }
      | otherwise -> pure cState

    (False, EventKey (SpecialKey KeyEsc) Down _ _) -> do
      putStrLn "[Input] Resuming game (Esc)"
      sendTcpPacket h (CTP_PauseGame False)
      pure cState { csState = S_InGame gdata }

    (False, EventKey (MouseButton LeftButton) Down _ (x, y))
      | (x > -100 && x < 100 && y > 75 && y < 125) -> do
          putStrLn "[Input] Resuming game (Button)"
          sendTcpPacket h (CTP_PauseGame False)
          pure cState { csState = S_InGame gdata }
      | (x > -100 && x < 100 && y > 15 && y < 65) -> do
          putStrLn "[Input] Settings (Disabled)"
          pure cState
      | (x > -100 && x < 100 && y > -45 && y < 5) -> do
          putStrLn "[Input] Requesting Exit to Menu..."
          pure cState { csState = S_Paused gdata True }
      | otherwise -> pure cState
    _ -> pure cState
handleInputPaused _ cState = pure cState