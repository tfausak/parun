module Parun.Codec.CostModifierSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.CostModifier as CostModifier
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.AppliedReduction as AppliedReduction
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostModifier as CostModifier.Type
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostModifier" $ do
  -- Every Maybe criterion absent: Thalia's shape, and no key written for any.
  Spec.it s "a spell increase" $
    Common.assertCodec
      s
      CostModifier.codec
      (CostModifier.Type.MkCostModifier CostSubject.Spells (Filter.Not (Filter.HasCardType CardType.Creature)) Nothing Nothing Nothing Nothing (CostChange.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 1])))
      " {\"subject\":{\"type\":\"Spells\"},\"matching\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"change\":{\"type\":\"Increase\",\"value\":[{\"type\":\"Generic\",\"value\":1}]}} "
  -- Every criterion present on the activation subject: Professor Hojo's first,
  -- Zirda's kind, Dwarven Mauler's target, Henzie's count, Heartstone's floor.
  Spec.it s "an activation reduction with every criterion" $
    Common.assertCodec
      s
      CostModifier.codec
      ( CostModifier.Type.MkCostModifier
          (CostSubject.Activations (ActivationCriteria.MkActivationCriteria Nothing (Just AbilityKind.NonManaAbility) Nothing))
          (Filter.HasCardType CardType.Creature)
          (Just Filter.IsSource)
          (Just (Filter.HasCardType CardType.Creature))
          (Just (Quantity.CommanderCasts (PlayerRef.Relative PlayerRelation.You)))
          (Just TurnScope.ControllersTurn)
          (CostChange.Reduce (AppliedReduction.MkAppliedReduction (ManaCost.MkManaCost [ManaSymbol.Generic 2]) 1 False))
      )
      " {\"subject\":{\"type\":\"Activations\",\"value\":{\"whichKind\":{\"type\":\"NonManaAbility\"}}},\"matching\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"whichTargets\":{\"type\":\"IsSource\"},\"perTarget\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"perEach\":{\"type\":\"CommanderCasts\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"onlyFirst\":{\"type\":\"ControllersTurn\"},\"change\":{\"type\":\"Reduce\",\"value\":{\"amount\":[{\"type\":\"Generic\",\"value\":2}],\"atLeast\":1}}} "
  Spec.it s "refuses a spell's onlyFirst (#4924)" $
    Spec.assertBool
      s
      (Either.isLeft (Codec.decode CostModifier.codec =<< Common.parse (Text.pack "{\"subject\":{\"type\":\"Spells\"},\"matching\":{\"type\":\"IsSource\"},\"onlyFirst\":{\"type\":\"ControllersTurn\"},\"change\":{\"type\":\"Increase\",\"value\":[{\"type\":\"Generic\",\"value\":1}]}}")))
      "expected a decode failure"
  Spec.it s "refuses onlyFirst beside whichLoyalty" $
    Spec.assertBool
      s
      (Either.isLeft (Codec.decode CostModifier.codec =<< Common.parse (Text.pack "{\"subject\":{\"type\":\"Activations\",\"value\":{\"whichLoyalty\":{\"type\":\"LoyaltyAbility\"}}},\"matching\":{\"type\":\"IsSource\"},\"onlyFirst\":{\"type\":\"ControllersTurn\"},\"change\":{\"type\":\"Increase\",\"value\":[{\"type\":\"Generic\",\"value\":1}]}}")))
      "expected a decode failure"
  Spec.it s "refuses a target criterion on an addition to an activation" $
    Spec.assertBool
      s
      (Either.isLeft (Codec.decode CostModifier.codec =<< Common.parse (Text.pack "{\"subject\":{\"type\":\"Activations\",\"value\":{}},\"matching\":{\"type\":\"IsSource\"},\"whichTargets\":{\"type\":\"IsSource\"},\"change\":{\"type\":\"Add\",\"value\":{\"components\":[]}}}")))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s CostModifier.codec
