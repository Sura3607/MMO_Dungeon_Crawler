-- Tệp này sẽ định nghĩa gói tin quan trọng nhất: WorldSnapshot.
-- Đây là "bức ảnh" về trạng thái thế giới game mà server gửi cho client mỗi tick.
{-# LANGUAGE DeriveGeneric #-}

module Network.Packet where

import Data.Binary (Binary)
import GHC.Generics (Generic)
import Types.Player (PlayerState)

-- | Trạng thái của toàn bộ thế giới game tại một thời điểm.
-- Server sẽ gửi gói tin này về cho tất cả client trong mỗi tick.
data WorldSnapshot = WorldSnapshot
  { wsPlayers :: [PlayerState]
  -- Sau này sẽ thêm: wsEnemies, wsBullets, wsItems, v.v.
  } deriving (Show, Generic)

instance Binary WorldSnapshot