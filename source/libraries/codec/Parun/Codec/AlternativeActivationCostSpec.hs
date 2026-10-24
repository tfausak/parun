module Parun.Codec.AlternativeActivationCostSpec where

import qualified Parun.Codec.AlternativeActivationCost as AlternativeActivationCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AlternativeActivationCost as AlternativeActivationCost
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AlternativeActivationCost" $ do
  -- Kíli the Resourceful's shape: the first equip ability each turn, for {0}.
  Spec.it s "the first equip ability each turn" $
    Common.assertCodec
      s
      AlternativeActivationCost.codec
      AlternativeActivationCost.MkAlternativeActivationCost
        { AlternativeActivationCost.grantedBy = KeywordDesignator.OfFamily KeywordFamily.Equip,
          AlternativeActivationCost.onlyFirst = Just TurnScope.EachTurn,
          AlternativeActivationCost.cost = ManaCost.MkManaCost []
        }
      " {\"grantedBy\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Equip\"}},\"onlyFirst\":{\"type\":\"EachTurn\"},\"cost\":[]} "
  -- onlyFirst is DEFAULTED, so its absence is its own case.
  Spec.it s "every matching ability" $
    Common.assertCodec
      s
      AlternativeActivationCost.codec
      AlternativeActivationCost.MkAlternativeActivationCost
        { AlternativeActivationCost.grantedBy = KeywordDesignator.OfFamily KeywordFamily.Equip,
          AlternativeActivationCost.onlyFirst = Nothing,
          AlternativeActivationCost.cost = ManaCost.MkManaCost [ManaSymbol.Generic 1]
        }
      " {\"grantedBy\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Equip\"}},\"cost\":[{\"type\":\"Generic\",\"value\":1}]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s AlternativeActivationCost.codec
