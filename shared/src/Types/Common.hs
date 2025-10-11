{-# LANGUAGE DeriveGeneric #-}

module Types.Common where

import Data.Binary (Binary)
import GHC.Generics (Generic)

data Vec2 = Vec2
  { vecX :: Float
  , vecY :: Float
  } deriving (Show, Eq, Generic)

instance Binary Vec2

-- | Cung cấp các phép toán cơ bản cho Vec2.
-- Quan trọng: Phép nhân (*) ở đây là nhân theo từng thành phần (component-wise),
-- không phải phép nhân vô hướng mà chúng ta cần cho di chuyển.
instance Num Vec2 where
  (Vec2 x1 y1) + (Vec2 x2 y2) = Vec2 (x1 + x2) (y1 + y2)
  (Vec2 x1 y1) - (Vec2 x2 y2) = Vec2 (x1 - x2) (y1 - y2)
  (Vec2 x1 y1) * (Vec2 x2 y2) = Vec2 (x1 * x2) (y1 * y2)
  abs (Vec2 x y) = Vec2 (abs x) (abs y)
  signum (Vec2 x y) = Vec2 (signum x) (signum y)
  fromInteger i = Vec2 (fromInteger i) (fromInteger i)

-- | Toán tử nhân vô hướng: Vector * Scalar.
-- Đây là hàm chúng ta sẽ dùng để tính toán di chuyển.
(*^) :: Vec2 -> Float -> Vec2
(Vec2 x y) *^ s = Vec2 (x * s) (y * s)