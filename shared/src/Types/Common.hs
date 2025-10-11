-- Tệp này sẽ chứa các kiểu dữ liệu cơ bản nhất được sử dụng ở mọi nơi. Việc đặt chúng ở đây giúp tránh định nghĩa lặp lại.
{-# LANGUAGE DeriveGeneric #-}
module Types.Common where

import Data.Binary (Binary)
import GHC.Generics (Generic)

-- | Một vector 2D đơn giản cho vị trí và vận tốc.
-- Able to be serialized to binary format.
data Vec2 = Vec2
  { vecX :: Double
  , vecY :: Double
  } deriving (Show, Eq, Generic)

instance Binary Vec2

-- | Kiểu dữ liệu cho góc, tính bằng radians.
type Angle = Double

-- | Định danh duy nhất cho mỗi thực thể trong game.
type EntityID = Int