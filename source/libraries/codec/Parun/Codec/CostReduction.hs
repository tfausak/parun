{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CostReduction where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.CostDirection as CostDirection
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CostDirection as CostDirection.Type
import qualified Parun.Types.CostReduction as CostReduction

-- | A bare object keyed by the record's field names, the shape
-- Parun.Codec.AppliedReduction takes.
--
-- 'amount' and 'perEach' are REQUIRED: Ertai's Scorn's fixed reduction spells
-- its Literal 1 'perEach' out rather than leaning on a default. An absent
-- 'condition' is Nothing, the unconditional reduction Thrasta prints; an absent
-- 'whichTargets' names no target, and an absent 'direction' is Less, the
-- sentence every card but a "costs more" one prints.
codec :: Codec.Codec CostReduction.CostReduction
codec = Fields.object $ do
  amount <- Fields.required "amount" ManaCost.codec CostReduction.amount
  perEach <- Fields.required "perEach" Quantity.codec CostReduction.perEach
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) CostReduction.condition
  whichTargets <- Fields.defaulted "whichTargets" Nothing (Common.maybe (Filter.codec Keyword.codec)) CostReduction.whichTargets
  direction <- Fields.defaulted "direction" CostDirection.Type.Less CostDirection.codec CostReduction.direction
  pure
    CostReduction.MkCostReduction
      { CostReduction.amount = amount,
        CostReduction.perEach = perEach,
        CostReduction.condition = condition,
        CostReduction.whichTargets = whichTargets,
        CostReduction.direction = direction
      }
