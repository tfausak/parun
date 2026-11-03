module Parun.Codec.NextDamageOutcome where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.NextDamageOutcome as NextDamageOutcome

-- | Nullary tags, Parun.Codec.AbilityKind's shape and for its reason.
codec :: Codec.Codec NextDamageOutcome.NextDamageOutcome
codec = Arm.enum
