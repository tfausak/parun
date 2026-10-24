module Parun.Codec.CostReductionSpec where

import qualified Parun.Codec.CostReduction as CostReduction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.CostDirection as CostDirection
import qualified Parun.Types.CostReduction as CostReduction
import qualified Parun.Types.Count as Count
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostReduction" $ do
  -- CR 601.2f, as Thrasta, Tempest's Roar costs {3} less for each other spell
  -- cast this turn.
  Spec.it s "MkCostReduction" $
    Common.assertCodec
      s
      CostReduction.codec
      ( CostReduction.MkCostReduction
          { CostReduction.amount = ManaCost.MkManaCost [ManaSymbol.Generic 3],
            CostReduction.perEach =
              Quantity.Count
                Count.MkCount
                  { Count.scope = Scope.InHistory EventShape.SpellCast,
                    Count.filter = Filter.And [],
                    Count.aggregation = Aggregation.Members
                  },
            CostReduction.condition = Nothing,
            CostReduction.whichTargets = Nothing,
            CostReduction.direction = CostDirection.Less
          }
      )
      " {\"amount\":[{\"type\":\"Generic\",\"value\":3}],\"perEach\":{\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InHistory\",\"value\":{\"type\":\"SpellCast\"}},\"filter\":{\"type\":\"And\",\"value\":[]},\"aggregation\":{\"type\":\"Members\"}}}} "
  -- CR 601.2f, as Ertai's Scorn costs {U} less if an opponent cast two or more
  -- spells this turn.
  Spec.it s "with a condition" $
    Common.assertCodec
      s
      CostReduction.codec
      ( CostReduction.MkCostReduction
          { CostReduction.amount = ManaCost.MkManaCost [ManaSymbol.Generic 1],
            CostReduction.perEach = Quantity.Literal 1,
            CostReduction.condition = Just (Condition.Compares (Compares.MkCompares (Quantity.Literal 2) Comparison.AtLeast (Quantity.Literal 3))),
            CostReduction.whichTargets = Nothing,
            CostReduction.direction = CostDirection.Less
          }
      )
      " {\"amount\":[{\"type\":\"Generic\",\"value\":1}],\"perEach\":{\"type\":\"Literal\",\"value\":1},\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":2},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":3}}}} "
  -- CR 601.2c / 601.2f, as Bury in Books costs {2} less if it targets an
  -- attacking creature.
  Spec.it s "with a target filter" $
    Common.assertCodec
      s
      CostReduction.codec
      ( CostReduction.MkCostReduction
          { CostReduction.amount = ManaCost.MkManaCost [ManaSymbol.Generic 2],
            CostReduction.perEach = Quantity.Literal 1,
            CostReduction.condition = Nothing,
            CostReduction.whichTargets = Just Filter.IsAttacking,
            CostReduction.direction = CostDirection.Less
          }
      )
      " {\"amount\":[{\"type\":\"Generic\",\"value\":2}],\"perEach\":{\"type\":\"Literal\",\"value\":1},\"whichTargets\":{\"type\":\"IsAttacking\"}} "
  -- CR 601.2f, as Dragon's Prey costs {2} more if it targets a Dragon.
  Spec.it s "costing more" $
    Common.assertCodec
      s
      CostReduction.codec
      ( CostReduction.MkCostReduction
          { CostReduction.amount = ManaCost.MkManaCost [ManaSymbol.Generic 2],
            CostReduction.perEach = Quantity.Literal 1,
            CostReduction.condition = Nothing,
            CostReduction.whichTargets = Just (Filter.HasSubtype Subtype.Dragon),
            CostReduction.direction = CostDirection.More
          }
      )
      " {\"amount\":[{\"type\":\"Generic\",\"value\":2}],\"perEach\":{\"type\":\"Literal\",\"value\":1},\"whichTargets\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Dragon\"}},\"direction\":{\"type\":\"More\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CostReduction.codec
