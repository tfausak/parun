module Parun.Codec.CombatDeclaration where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CombatDeclaration as CombatDeclaration

codec :: Codec.Codec CombatDeclaration.CombatDeclaration
codec = Arm.enum
