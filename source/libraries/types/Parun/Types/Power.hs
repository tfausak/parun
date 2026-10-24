module Parun.Types.Power where

import qualified Parun.Types.Quantity as Quantity

newtype Power = MkPower
  { unwrap :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
