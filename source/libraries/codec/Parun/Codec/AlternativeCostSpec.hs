module Parun.Codec.AlternativeCostSpec where

import qualified Parun.Codec.AlternativeCost as AlternativeCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AlternativeCost as AlternativeCost
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AlternativeCost" $ do
  -- CR 118.9's ordinary case, Fireblast's: no condition, so the key is omitted.
  Spec.it s "an unconditioned alternative omits the condition key" $
    Common.assertCodec
      s
      AlternativeCost.codec
      AlternativeCost.MkAlternativeCost
        { AlternativeCost.condition = Nothing,
          AlternativeCost.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = []}
        }
      " {\"cost\":{\"mana\":[]}} "
  -- CR 604.2's "as long as" clause on one,
  -- Asmoranomardicadaistinaculdacar's: the condition is the payload a recursive
  -- decoder could lose, so it is round-tripped alongside a mana part that is not
  -- {0}.
  Spec.it s "a conditioned alternative round-trips its condition" $
    Common.assertCodec
      s
      AlternativeCost.codec
      AlternativeCost.MkAlternativeCost
        { AlternativeCost.condition =
            Just
              ( Condition.Compares
                  ( Compares.MkCompares
                      (Quantity.CardsDiscardedThisTurn (PlayerRef.Relative PlayerRelation.You))
                      Comparison.AtLeast
                      (Quantity.Literal 1)
                  )
              ),
          AlternativeCost.cost =
            Cost.MkCost
              { Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Hybrid (Hybrid.MkHybrid (ManaType.Colored Color.Black) (ManaType.Colored Color.Red))]),
                Cost.components = []
              }
        }
      " {\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"CardsDiscardedThisTurn\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"cost\":{\"mana\":[{\"type\":\"Hybrid\",\"value\":{\"left\":{\"type\":\"Colored\",\"value\":{\"type\":\"Black\"}},\"right\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}}}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AlternativeCost.codec
