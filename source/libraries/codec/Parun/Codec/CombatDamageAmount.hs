module Parun.Codec.CombatDamageAmount where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CombatDamageAmount as CombatDamageAmount

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec CombatDamageAmount.CombatDamageAmount
codec = Arm.enum
