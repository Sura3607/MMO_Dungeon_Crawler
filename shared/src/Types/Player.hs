module Types.Player where

data Player = Player
  { playerId :: Int
  , playerName :: String
  } deriving (Show, Eq)
