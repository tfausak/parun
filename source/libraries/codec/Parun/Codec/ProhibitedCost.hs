module Parun.Codec.ProhibitedCost where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ProhibitedCost as ProhibitedCost

-- | Nullary tags, Parun.Codec.AbilityKind's shape.
codec :: Codec.Codec ProhibitedCost.ProhibitedCost
codec = Arm.enum
