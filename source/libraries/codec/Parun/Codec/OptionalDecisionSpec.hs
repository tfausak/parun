module Parun.Codec.OptionalDecisionSpec where

import qualified Parun.Codec.OptionalDecision as OptionalDecision
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.OptionalDecision as OptionalDecision.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OptionalDecision" $ do
  Spec.it s "Exercises" $
    Common.assertCodec s OptionalDecision.codec OptionalDecision.Type.Exercises " {\"type\":\"Exercises\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s OptionalDecision.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s OptionalDecision.codec
