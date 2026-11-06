module Parun.Codec.NextDamageOutcomeSpec where

import qualified Parun.Codec.NextDamageOutcome as NextDamageOutcome
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.NextDamageOutcome as NextDamageOutcome

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.NextDamageOutcome" $ do
  Spec.it s "Prevented" $
    Common.assertCodec
      s
      NextDamageOutcome.codec
      NextDamageOutcome.Prevented
      " {\"type\":\"Prevented\"} "
  Spec.it s "PreventedAllBut" $
    Common.assertCodec
      s
      NextDamageOutcome.codec
      (NextDamageOutcome.PreventedAllBut 1)
      " {\"type\":\"PreventedAllBut\",\"value\":1} "
  Spec.it s "AlsoToSourceController" $
    Common.assertCodec
      s
      NextDamageOutcome.codec
      NextDamageOutcome.AlsoToSourceController
      " {\"type\":\"AlsoToSourceController\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s NextDamageOutcome.codec
