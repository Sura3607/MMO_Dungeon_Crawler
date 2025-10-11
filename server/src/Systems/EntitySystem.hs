module Systems.EntitySystem (updatePlayerState) where

import Core.Types (GameState(..))
import Types.Player (PlayerState(..))

-- | Hàm này sẽ tìm và cập nhật trạng thái cho một người chơi cụ thể.
-- Hiện tại, để đơn giản, chúng ta giả định chỉ có một người chơi và cập nhật thẳng.
-- Sau này sẽ cần playerId để phân biệt.
updatePlayerState :: PlayerState -> GameState -> GameState
updatePlayerState newPlayerState gs =
  gs { gsPlayers = [newPlayerState] } -- Ghi đè state của người chơi đầu tiên