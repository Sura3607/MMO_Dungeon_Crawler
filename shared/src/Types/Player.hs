-- Tệp này ...
{-# LANGUAGE DeriveGeneric #-}

module Types.Player where

import Data.Binary (Binary)
import GHC.Generics (Generic)
import Types.Common (Angle, EntityID, Vec2)

-- | Dữ liệu định danh cho một người chơi (phù hợp cho lobby, database).
data Player = Player
  { playerId   :: Int
  , playerName :: String
  } deriving (Show, Eq, Generic)

instance Binary Player

-- | Lệnh mà Client gửi lên Server trong mỗi tick.
data PlayerCommand
  -- | Hướng di chuyển mong muốn (ví dụ: Vec2 0 1 là đi thẳng lên).
  = Move Vec2
  -- | Góc của nòng súng so với trục hoành.
  | Aim Angle
  -- | Lệnh bắn.
  | Shoot
  -- | Gói tin tối ưu, gửi cả hướng di chuyển và góc bắn cùng lúc.
  | FullCommand Vec2 Angle
  deriving (Show, Generic)

instance Binary PlayerCommand

-- | Trạng thái vật lý của người chơi trong thế giới game.
-- Server quản lý và gửi về Client trong WorldSnapshot.
data PlayerState = PlayerState
  { -- | ID của thực thể xe tăng này.
    psId          :: EntityID
    -- | Vị trí hiện tại trên bản đồ.
  , psPos         :: Vec2
    -- | Góc xoay của thân xe (thường đi theo hướng di chuyển).
  , psBodyAngle   :: Angle
    -- | Góc xoay của nòng súng (đi theo con trỏ chuột).
  , psTurretAngle :: Angle
  } deriving (Show, Eq, Generic)

instance Binary PlayerState