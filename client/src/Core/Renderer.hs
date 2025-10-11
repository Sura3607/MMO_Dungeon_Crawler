module Core.Renderer (render) where

import Graphics.Gloss
import Network.Packet (WorldSnapshot(..))
import Types.Player (PlayerState(..))
import Types.Common (Vec2(..))

-- | Hàm render chính, nhận vào state và trả về một Picture của gloss.
render :: (Picture, Picture) -> WorldSnapshot -> Picture
render (tankBody, tankTurret) snapshot =
  Pictures $ map (drawPlayer tankBody tankTurret) (wsPlayers snapshot)

-- | Vẽ một người chơi (xe tăng).
drawPlayer :: Picture -> Picture -> PlayerState -> Picture
drawPlayer tankBody tankTurret ps =
  let
    (x, y) = (vecX $ psPosition ps, vecY $ psPosition ps)
  in
    Translate x y $ Pictures
      [ -- Vẽ thân xe
        Rotate (radToDeg $ psBodyAngle ps) tankBody
        -- Vẽ nòng súng
      , Rotate (radToDeg $ psTurretAngle ps) tankTurret
      ]

radToDeg :: Float -> Float
radToDeg r = r * 180 / pi