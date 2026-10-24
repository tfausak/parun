module Parun.Codec.ProjectedCharacteristicsSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.CardSpec as CardSpec
import qualified Parun.Codec.FaceSpec as FaceSpec
import qualified Parun.Codec.ProjectedCharacteristics as PC
import qualified Parun.Codec.RuleAbilitiesSpec as RuleAbilitiesSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AlternativeCost as AlternativeCost
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.ChangeWord as ChangeWord
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatDamageOption as CombatDamageOption
import qualified Parun.Types.CopyException as CopyException
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostDirection as CostDirection
import qualified Parun.Types.CostReduction as CostReduction
import qualified Parun.Types.Face as Face.Type
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SpecialAction as SpecialAction
import qualified Parun.Types.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TextWord as TextWord
import qualified Parun.Types.Timestamp as Timestamp

-- | `name` and `cardTypes` are the only required keys; every other field is
-- omitted when it is at its default. One populated fixture, with every
-- collection given at least one element and 'loyalty'/'characteristicPT' left
-- at Nothing, exercises the whole shape at once including those omissions;
-- `minimalCharacteristics` below is its counterpart with everything but the two
-- required keys defaulted.
--
-- No registry here: like Parun.Codec.CardSpec, this sublibrary sits above
-- Parun.Registry and cannot reach a real snapshot. Round trips over an
-- engine-built snapshot stay in Parun.CodecIntegrationSpec.

-- | A synthetic snapshot, not any real card's projection: its supertype and
-- subtype are chosen to exercise every collection field.
testCharacteristics :: PC.ProjectedCharacteristics
testCharacteristics =
  PC.MkProjectedCharacteristics
    { PC.names = Set.singleton . CardName.MkCardName $ Text.pack "Test Creature",
      PC.supertypes = Set.singleton Supertype.Legendary,
      PC.keywords = Map.singleton Keyword.Flying 1,
      PC.colors = Set.singleton Color.Blue,
      PC.manaCost = Just (ManaCost.MkManaCost [ManaSymbol.Generic 2, ManaSymbol.OfType (ManaType.Colored Color.Blue)]),
      PC.manaValue = Just 3,
      PC.power = Just 1,
      PC.toughness = Just 2,
      PC.loyalty = Nothing,
      PC.defense = Nothing,
      PC.intensity = Nothing,
      PC.characteristicPT = Nothing,
      PC.cardTypes = Set.singleton CardType.Creature,
      PC.subtypes = Set.singleton Subtype.Human,
      PC.staticAbilities = [StaticAbility.MkStaticAbility Affected.Attached Nothing Set.empty Nothing Nothing (NonEmpty.singleton (Modification.GainKeyword Keyword.Flying))],
      PC.playerAbilities = [PlayerStaticAbility.MkPlayerStaticAbility {PlayerStaticAbility.scope = PlayerScope.Related PlayerRelation.AnyPlayer, PlayerStaticAbility.condition = Nothing, PlayerStaticAbility.name = Nothing, PlayerStaticAbility.effect = PlayerEffect.CantCastMoreThan 1}],
      PC.grantedPlayerAbilities = [(Timestamp.MkTimestamp 3, PlayerStaticAbility.MkPlayerStaticAbility {PlayerStaticAbility.scope = PlayerScope.Related PlayerRelation.You, PlayerStaticAbility.condition = Nothing, PlayerStaticAbility.name = Nothing, PlayerStaticAbility.effect = PlayerEffect.NoMaximumHandSize})],
      PC.grantedStaticAbilities = [(Timestamp.MkTimestamp 4, StaticAbility.MkStaticAbility Affected.Attached Nothing Set.empty Nothing Nothing (NonEmpty.singleton (Modification.GainKeyword Keyword.Trample)))],
      PC.grantedRuleAbilities = RuleAbilitiesSpec.testRuleAbilities,
      PC.specialActions = [SpecialAction.DiscardThisAnyTime],
      PC.activatedAbilities = [],
      PC.replacementEffects = [],
      PC.triggeredAbilities = [FaceSpec.minimalTriggeredAbility],
      PC.delayedAbilities = Map.singleton (AbilityName.MkAbilityName (Text.pack "later")) FaceSpec.minimalTriggeredAbility,
      PC.enchant = [TargetSlot.required Pool.Creatures Nothing],
      PC.castingPermissions = [CastingPermission.CastFromLibraryWhileSearching],
      -- Parun.Codec.RuleAbilitiesSpec's own fixture, which is where the twelve
      -- keys inside it are checked; here the case is only that the bundle rides
      -- one key of this record's own object.
      PC.ruleAbilities = RuleAbilitiesSpec.testRuleAbilities,
      -- True rather than the default, so an arm that dropped the field would not
      -- round trip to the same JSON.
      PC.lostAllAbilities = True,
      PC.hasFullText = True,
      PC.wordChanges = [ChangeWord.MkChangeWord (TextWord.SubtypeWord Subtype.Spirit) (TextWord.SubtypeWord Subtype.Elf)],
      -- A different keyword from `keywords` above, so a codec arm reading the
      -- wrong field would not round trip to the same JSON.
      PC.textChangedKeywords = Map.singleton Keyword.Trample 1,
      PC.assignsCombatDamageWithToughness = True,
      PC.combatDamageOptions = Set.singleton CombatDamageOption.ToDefendingCreature,
      PC.grantsStationToughness = True,
      -- Parun.Codec.FaceSpec's own values for the four cost fields.
      PC.additionalCosts = [CostComponent.TapThis],
      PC.additionalCostChoices = [CostChoice.MkCostChoice (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis] NonEmpty.:| [Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []])],
      PC.alternativeCosts = [AlternativeCost.MkAlternativeCost Nothing (Cost.MkCost (Just (ManaCost.MkManaCost [])) [])],
      PC.costReductions = [CostReduction.MkCostReduction (ManaCost.MkManaCost [ManaSymbol.Generic 3]) (Quantity.Literal 1) Nothing Nothing CostDirection.Less],
      PC.grantedCostReductions = [CostReduction.MkCostReduction (ManaCost.MkManaCost [ManaSymbol.Generic 1]) (Quantity.Literal 1) Nothing Nothing CostDirection.Less],
      PC.grantedAlternativeCosts = [AlternativeCost.MkAlternativeCost Nothing (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) [])],
      PC.grantedSpendManaAsThough = [SpendManaAsThough.MkSpendManaAsThough ManaFilter.Any (Set.singleton ManaType.Colorless) True],
      -- Synthetic like the rest of this value: a Mountain has no halves, and
      -- what the case is about is that the field carries a whole card through
      -- the wire (CR 709.5).
      PC.halves = Just CardSpec.mountainCard,
      -- CR 707.9b, synthetic for halves' reason.
      PC.exceptions = [CopyException.NoManaCost],
      -- CR 702.140e, synthetic for halves' reason.
      PC.mergedDonors = [minimalCharacteristics],
      -- Synthetic for halves' reason: a Mountain has no inset frame, and what
      -- the case is about is that the field carries a whole FACE through the
      -- wire (CR 722.2b).
      PC.prepare = Just (NonEmpty.head (Card.Type.faces CardSpec.mountainCard)),
      -- Synthetic for prepare's reason (CR 715.2b).
      PC.alternativeSpell = Just (NonEmpty.head (Card.Type.faces CardSpec.mountainCard)),
      -- Synthetic for prepare's reason: a Mountain is no prototype card (CR
      -- 718.2a).
      PC.prototyped = True,
      -- Two empty modes, off the default of one (CR 707.2).
      PC.spell = Face.Type.defaultSpell {Modal.modes = Modal.modes (Face.Type.defaultSpell :: Modal.Modal Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) <> Modal.modes Face.Type.defaultSpell},
      -- The recursive field, carrying the all-default record so the nested
      -- object's own defaults are exercised too (CR 707.3).
      PC.flipped = Just minimalCharacteristics
    }

