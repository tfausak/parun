module Parun.Codec.CostChange where

import qualified Parun.Codec.AppliedReduction as AppliedReduction
import qualified Parun.Codec.CostAddition as CostAddition
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostChange as CostChange

codec :: Codec.Codec CostChange.CostChange
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Increase" ManaCost.codec CostChange.Increase (\x -> case x of CostChange.Increase y -> Just y; _ -> Nothing),
      Arm.payload "Reduce" AppliedReduction.codec CostChange.Reduce (\x -> case x of CostChange.Reduce y -> Just y; _ -> Nothing),
      Arm.payload "Add" CostAddition.codec CostChange.Add (\x -> case x of CostChange.Add y -> Just y; _ -> Nothing)
    ]

tagOf :: CostChange.CostChange -> String
tagOf x = case x of
  CostChange.Increase {} -> "Increase"
  CostChange.Reduce {} -> "Reduce"
  CostChange.Add {} -> "Add"
