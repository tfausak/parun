module Parun.Codec.CounterProhibitionSpec where

import qualified Parun.Codec.CounterProhibition as CounterProhibition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CounterProhibition as CounterProhibition
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterProhibition" $ do
  -- Prowling Serpopard's "creature spells you control can't be countered":
  -- every counterer, the defaulted key left out.
  Spec.it s "MkCounterProhibition" $
    Common.assertCodec
      s
      CounterProhibition.codec
      (CounterProhibition.MkCounterProhibition (Filter.HasCardType CardType.Creature) (Filter.And []))
      " {\"countered\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Autumn's Veil's "by blue or black spells".
  Spec.it s "counterers" $
    Common.assertCodec
      s
      CounterProhibition.codec
      (CounterProhibition.MkCounterProhibition (Filter.Not Filter.IsAbility) (Filter.Or [Filter.HasColor Color.Blue, Filter.HasColor Color.Black]))
      " {\"countered\":{\"type\":\"Not\",\"value\":{\"type\":\"IsAbility\"}},\"counterers\":{\"type\":\"Or\",\"value\":[{\"type\":\"HasColor\",\"value\":{\"type\":\"Blue\"}},{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterProhibition.codec
