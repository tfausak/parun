module Parun.Codec.CostSubjectSpec where

import qualified Parun.Codec.CostSubject as CostSubject
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.CostSubject as CostSubject.Type
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.LoyaltyKind as LoyaltyKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostSubject" $ do
  Spec.it s "Spells" $
    Common.assertCodec
      s
      CostSubject.codec
      CostSubject.Type.Spells
      " {\"type\":\"Spells\"} "
  -- Every criterion absent writes an empty object: Heartstone's shape.
  Spec.it s "Activations, every ability" $
    Common.assertCodec
      s
      CostSubject.codec
      (CostSubject.Type.Activations (ActivationCriteria.MkActivationCriteria Nothing Nothing Nothing))
      " {\"type\":\"Activations\",\"value\":{}} "
  Spec.it s "Activations, every criterion" $
    Common.assertCodec
      s
      CostSubject.codec
      (CostSubject.Type.Activations (ActivationCriteria.MkActivationCriteria (Just (KeywordDesignator.OfFamily KeywordFamily.Equip)) (Just AbilityKind.NonManaAbility) (Just LoyaltyKind.LoyaltyAbility)))
      " {\"type\":\"Activations\",\"value\":{\"grantedBy\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Equip\"}},\"whichKind\":{\"type\":\"NonManaAbility\"},\"whichLoyalty\":{\"type\":\"LoyaltyAbility\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CostSubject.codec
