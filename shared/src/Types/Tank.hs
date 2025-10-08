{-# LANGUAGE DeriveGeneric #-} -- << THÊM DÒNG NÀY VÀO ĐẦU TIÊN

module Types.Tank where

import GHC.Generics (Generic)
import Data.Binary (Binary)

data Tank = Tank { tid :: Int, tname :: String } deriving (Show, Generic) -- Dòng này cần `DeriveGeneric`

instance Binary Tank