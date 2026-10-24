module Parun.Codec.RevealedThisWaySpec where

import qualified Parun.Codec.RevealedThisWay as RevealedThisWay
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.RevealTiming as RevealTiming
import qualified Parun.Types.RevealedThisWay as RevealedThisWay

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RevealedThisWay" $ do
  -- Rowen's "this way": either timing, so no key.
  Spec.it s "no timing writes no key" $
    Common.assertCodec
      s
      RevealedThisWay.codec
      (RevealedThisWay.MkRevealedThisWay (Filter.HasCardType CardType.Land) Nothing)
      " {\"card\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  Spec.it s "MkRevealedThisWay, both keys" $
    Common.assertCodec
      s
      RevealedThisWay.codec
      (RevealedThisWay.MkRevealedThisWay {RevealedThisWay.card = Filter.HasCardType CardType.Land, RevealedThisWay.timing = Just RevealTiming.AsDrawn})
      " {\"card\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"timing\":{\"type\":\"AsDrawn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RevealedThisWay.codec
