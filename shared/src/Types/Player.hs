{-# LANGUAGE DeriveGeneric #-}

module Types.Player where

import Data.Binary (Binary)
import GHC.Generics (Generic)
import Types.Common (Vec2)

-- | Dữ liệu trạng thái của một người chơi, được server gửi về client.
data PlayerState = PlayerState
  { psPosition    :: Vec2    -- Vị trí hiện tại
  , psBodyAngle   :: Float   -- Góc xoay của thân xe (radians)
  , psTurretAngle :: Float   -- Góc xoay của nòng súng (radians)
  } deriving (Show, Generic)

instance Binary PlayerState

-- | Lệnh do người chơi gửi lên server.
data PlayerCommand
  = Move Vec2         -- Vector di chuyển (ví dụ: W=(0,1), A=(-1,0))
  | Aim Float         -- Góc nòng súng (radians)
  | MoveAndAim Vec2 Float -- Gửi cả hai trong một gói tin
  deriving (Show, Generic)

instance Binary PlayerCommand