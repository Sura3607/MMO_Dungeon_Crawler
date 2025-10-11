module Systems.PhysicsSystem (updatePhysics) where

import Core.Types (GameState(..), Command(..))
import Types.Player (PlayerState(..), PlayerCommand(..))
import Types.Common (Vec2(..), (*^))
import Network.Socket (SockAddr)

playerSpeed :: Float
playerSpeed = 200.0 -- pixels per second

updatePhysics :: Float -> GameState -> GameState
updatePhysics dt gs =
  let
    -- Áp dụng tất cả các lệnh trong tick hiện tại
    updatedPlayers = foldr (applyCommand dt) (gsPlayers gs) (gsCommands gs)
  in
    gs { gsPlayers = updatedPlayers }

-- | Áp dụng một lệnh lên danh sách người chơi
applyCommand :: Float -> Command -> [PlayerState] -> [PlayerState]
applyCommand dt (Command addr pcmd) players =
  -- Hiện tại, chúng ta chỉ có một người chơi, nên cứ cập nhật người chơi đó
  -- Sau này, khi có nhiều người chơi, chúng ta sẽ cần tìm đúng người chơi dựa trên `addr`
  case players of
    [] -> []
    (p:ps) -> updatePlayerState dt p pcmd : ps

-- | Cập nhật trạng thái của một người chơi dựa trên lệnh
updatePlayerState :: Float -> PlayerState -> PlayerCommand -> PlayerState
updatePlayerState dt ps (Move moveVec) =
  let newPos = psPosition ps + (moveVec *^ (playerSpeed * dt))
  in ps { psPosition = newPos }
updatePlayerState _ ps (Aim angle) =
  ps { psTurretAngle = angle }
updatePlayerState dt ps (MoveAndAim moveVec angle) =
  let newPos = psPosition ps + (moveVec *^ (playerSpeed * dt))
  in ps { psPosition = newPos, psTurretAngle = angle }
