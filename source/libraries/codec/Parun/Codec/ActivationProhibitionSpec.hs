module Parun.Codec.ActivationProhibitionSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ActivationProhibition as ActivationProhibition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ActivationProhibition as ActivationProhibition
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActivationProhibition" $ do
  -- Arrest's second clause (CR 602.2 / CR 101.2), which names no kind, so the
  -- key is absent -- the wire form data/cards/arrest.json writes.
  Spec.it s "MkActivationProhibition, no kind named" $
    Common.assertCodec
      s
      ActivationProhibition.codec
      ( ActivationProhibition.MkActivationProhibition
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          Nothing
          Nothing
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Realmbreaker's Grasp's "unless they're mana abilities", which names one.
  Spec.it s "MkActivationProhibition, a named kind" $
    Common.assertCodec
      s
      ActivationProhibition.codec
      ( ActivationProhibition.MkActivationProhibition
          Affected.Attached
          (Just AbilityKind.NonManaAbility)
          Nothing
      )
      " {\"affected\":{\"type\":\"Attached\"},\"kind\":{\"type\":\"NonManaAbility\"}} "
  -- CR 116.2d: Volrath's Curse names the ability its own ignore refers to, and
  -- names it on all three of the rows that one sentence declares.
  Spec.it s "MkActivationProhibition, a named ability" $
    Common.assertCodec
      s
      ActivationProhibition.codec
      ( ActivationProhibition.MkActivationProhibition
          Affected.Attached
          Nothing
          (Just (AbilityName.MkAbilityName (Text.pack "this effect")))
      )
      " {\"affected\":{\"type\":\"Attached\"},\"name\":\"this effect\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ActivationProhibition.codec
