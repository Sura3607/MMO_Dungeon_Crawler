module Core.Types where

import Network.Socket (SockAddr)
import Types.Player (PlayerCommand, PlayerState(..))
import Types.Common (Vec2(..))

data GameState = GameState
  { gsTick     :: Int
  , gsCommands :: [Command]
  , gsPlayers  :: [PlayerState] 
  }

data Command = Command SockAddr PlayerCommand

initialGameState :: GameState
initialGameState = GameState
  { gsTick = 0
  , gsCommands = []
  , gsPlayers = [initialPlayerState] -- Khởi tạo một người chơi
  }

initialPlayerState :: PlayerState
initialPlayerState = PlayerState
  { psPosition = Vec2 0 0
  , psBodyAngle = 0.0
  , psTurretAngle = 0.0
  }