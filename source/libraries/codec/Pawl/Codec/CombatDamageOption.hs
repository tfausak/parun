module Pawl.Codec.CombatDamageOption where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.CombatDamageOption as CombatDamageOption

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec CombatDamageOption.CombatDamageOption
codec = Arm.enum