testCharacteristicsJson :: String
testCharacteristicsJson =
  "{\"names\":[\"Test Creature\"],\"supertypes\":[{\"type\":\"Legendary\"}],\"keywords\":[{\"key\":{\"type\":\"Flying\"},\"value\":1}],"
    <> "\"colors\":[{\"type\":\"Blue\"}],"
    <> "\"manaCost\":[{\"type\":\"Generic\",\"value\":2},{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Blue\"}}}],"
    <> "\"manaValue\":3,\"power\":1,\"toughness\":2,"
    <> "\"cardTypes\":[{\"type\":\"Creature\"}],\"subtypes\":[{\"type\":\"Human\"}],"
    <> "\"staticAbilities\":[{\"affected\":{\"type\":\"Attached\"},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}}]}],"
    <> "\"playerAbilities\":[{\"scope\":{\"type\":\"AnyPlayer\"},\"effect\":{\"type\":\"CantCastMoreThan\",\"value\":1}}],"
    <> "\"grantedPlayerAbilities\":[{\"key\":3,\"value\":{\"scope\":{\"type\":\"You\"},\"effect\":{\"type\":\"NoMaximumHandSize\"}}}],"
    <> "\"grantedStaticAbilities\":[{\"key\":4,\"value\":{\"affected\":{\"type\":\"Attached\"},\"modifications\":[{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Trample\"}}]}}],"
    <> "\"grantedRuleAbilities\":"
    <> RuleAbilitiesSpec.testRuleAbilitiesJson
    <> ","
    <> "\"specialActions\":[{\"type\":\"DiscardThisAnyTime\"}],"
    <> "\"triggeredAbilities\":[{\"condition\":{\"type\":\"SelfEnters\"},"
    <> "\"modal\":{\"modes\":[{}]}}],"
    <> "\"delayedAbilities\":{\"later\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}}},"
    <> "\"enchant\":[{\"pool\":{\"type\":\"Creatures\"}}],"
    <> "\"castingPermissions\":[{\"type\":\"CastFromLibraryWhileSearching\"}],"
    <> "\"ruleAbilities\":"
    <> RuleAbilitiesSpec.testRuleAbilitiesJson
    <> ","
    <> "\"lostAllAbilities\":true,"
    <> "\"hasFullText\":true,"
    <> "\"wordChanges\":[{\"from\":{\"type\":\"Spirit\"},\"to\":{\"type\":\"Elf\"}}],"
    <> "\"textChangedKeywords\":[{\"key\":{\"type\":\"Trample\"},\"value\":1}],"
    <> "\"assignsCombatDamageWithToughness\":true,"
    <> "\"combatDamageOptions\":[{\"type\":\"ToDefendingCreature\"}],"
    <> "\"grantsStationToughness\":true,"
    <> "\"additionalCosts\":[{\"type\":\"TapThis\"}],"
    <> "\"additionalCostChoices\":[[{\"components\":[{\"type\":\"TapThis\"}],\"mana\":[]},{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}]],"
    <> "\"alternativeCosts\":[{\"cost\":{\"mana\":[]}}],"
    <> "\"costReductions\":[{\"amount\":[{\"type\":\"Generic\",\"value\":3}],\"perEach\":{\"type\":\"Literal\",\"value\":1}}],"
    <> "\"grantedCostReductions\":[{\"amount\":[{\"type\":\"Generic\",\"value\":1}],\"perEach\":{\"type\":\"Literal\",\"value\":1}}],"
    <> "\"grantedAlternativeCosts\":[{\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]}}],"
    <> "\"grantedSpendManaAsThough\":[{\"which\":{\"type\":\"Any\"},\"asThough\":[{\"type\":\"Colorless\"}],\"only\":true}],"
    <> "\"halves\":{\"faces\":[{\"name\":\"Mountain\",\"typeLine\":{\"supertypes\":[{\"type\":\"Basic\"}],\"types\":[{\"type\":\"Land\"}],\"subtypes\":[{\"type\":\"Mountain\"}]}}]},"
    <> "\"exceptions\":[{\"type\":\"NoManaCost\"}],"
    <> "\"mergedDonors\":[{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}],"
    <> "\"prepare\":{\"name\":\"Mountain\",\"typeLine\":{\"supertypes\":[{\"type\":\"Basic\"}],\"types\":[{\"type\":\"Land\"}],\"subtypes\":[{\"type\":\"Mountain\"}]}},"
    <> "\"alternativeSpell\":{\"name\":\"Mountain\",\"typeLine\":{\"supertypes\":[{\"type\":\"Basic\"}],\"types\":[{\"type\":\"Land\"}],\"subtypes\":[{\"type\":\"Mountain\"}]}},"
    <> "\"prototyped\":true,"
    <> "\"spell\":{\"modes\":[{},{}]},"
    <> "\"flipped\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}}"

