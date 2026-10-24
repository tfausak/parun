module Parun.Codec.OnsetSpec where

import qualified Parun.Codec.Onset as Onset
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Onset as Onset
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Onset" $ do
  Spec.it s "Immediately" $
    Common.assertCodec
      s
      Onset.codec
      Onset.Immediately
      " {\"type\":\"Immediately\"} "
  Spec.it s "FromNextTurnOf" $
    Common.assertCodec
      s
      Onset.codec
      (Onset.FromNextTurnOf (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"FromNextTurnOf\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  Spec.it s "FromThatExtraTurn" $
    Common.assertCodec
      s
      Onset.codec
      Onset.FromThatExtraTurn
      " {\"type\":\"FromThatExtraTurn\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Onset.codec
