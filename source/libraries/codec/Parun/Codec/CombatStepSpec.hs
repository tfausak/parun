module Parun.Codec.CombatStepSpec where

import qualified Parun.Codec.CombatStep as CombatStep
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CombatStep as CombatStep

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CombatStep" $ do
  Spec.it s "BeginningOfCombat" $
    Common.assertCodec
      s
      CombatStep.codec
      CombatStep.BeginningOfCombat
      " \"BeginningOfCombat\" "
  Spec.it s "DeclareAttackers" $
    Common.assertCodec
      s
      CombatStep.codec
      CombatStep.DeclareAttackers
      " \"DeclareAttackers\" "
  Spec.it s "DeclareBlockers" $
    Common.assertCodec
      s
      CombatStep.codec
      CombatStep.DeclareBlockers
      " \"DeclareBlockers\" "
  Spec.it s "CombatDamage" $
    Common.assertCodec
      s
      CombatStep.codec
      CombatStep.CombatDamage
      " \"CombatDamage\" "
  Spec.it s "EndOfCombat" $
    Common.assertCodec
      s
      CombatStep.codec
      CombatStep.EndOfCombat
      " \"EndOfCombat\" "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CombatStep.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s CombatStep.codec
