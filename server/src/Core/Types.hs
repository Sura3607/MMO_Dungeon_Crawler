-- server/src/Core/Types.hs
module Core.Types where

import Types.Player (PlayerCommand) -- Import từ gói shared
import Network.Socket (SockAddr)

type Tick = Int
type EntityID = Int

data Vec2 = Vec2 { vx :: Double, vy :: Double } deriving (Show, Eq)

-- Trạng thái của toàn bộ game
data GameState = GameState
  { gsTick :: Tick
  , gsCommands :: [(SockAddr, PlayerCommand)] -- Danh sách các lệnh nhận được trong tick này
  }

-- Hàm tạo một GameState ban đầu
initialGameState :: GameState
initialGameState = GameState
  { gsTick = 0
  , gsCommands = []
  }