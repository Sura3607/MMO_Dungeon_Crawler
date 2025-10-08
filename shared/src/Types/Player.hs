{-# LANGUAGE DeriveGeneric #-} -- Bật tính năng DeriveGeneric

module Types.Player where

import GHC.Generics (Generic)
import Data.Binary (Binary)

-- Định nghĩa kiểu dữ liệu cho người chơi
data Player = Player
  { playerId :: Int
  , playerName :: String
  } deriving (Show, Eq, Generic)

-- Khai báo để thư viện Binary biết cách mã hóa/giải mã Player
instance Binary Player

-- Định nghĩa các lệnh mà người chơi có thể gửi đi
data PlayerCommand
  = Move { velX :: Float, velY :: Float }
  | Shoot
  deriving (Show, Eq, Generic)

-- Khai báo để thư viện Binary biết cách mã hóa/giải mã PlayerCommand
instance Binary PlayerCommand