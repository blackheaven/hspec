module Main where

import Control.Monad
import Data.List
import Test.Hspec

main :: IO ()
main = do
  hspec $
    parallel $ do
      forM_ ([0 .. 10] :: [Int]) $ \_ ->
        it "Quick test" $ do
          shouldBe (show left) (show right)

data S = S
  { t :: String,
    f0 :: Maybe S,
    f1 :: Maybe S,
    f2 :: Maybe S,
    f3 :: Maybe S
  }
  deriving (Eq, Show)

data T = T
  { u :: String,
    g5 :: Maybe T,
    g6 :: Maybe T,
    g7 :: Maybe T,
    h8 :: Maybe T
  }
  deriving (Eq, Show)

left :: Maybe S
left = mkS "azrtqyui"

right :: Maybe T
right = mkT "azmXauryt"

mkS :: String -> Maybe S
mkS x =
  case permutations x of
    (t' : f0' : f1' : f2' : f3' : _) -> Just $ S t' (mkS (tail f0')) (mkS (tail f1')) (mkS (tail f2')) (mkS (tail f3'))
    _ -> Nothing

mkT :: String -> Maybe T
mkT x =
  case permutations x of
    (t' : f0' : f1' : f2' : f3' : _) -> Just $ T t' (mkT (tail f3')) (mkT (tail f2')) (mkT (tail f0')) (mkT (tail f1'))
    _ -> Nothing
