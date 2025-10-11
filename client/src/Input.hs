module Input where

import Graphics.Gloss.Interface.IO.Game
import Types.Common (Vec2(..))
import qualified Data.Set as Set

type KeyMap = Set.Set Key

-- | Tính toán vector di chuyển từ các phím đang được nhấn.
-- WASD mapping.
calculateMoveVector :: KeyMap -> Vec2
calculateMoveVector km =
  Vec2 (getX km) (getY km)
  where
    getX s | Set.member (Char 'd') s = 1.0
           | Set.member (Char 'a') s = -1.0
           | otherwise = 0.0
    getY s | Set.member (Char 'w') s = 1.0
           | Set.member (Char 's') s = -1.0
           | otherwise = 0.0