-- | Every field but the two required ones at its default.
minimalCharacteristics :: PC.ProjectedCharacteristics
minimalCharacteristics =
  PC.MkProjectedCharacteristics
    { PC.names = Set.singleton (CardName.MkCardName (Text.pack "Mountain")),
      PC.supertypes = Set.empty,
      PC.keywords = Map.empty,
      PC.colors = Set.empty,
      PC.manaCost = Nothing,
      PC.manaValue = Nothing,
      PC.power = Nothing,
      PC.toughness = Nothing,
      PC.loyalty = Nothing,
      PC.defense = Nothing,
      PC.intensity = Nothing,
      PC.characteristicPT = Nothing,
      PC.cardTypes = Set.singleton CardType.Land,
      PC.subtypes = Set.empty,
      PC.staticAbilities = [],
      PC.playerAbilities = [],
      PC.grantedPlayerAbilities = [],
      PC.grantedStaticAbilities = [],
      PC.grantedRuleAbilities = mempty,
      PC.specialActions = [],
      PC.activatedAbilities = [],
      PC.replacementEffects = [],
      PC.triggeredAbilities = [],
      PC.delayedAbilities = Map.empty,
      PC.enchant = [],
      PC.castingPermissions = [],
      PC.ruleAbilities = mempty,
      PC.lostAllAbilities = False,
      PC.hasFullText = False,
      PC.wordChanges = [],
      PC.textChangedKeywords = Map.empty,
      PC.assignsCombatDamageWithToughness = False,
      PC.combatDamageOptions = Set.empty,
      PC.grantsStationToughness = False,
      PC.additionalCosts = [],
      PC.additionalCostChoices = [],
      PC.alternativeCosts = [],
      PC.costReductions = [],
      PC.grantedCostReductions = [],
      PC.grantedAlternativeCosts = [],
      PC.grantedSpendManaAsThough = [],
      PC.halves = Nothing,
      PC.exceptions = [],
      PC.mergedDonors = [],
      PC.prepare = Nothing,
      PC.alternativeSpell = Nothing,
      PC.prototyped = False,
      PC.spell = Face.Type.defaultSpell,
      PC.flipped = Nothing
    }

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ProjectedCharacteristics" $ do
  Spec.it s "MkProjectedCharacteristics, every collection populated, loyalty and characteristicPT omitted at Nothing" $
    Common.assertCodec s PC.codec testCharacteristics testCharacteristicsJson
  Spec.it s "an all-default value omits every optional key" $
    Common.assertCodec
      s
      PC.codec
      minimalCharacteristics
      " {\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]} "
