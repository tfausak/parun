module Parun.Codec.RollModifierSpec where

import qualified Parun.Codec.RollModifier as RollModifier
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.RollModifier as RollModifier

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RollModifier" $ do
  -- CR 706.2b's first step: Clam-I-Am.
  Spec.it s "Reroll" $
    Common.assertCodec
      s
      RollModifier.codec
      RollModifier.Reroll
      " {\"type\":\"Reroll\"} "
  -- CR 706.2b's second step: Night Shift of the Living Dead.
  Spec.it s "IncreaseOrDecrease" $
    Common.assertCodec
      s
      RollModifier.codec
      (RollModifier.IncreaseOrDecrease 1)
      " {\"type\":\"IncreaseOrDecrease\",\"value\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RollModifier.codec
