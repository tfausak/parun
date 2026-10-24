module Parun.Types.DamageIs where

import Numeric.Natural (Natural)
import qualified Parun.Types.Reference as Reference

-- | CR 120.6: the damage marked on a permanent.
data DamageIs = MkDamageIs
  { object :: Reference.Reference,
    damage :: Natural
  }
  deriving (Eq, Ord, Show)
