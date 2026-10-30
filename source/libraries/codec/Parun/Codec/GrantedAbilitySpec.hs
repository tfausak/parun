module Parun.Codec.GrantedAbilitySpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AlternativeCost as AlternativeCost
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostDirection as CostDirection
import qualified Parun.Types.CostReduction as CostReduction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeMemory as ModeMemory
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility

-- | The `card` parameter is instantiated at 'Text.Text', reached only through the
-- Modal codec, the posture 'Parun.Codec.ActivatedAbilitySpec' takes.
codec :: Codec.Codec (GrantedAbility.GrantedAbility Text.Text)
codec = GrantedAbility.codec Common.text

emptyModal :: Modal.Modal Text.Text (GrantedAbility.GrantedAbility Text.Text)
emptyModal = Modal.MkModal (Seq.singleton (Mode.MkMode Seq.empty Map.empty)) (ModeSelection.ChooseExactly 1) ModeMemory.NoMemory

-- Every arm, since the whole point of the type is that CR 613.1f's grant reaches
-- several of CR 113.3's ability kinds and the wire has to say which.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.GrantedAbility" $ do
  -- Presence of Gond's "{T}: ..." reduced to its cost.
  Spec.it s "Activated" $
    Common.assertCodec
      s
      codec
      ( GrantedAbility.Activated
          ( ActivatedAbility.MkActivatedAbility
              (Cost.MkCost Nothing [CostComponent.TapThis])
              []
              0
              Nothing
              emptyModal
              []
              Activator.Controller
              Nothing
              Nothing
              Nothing
          )
      )
      " {\"type\":\"Activated\",\"value\":{\"cost\":{\"mana\":null,\"components\":[{\"type\":\"TapThis\"}]},\"modal\":{\"modes\":[{}]}}} "
  -- Sixth Sense's "Whenever this creature deals combat damage to a player, ..."
  -- reduced to its condition.
  Spec.it s "Triggered" $
    Common.assertCodec
      s
      codec
      ( GrantedAbility.Triggered
          ( TriggeredAbility.MkTriggeredAbility
              (TriggerCondition.SelfDealsCombatDamageToPlayer PlayerRelation.AnyPlayer)
              emptyModal
              Nothing
              Nothing
              TriggerLimit.Unlimited
              Set.empty
          )
      )
      " {\"type\":\"Triggered\",\"value\":{\"condition\":{\"type\":\"SelfDealsCombatDamageToPlayer\",\"value\":{\"type\":\"AnyPlayer\"}},\"modal\":{\"modes\":[{}]}}} "
  -- Streetwise Negotiator's "This creature assigns combat damage equal to its
  -- toughness rather than its power", as backup hands it over.
  Spec.it s "Static" $
    Common.assertCodec
      s
      codec
      ( GrantedAbility.Static
          ( StaticAbility.MkStaticAbility
              (Affected.Matching Filter.IsSource)
              Nothing
              Set.empty
              Nothing
              Nothing
              (NonEmpty.singleton Modification.AssignCombatDamageWithToughness)
          )
      )
      " {\"type\":\"Static\",\"value\":{\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"modifications\":[{\"type\":\"AssignCombatDamageWithToughness\"}]}} "
  -- Chomping Kavu's "This creature can't be blocked by creatures with power 2
  -- or less", as backup hands it over.
  Spec.it s "Rules" $
    Common.assertCodec
      s
      codec
      ( GrantedAbility.Rules
          mempty
            { RuleAbilities.combatRestrictions =
                [CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching Filter.IsSource) (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.AtMost (Operand.Literal 2))) Nothing Nothing)]
            }
      )
      " {\"type\":\"Rules\",\"value\":{\"combatRestrictions\":[{\"type\":\"CantBeBlockedBy\",\"value\":{\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"blockers\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"AtMost\"},\"operand\":{\"type\":\"Literal\",\"value\":2}}}}}]}} "
  -- CR 613.10: Nerd Rage's "You have no maximum hand size".
  Spec.it s "Player" $
    Common.assertCodec
      s
      codec
      (GrantedAbility.Player (PlayerStaticAbility.MkPlayerStaticAbility (PlayerScope.Related PlayerRelation.You) Nothing Nothing PlayerEffect.NoMaximumHandSize))
      " {\"type\":\"Player\",\"value\":{\"scope\":{\"type\":\"You\"},\"effect\":{\"type\":\"NoMaximumHandSize\"}}} "
  -- CR 601.2f: Richlau, Headmaster's "This spell costs {1} less to cast".
  Spec.it s "SelfCostReduction" $
    Common.assertCodec
      s
      codec
      (GrantedAbility.SelfCostReduction (CostReduction.MkCostReduction (ManaCost.MkManaCost [ManaSymbol.Generic 1]) (Quantity.Literal 1) Nothing Nothing CostDirection.Less))
      " {\"type\":\"SelfCostReduction\",\"value\":{\"amount\":[{\"type\":\"Generic\",\"value\":1}],\"perEach\":{\"type\":\"Literal\",\"value\":1}}} "
  -- CR 118.9: Mine Security's "You may pay {0} rather than pay this spell's
  -- mana cost".
  Spec.it s "SelfAlternativeCost" $
    Common.assertCodec
      s
      codec
      (GrantedAbility.SelfAlternativeCost (AlternativeCost.MkAlternativeCost Nothing (Cost.MkCost (Just (ManaCost.MkManaCost [])) [])))
      " {\"type\":\"SelfAlternativeCost\",\"value\":{\"cost\":{\"mana\":[]}}} "
  -- CR 609.4b: Tome of the Infinite's "You may spend mana as though it were mana
  -- of any color to cast this spell", one color shown.
  Spec.it s "SelfSpendManaAsThough" $
    Common.assertCodec
      s
      codec
      (GrantedAbility.SelfSpendManaAsThough (SpendManaAsThough.MkSpendManaAsThough ManaFilter.Any (Set.singleton (ManaType.Colored Color.Red)) False))
      " {\"type\":\"SelfSpendManaAsThough\",\"value\":{\"which\":{\"type\":\"Any\"},\"asThough\":[{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}}],\"only\":false}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
