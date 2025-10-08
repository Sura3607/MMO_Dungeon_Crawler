{-# LANGUAGE DeriveGeneric #-} -- << THÊM DÒNG NÀY VÀO ĐẦU TIÊN

module Types.Player where

import GHC.Generics (Generic)
import Data.Binary (Binary)

data Player = Player
  { playerId :: Int
  , playerName :: String
  } deriving (Show, Eq, Generic) -- Bây giờ trình biên dịch sẽ hiểu `Generic`

instance Binary Player

data PlayerCommand
  = Move { velX :: Float, velY :: Float }
  | Shoot
  deriving (Show, Eq, Generic) -- Và ở đây nữa

instance Binary PlayerCommand