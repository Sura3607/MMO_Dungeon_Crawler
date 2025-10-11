module Main (main) where

import Test.Hspec
import Input
import Types.Common (Vec2(..))
import Graphics.Gloss.Interface.IO.Game (Key(..))
import qualified Data.Set as Set

main :: IO ()
main = hspec $ do
  describe "calculateMoveVector" $ do
    it "returns (0,0) when no keys pressed" $ do
      calculateMoveVector Set.empty `shouldBe` Vec2 0 0

    it "W key gives up vector" $ do
      let km = Set.fromList [Char 'w']
      calculateMoveVector km `shouldBe` Vec2 0 1

    it "A and W combined" $ do
      let km = Set.fromList [Char 'a', Char 'w']
      calculateMoveVector km `shouldBe` Vec2 (-1) 1

  describe "turret angle math" $ do
    it "atan2 0,1 is 0 radians" $ do
      let ang = atan2 0 1 :: Float
      ang `shouldBe` 0

    it "atan2 1 0 is pi/2" $ do
      let ang = atan2 1 0 :: Float
      ang `shouldBe` (pi / 2)
