{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ProjectedCharacteristics where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.AlternativeCost as AlternativeCost
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.CastingPermission as CastingPermission
import qualified Parun.Codec.ChangeWord as ChangeWord
import qualified Parun.Codec.CharacteristicPT as CharacteristicPT
import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.CombatDamageOption as CombatDamageOption
import qualified Parun.Codec.CopyException as CopyException
import qualified Parun.Codec.CostChoice as CostChoice
import qualified Parun.Codec.CostComponent as CostComponent
import qualified Parun.Codec.CostReduction as CostReduction
import qualified Parun.Codec.Defense as Defense
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.Face as Face
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Loyalty as Loyalty
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.Modal as Modal
import qualified Parun.Codec.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Codec.PrintedReplacement as PrintedReplacement
import qualified Parun.Codec.RuleAbilities as RuleAbilities
import qualified Parun.Codec.SpecialAction as SpecialAction
import qualified Parun.Codec.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Codec.StaticAbility as StaticAbility
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.Codec.Supertype as Supertype
import qualified Parun.Codec.TargetSlot as TargetSlot
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Face as Face.Type
import qualified Parun.Types.ProjectedCharacteristics as PC

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
--
-- RECURSIVE through `flipped`, Parun.Codec.Card's knot and for its reason.
codec :: Codec.Codec PC.ProjectedCharacteristics
codec = Fields.object $ do
  names <- Fields.required "names" (Common.set CardName.codec) PC.names
  supertypes <- Fields.defaulted "supertypes" Set.empty (Common.set Supertype.codec) PC.supertypes
  keywords <- Fields.defaulted "keywords" Map.empty (Common.multiset Keyword.codec) PC.keywords
  colors <- Fields.defaulted "colors" Set.empty (Common.set Color.codec) PC.colors
  manaCost <- Fields.defaulted "manaCost" Nothing (Common.maybe ManaCost.codec) PC.manaCost
  manaValue <- Fields.defaulted "manaValue" Nothing (Common.maybe Common.integer) PC.manaValue
  power <- Fields.defaulted "power" Nothing (Common.maybe Common.integer) PC.power
  toughness <- Fields.defaulted "toughness" Nothing (Common.maybe Common.integer) PC.toughness
  loyalty <- Fields.defaulted "loyalty" Nothing (Common.maybe Loyalty.codec) PC.loyalty
  defense <- Fields.defaulted "defense" Nothing (Common.maybe Defense.codec) PC.defense
  intensity <- Fields.defaulted "intensity" Nothing (Common.maybe Common.integer) PC.intensity
  characteristicPT <- Fields.defaulted "characteristicPT" Nothing (Common.maybe CharacteristicPT.codec) PC.characteristicPT
  cardTypes <- Fields.required "cardTypes" (Common.set CardType.codec) PC.cardTypes
  subtypes <- Fields.defaulted "subtypes" Set.empty (Common.set Subtype.codec) PC.subtypes
  staticAbilities <- Fields.defaulted "staticAbilities" [] (Common.list (StaticAbility.codec (GrantedAbility.codec Card.codec))) PC.staticAbilities
  playerAbilities <- Fields.defaulted "playerAbilities" [] (Common.list PlayerStaticAbility.codec) PC.playerAbilities
  grantedPlayerAbilities <- Fields.defaulted "grantedPlayerAbilities" [] (Common.list (Common.keyValue Timestamp.codec PlayerStaticAbility.codec)) PC.grantedPlayerAbilities
  grantedStaticAbilities <- Fields.defaulted "grantedStaticAbilities" [] (Common.list (Common.keyValue Timestamp.codec (StaticAbility.codec (GrantedAbility.codec Card.codec)))) PC.grantedStaticAbilities
  grantedRuleAbilities <- Fields.defaulted "grantedRuleAbilities" mempty RuleAbilities.codec PC.grantedRuleAbilities
  specialActions <- Fields.defaulted "specialActions" [] (Common.list SpecialAction.codec) PC.specialActions
  activatedAbilities <- Fields.defaulted "activatedAbilities" [] (Common.list (ActivatedAbility.codec Card.codec (GrantedAbility.codec Card.codec))) PC.activatedAbilities
  replacementEffects <- Fields.defaulted "replacementEffects" [] (Common.list (PrintedReplacement.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))) PC.replacementEffects
  triggeredAbilities <- Fields.defaulted "triggeredAbilities" [] (Common.list (TriggeredAbility.codec Card.codec (GrantedAbility.codec Card.codec))) PC.triggeredAbilities
  delayedAbilities <- Fields.defaulted "delayedAbilities" Map.empty (TriggeredAbility.codecDelayed Card.codec (GrantedAbility.codec Card.codec)) PC.delayedAbilities
  enchant <- Fields.defaulted "enchant" [] (Common.list TargetSlot.codec) PC.enchant
  castingPermissions <- Fields.defaulted "castingPermissions" [] (Common.list CastingPermission.codec) PC.castingPermissions
  ruleAbilities <- Fields.defaulted "ruleAbilities" mempty RuleAbilities.codec PC.ruleAbilities
  lostAllAbilities <- Fields.defaulted "lostAllAbilities" False Common.boolean PC.lostAllAbilities
  hasFullText <- Fields.defaulted "hasFullText" False Common.boolean PC.hasFullText
  wordChanges <- Fields.defaulted "wordChanges" [] (Common.list ChangeWord.codec) PC.wordChanges
  textChangedKeywords <- Fields.defaulted "textChangedKeywords" Map.empty (Common.multiset Keyword.codec) PC.textChangedKeywords
  assignsCombatDamageWithToughness <- Fields.defaulted "assignsCombatDamageWithToughness" False Common.boolean PC.assignsCombatDamageWithToughness
  combatDamageOptions <- Fields.defaulted "combatDamageOptions" Set.empty (Common.set CombatDamageOption.codec) PC.combatDamageOptions
  grantsStationToughness <- Fields.defaulted "grantsStationToughness" False Common.boolean PC.grantsStationToughness
  additionalCosts <- Fields.defaulted "additionalCosts" [] (Common.list (CostComponent.codec Keyword.codec)) PC.additionalCosts
  additionalCostChoices <- Fields.defaulted "additionalCostChoices" [] (Common.list CostChoice.codec) PC.additionalCostChoices
  alternativeCosts <- Fields.defaulted "alternativeCosts" [] (Common.list AlternativeCost.codec) PC.alternativeCosts
  costReductions <- Fields.defaulted "costReductions" [] (Common.list CostReduction.codec) PC.costReductions
  grantedCostReductions <- Fields.defaulted "grantedCostReductions" [] (Common.list CostReduction.codec) PC.grantedCostReductions
  grantedAlternativeCosts <- Fields.defaulted "grantedAlternativeCosts" [] (Common.list AlternativeCost.codec) PC.grantedAlternativeCosts
  grantedSpendManaAsThough <- Fields.defaulted "grantedSpendManaAsThough" [] (Common.list SpendManaAsThough.codec) PC.grantedSpendManaAsThough
  halves <- Fields.defaulted "halves" Nothing (Common.maybe Card.codec) PC.halves
  exceptions <- Fields.defaulted "exceptions" [] (Common.list (CopyException.codec (GrantedAbility.codec Card.codec))) PC.exceptions
  mergedDonors <- Fields.defaulted "mergedDonors" [] (Common.list codec) PC.mergedDonors
  prepare <- Fields.defaulted "prepare" Nothing (Common.maybe (Face.codec Card.codec)) PC.prepare
  alternativeSpell <- Fields.defaulted "alternativeSpell" Nothing (Common.maybe (Face.codec Card.codec)) PC.alternativeSpell
  prototyped <- Fields.defaulted "prototyped" False Common.boolean PC.prototyped
  spell <- Fields.defaulted "spell" Face.Type.defaultSpell (Modal.codec Card.codec (GrantedAbility.codec Card.codec)) PC.spell
  flipped <- Fields.defaulted "flipped" Nothing (Common.maybe codec) PC.flipped
  pure
    PC.MkProjectedCharacteristics
      { PC.names = names,
        PC.supertypes = supertypes,
        PC.keywords = keywords,
        PC.colors = colors,
        PC.manaCost = manaCost,
        PC.manaValue = manaValue,
        PC.power = power,
        PC.toughness = toughness,
        PC.loyalty = loyalty,
        PC.defense = defense,
        PC.intensity = intensity,
        PC.characteristicPT = characteristicPT,
        PC.cardTypes = cardTypes,
        PC.subtypes = subtypes,
        PC.staticAbilities = staticAbilities,
        PC.playerAbilities = playerAbilities,
        PC.grantedPlayerAbilities = grantedPlayerAbilities,
        PC.grantedStaticAbilities = grantedStaticAbilities,
        PC.grantedRuleAbilities = grantedRuleAbilities,
        PC.specialActions = specialActions,
        PC.activatedAbilities = activatedAbilities,
        PC.replacementEffects = replacementEffects,
        PC.triggeredAbilities = triggeredAbilities,
        PC.delayedAbilities = delayedAbilities,
        PC.enchant = enchant,
        PC.castingPermissions = castingPermissions,
        PC.ruleAbilities = ruleAbilities,
        PC.lostAllAbilities = lostAllAbilities,
        PC.hasFullText = hasFullText,
        PC.wordChanges = wordChanges,
        PC.textChangedKeywords = textChangedKeywords,
        PC.assignsCombatDamageWithToughness = assignsCombatDamageWithToughness,
        PC.combatDamageOptions = combatDamageOptions,
        PC.grantsStationToughness = grantsStationToughness,
        PC.additionalCosts = additionalCosts,
        PC.additionalCostChoices = additionalCostChoices,
        PC.alternativeCosts = alternativeCosts,
        PC.costReductions = costReductions,
        PC.grantedCostReductions = grantedCostReductions,
        PC.grantedAlternativeCosts = grantedAlternativeCosts,
        PC.grantedSpendManaAsThough = grantedSpendManaAsThough,
        PC.halves = halves,
        PC.exceptions = exceptions,
        PC.mergedDonors = mergedDonors,
        PC.prepare = prepare,
        PC.alternativeSpell = alternativeSpell,
        PC.prototyped = prototyped,
        PC.spell = spell,
        PC.flipped = flipped
      }
