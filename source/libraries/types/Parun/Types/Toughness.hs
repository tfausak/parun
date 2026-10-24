module Parun.Types.Toughness where

import qualified Parun.Types.Quantity as Quantity

newtype Toughness = MkToughness
  { unwrap :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
