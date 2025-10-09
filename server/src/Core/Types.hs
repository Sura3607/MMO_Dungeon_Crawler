module Core.Types where

import Network.Socket (SockAddr)
-- Import các kiểu đã được chuẩn hóa từ thư viện shared
import Types.Common (EntityID, Vec2)
import Types.Player (PlayerCommand)

type Tick = Int

-- | Trạng thái của toàn bộ game phía server.
data GameState = GameState
  { gsTick      :: Tick
  , gsCommands  :: [(SockAddr, PlayerCommand)] -- Các lệnh nhận được trong tick
  -- Sau này sẽ thêm State của người chơi, quái, v.v.
  -- , gsPlayers :: Map EntityID PlayerState
  }

-- | Hàm tạo một GameState ban đầu.
initialGameState :: GameState
initialGameState = GameState
  { gsTick = 0
  , gsCommands = []
  }