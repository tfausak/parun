module Parun.Codec.CostChangeSpec where

import qualified Parun.Codec.CostChange as CostChange
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AppliedReduction as AppliedReduction
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CostAddition as CostAddition
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostChange as CostChange.Type
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostScale as CostScale
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.Sacrifice as Sacrifice

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostChange" $ do
  Spec.it s "Increase, Thalia's" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 2]))
      " {\"type\":\"Increase\",\"value\":[{\"type\":\"Generic\",\"value\":2}]} "
  Spec.it s "Increase, Derelor's" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Increase (ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Black)]))
      " {\"type\":\"Increase\",\"value\":[{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Black\"}}}]} "
  -- The rules' defaults, no floor and CR 118.7b-d's spill, write no key.
  Spec.it s "Reduce, Sapphire Medallion's" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Reduce (AppliedReduction.MkAppliedReduction (ManaCost.MkManaCost [ManaSymbol.Generic 1]) 0 False))
      " {\"type\":\"Reduce\",\"value\":{\"amount\":[{\"type\":\"Generic\",\"value\":1}]}} "
  Spec.it s "Reduce, Edgewalker's coloured mana only" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Reduce (AppliedReduction.MkAppliedReduction (ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.White)]) 0 True))
      " {\"type\":\"Reduce\",\"value\":{\"amount\":[{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}}}],\"coloredOnly\":true}} "
  Spec.it s "Reduce, Heartstone's floor" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Reduce (AppliedReduction.MkAppliedReduction (ManaCost.MkManaCost [ManaSymbol.Generic 1]) 1 False))
      " {\"type\":\"Reduce\",\"value\":{\"amount\":[{\"type\":\"Generic\",\"value\":1}],\"atLeast\":1}} "
  -- A scale of Once writes no key.
  Spec.it s "Add, Brutal Suppression's" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Add (CostAddition.MkCostAddition [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) (Filter.HasCardType CardType.Land))] CostScale.Once))
      " {\"type\":\"Add\",\"value\":{\"components\":[{\"type\":\"Sacrifice\",\"value\":{\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}]}} "
  Spec.it s "Add, Drought's scale" $
    Common.assertCodec
      s
      CostChange.codec
      (CostChange.Type.Add (CostAddition.MkCostAddition [] (CostScale.PerColoredSymbol Color.Black)))
      " {\"type\":\"Add\",\"value\":{\"components\":[],\"scale\":{\"type\":\"PerColoredSymbol\",\"value\":{\"type\":\"Black\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CostChange.codec
