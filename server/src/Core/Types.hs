module Core.Types where

type Tick = Int

type EntityID = Int

data Vec2 = Vec2 { vx :: Double, vy :: Double } deriving (Show, Eq)
