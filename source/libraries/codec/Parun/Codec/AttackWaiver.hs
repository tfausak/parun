module Parun.Codec.AttackWaiver where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackWaiver as AttackWaiver

-- | Nullary tags, Parun.Codec.AbilityKind's shape.
codec :: Codec.Codec AttackWaiver.AttackWaiver
codec = Arm.enum
