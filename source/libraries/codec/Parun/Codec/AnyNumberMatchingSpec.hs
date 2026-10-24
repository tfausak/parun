module Parun.Codec.AnyNumberMatchingSpec where

import qualified Parun.Codec.AnyNumberMatching as AnyNumberMatching
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AnyNumberMatching" $ do
  Spec.it s "no ceiling writes no key" $
    Common.assertCodec
      s
      AnyNumberMatching.codec
      (AnyNumberMatching.MkAnyNumberMatching (Filter.HasCardType CardType.Creature) Nothing)
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "a ceiling" $
    Common.assertCodec
      s
      AnyNumberMatching.codec
      (AnyNumberMatching.MkAnyNumberMatching (Filter.HasCardType CardType.Land) (Just (Quantity.Literal 2)))
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"atMost\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AnyNumberMatching.codec
