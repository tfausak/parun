{-# LANGUAGE ApplicativeDo #-}

-- | @Face@ is the entry point to the rest of @Parun.Codec@: the transitive
-- closure of @Face@'s fields is one module per type, each exposing a 'Codec.Codec'
-- bundle, and this module is where they are instantiated at @Face@.
--
-- Parametric in the card codec the way 'Parun.Types.Face.Face' is parametric in
-- @card@: @Parun.Codec.Card@ passes its own in, which is where the knot is tied.
--
-- Every @Parun.Types.*@ module stays JSON-free. Casing on an effect's identity
-- anywhere under @Parun.Codec@ is open-half machinery, not the rules core.
module Parun.Codec.Face where

import qualified Control.Monad as Monad
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.ActivationProhibition as ActivationProhibition
import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.AlternativeCost as AlternativeCost
import qualified Parun.Codec.AttachRestriction as AttachRestriction
import qualified Parun.Codec.AttackCost as AttackCost
import qualified Parun.Codec.AttackPermission as AttackPermission
import qualified Parun.Codec.AttackRequirement as AttackRequirement
import qualified Parun.Codec.BlockCost as BlockCost
import qualified Parun.Codec.BlockPermission as BlockPermission
import qualified Parun.Codec.BlockRequirement as BlockRequirement
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CastingPermission as CastingPermission
import qualified Parun.Codec.CastingRestriction as CastingRestriction
import qualified Parun.Codec.CharacteristicPT as CharacteristicPT
import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.CombatRestriction as CombatRestriction
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.CostChoice as CostChoice
import qualified Parun.Codec.CostComponent as CostComponent
import qualified Parun.Codec.CostReduction as CostReduction
import qualified Parun.Codec.CounterRestriction as CounterRestriction
import qualified Parun.Codec.Counterability as Counterability
import qualified Parun.Codec.CrewRestriction as CrewRestriction
import qualified Parun.Codec.Defense as Defense
import qualified Parun.Codec.DungeonRoom as DungeonRoom
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.EntryRestriction as EntryRestriction
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.HandAction as HandAction
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Loyalty as Loyalty
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.Modal as Modal
import qualified Parun.Codec.ModeIndex as ModeIndex
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Codec.Power as Power
import qualified Parun.Codec.PrintedReplacement as PrintedReplacement
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SacrificeRestriction as SacrificeRestriction
import qualified Parun.Codec.SpecialAction as SpecialAction
import qualified Parun.Codec.StaticAbility as StaticAbility
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.Codec.TargetRestriction as TargetRestriction
import qualified Parun.Codec.TargetSlot as TargetSlot
import qualified Parun.Codec.Toughness as Toughness
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.Codec.TypeLine as TypeLine
import qualified Parun.Codec.UntapRestriction as UntapRestriction
import qualified Parun.Codec.Vanguard as Vanguard
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Counterability as Counterability.Type
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Modal as Modal.Type
import qualified Parun.Types.ModeIndex as ModeIndex.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation.Type
import qualified Parun.Types.TypeLine as TypeLine

-- | CR 700.2h's cost belongs to a mode the face HAS: a key past the end of
-- `spell`'s mode list is a mistranscription, and silently dropping it would make
-- that mode free.
modeCostsInRange :: Face.Face card -> Either Text.Text (Face.Face card)
modeCostsInRange f =
  let indices = fmap ModeIndex.Type.MkModeIndex (take (Seq.length (Modal.Type.modes (Face.spell f))) [0 ..])
   in if all (\i -> elem i indices) (Map.keys (Face.modeCosts f))
        then Right f
        else Left (Text.pack "modeCosts names a mode the spell does not have")

-- | CR 700.2e names a chooser of MODES, so a face naming a chooser other than
-- its controller has two or more of them (CR 700.2).
chooserHasModes :: Face.Face card -> Either Text.Text (Face.Face card)
chooserHasModes f =
  if Face.modeChooser f == PlayerRelation.Type.You || Seq.length (Modal.Type.modes (Face.spell f)) > 1
    then Right f
    else Left (Text.pack "modeChooser names a chooser for a spell with one mode")

-- | @Eq card@ because several fields below carry card-shaped payloads and
-- 'Fields.defaulted' omits a key by comparing its value to the default.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: (Typeable.Typeable card, Eq card) => Codec.Codec card -> Codec.Codec (Face.Face card)
codec cardCodec = Fields.objectWith (modeCostsInRange Monad.>=> chooserHasModes) $ do
  name <- Fields.required "name" CardName.codec Face.name
  oracleText <- Fields.defaulted "oracleText" Nothing (Common.maybe Common.text) Face.oracleText
  -- CR 205.1 puts a type line on every card and CR 114.3 gives an emblem no
  -- types at all, so the key is optional and its absence means the latter: an
  -- emblem's face is authored as the payload of Effect.CreateEmblem and decoded
  -- through this same codec. A key that IS present must still name a card type,
  -- which is Parun.Codec.TypeLine's own reading of CR 205.1. Which faces may
  -- leave it out is a question about the corpus rather than about the wire, and
  -- Parun.CardSpec's lint -- "only an emblem's face has no card type" -- asks it.
  typeLine <- Fields.defaulted "typeLine" TypeLine.empty TypeLine.codec Face.typeLine
  manaCost <- Fields.defaulted "manaCost" Nothing (Common.maybe ManaCost.codec) Face.manaCost
  power <- Fields.defaulted "power" Nothing (Common.maybe Power.codec) Face.power
  toughness <- Fields.defaulted "toughness" Nothing (Common.maybe Toughness.codec) Face.toughness
  loyalty <- Fields.defaulted "loyalty" Nothing (Common.maybe Loyalty.codec) Face.loyalty
  defense <- Fields.defaulted "defense" Nothing (Common.maybe Defense.codec) Face.defense
  startingIntensity <- Fields.defaulted "startingIntensity" Nothing (Common.maybe Common.natural) Face.startingIntensity
  -- CR 313.6 / 313.7: absent on every card but a vanguard.
  vanguard <- Fields.defaulted "vanguard" Nothing (Common.maybe Vanguard.codec) Face.vanguard
  -- A quantity per box, as Face.characteristicPT holds them: Sutured Ghoul's
  -- power and toughness are two different totals (CR 208.2a). Substituting a
  -- quantity into a box that prints no star is the identity.
  characteristicPT <- Fields.defaulted "characteristicPT" Nothing (Common.maybe CharacteristicPT.codec) Face.characteristicPT
  enchant <- Fields.defaulted "enchant" [] (Common.list TargetSlot.codec) Face.enchant
  -- ONE ARRAY ENTRY PER INSTANCE (Common.repeats), which is how Apex Devastator
  -- prints it: "Cascade, cascade, cascade, cascade". A card naming each keyword
  -- once reads and writes exactly as it did when this was a set.
  keywords <- Fields.defaulted "keywords" Map.empty (Common.repeats Keyword.codec) Face.keywords
  colorIndicator <- Fields.defaulted "colorIndicator" Set.empty (Common.set Color.codec) Face.colorIndicator
  spell <- Fields.defaulted "spell" Face.defaultSpell (Modal.codec cardCodec (GrantedAbility.codec cardCodec)) Face.spell
  staticAbilities <- Fields.defaulted "staticAbilities" [] (Common.list (StaticAbility.codec (GrantedAbility.codec cardCodec))) Face.staticAbilities
  activatedAbilities <- Fields.defaulted "activatedAbilities" [] (Common.list (ActivatedAbility.codec cardCodec (GrantedAbility.codec cardCodec))) Face.activatedAbilities
  replacementEffects <- Fields.defaulted "replacementEffects" [] (Common.list (PrintedReplacement.codec cardCodec (GrantedAbility.codec cardCodec) (Effect.codec cardCodec (GrantedAbility.codec cardCodec)))) Face.replacementEffects
  triggeredAbilities <- Fields.defaulted "triggeredAbilities" [] (Common.list (TriggeredAbility.codec cardCodec (GrantedAbility.codec cardCodec))) Face.triggeredAbilities
  delayedAbilities <- Fields.defaulted "delayedAbilities" Map.empty (TriggeredAbility.codecDelayed cardCodec (GrantedAbility.codec cardCodec)) Face.delayedAbilities
  -- CR 309.4: the rooms of a dungeon card, topmost first.
  rooms <- Fields.defaulted "rooms" Seq.empty (Common.seq (DungeonRoom.codec cardCodec)) Face.rooms
  -- CR 701.49d: the quality a venture must indicate to bring this dungeon in.
  dungeonEntryQuality <- Fields.defaulted "dungeonEntryQuality" Nothing (Common.maybe Subtype.codec) Face.dungeonEntryQuality
  castingPermissions <- Fields.defaulted "castingPermissions" [] (Common.list CastingPermission.codec) Face.castingPermissions
  castingRestrictions <- Fields.defaulted "castingRestrictions" [] (Common.list CastingRestriction.codec) Face.castingRestrictions
  playerAbilities <- Fields.defaulted "playerAbilities" [] (Common.list PlayerStaticAbility.codec) Face.playerAbilities
  blockRequirements <- Fields.defaulted "blockRequirements" [] (Common.list BlockRequirement.codec) Face.blockRequirements
  blockPermissions <- Fields.defaulted "blockPermissions" [] (Common.list BlockPermission.codec) Face.blockPermissions
  attackRequirements <- Fields.defaulted "attackRequirements" [] (Common.list AttackRequirement.codec) Face.attackRequirements
  combatRestrictions <- Fields.defaulted "combatRestrictions" [] (Common.list CombatRestriction.codec) Face.combatRestrictions
  sacrificeRestrictions <- Fields.defaulted "sacrificeRestrictions" [] (Common.list SacrificeRestriction.codec) Face.sacrificeRestrictions
  untapRestrictions <- Fields.defaulted "untapRestrictions" [] (Common.list UntapRestriction.codec) Face.untapRestrictions
  crewRestrictions <- Fields.defaulted "crewRestrictions" [] (Common.list CrewRestriction.codec) Face.crewRestrictions
  targetRestrictions <- Fields.defaulted "targetRestrictions" [] (Common.list (TargetRestriction.codec Affected.codec)) Face.targetRestrictions
  attackPermissions <- Fields.defaulted "attackPermissions" [] (Common.list AttackPermission.codec) Face.attackPermissions
  attachRestrictions <- Fields.defaulted "attachRestrictions" [] (Common.list AttachRestriction.codec) Face.attachRestrictions
  counterRestrictions <- Fields.defaulted "counterRestrictions" [] (Common.list CounterRestriction.codec) Face.counterRestrictions
  activationProhibitions <- Fields.defaulted "activationProhibitions" [] (Common.list ActivationProhibition.codec) Face.activationProhibitions
  entryRestrictions <- Fields.defaulted "entryRestrictions" [] (Common.list EntryRestriction.codec) Face.entryRestrictions
  attackCosts <- Fields.defaulted "attackCosts" [] (Common.list AttackCost.codec) Face.attackCosts
  blockCosts <- Fields.defaulted "blockCosts" [] (Common.list BlockCost.codec) Face.blockCosts
  additionalCosts <- Fields.defaulted "additionalCosts" [] (Common.list (CostComponent.codec Keyword.codec)) Face.additionalCosts
  -- CR 118.8 / 601.2b: an additional cost whose payment offers the caster a
  -- choice, each option a whole Cost because an option can be mana
  -- (Parun.Types.CostChoice).
  additionalCostChoices <- Fields.defaulted "additionalCostChoices" [] (Common.list CostChoice.codec) Face.additionalCostChoices
  -- CR 700.2h: the cost printed before a mode's effect, keyed by that mode's
  -- index into `spell` -- an object rather than an array so a card lists only
  -- the modes that print one (Parun.Types.Face).
  modeCosts <- Fields.defaulted "modeCosts" Map.empty (Common.naturalMap ModeIndex.codec (Cost.codec Keyword.codec)) Face.modeCosts
  -- CR 700.2e: who chooses the spell's modes, emitted only for a face whose
  -- chooser is not its controller (Parun.Types.Face).
  modeChooser <- Fields.defaulted "modeChooser" PlayerRelation.Type.You PlayerRelation.codec Face.modeChooser
  -- CR 101.1: the ceilings this face's own words put on CR 601.2b's announced X
  -- (Parun.Types.Face).
  maximumX <- Fields.defaulted "maximumX" [] (Common.list Quantity.codec) Face.maximumX
  -- CR 101.1: the floor on that X, emitted only for a face that states one.
  minimumX <- Fields.defaulted "minimumX" 0 Common.natural Face.minimumX
  alternativeCosts <- Fields.defaulted "alternativeCosts" [] (Common.list AlternativeCost.codec) Face.alternativeCosts
  -- CR 601.2f: the reductions this face applies to its own cost to cast
  -- (Parun.Types.CostReduction).
  costReductions <- Fields.defaulted "costReductions" [] (Common.list CostReduction.codec) Face.costReductions
  -- CR 103.5b / CR 103.6: an array of ACTIONS, each an array of effects, so a
  -- face granting two of them is writable (Parun.Types.Face).
  mulliganActions <- Fields.defaulted "mulliganActions" [] (Common.list (HandAction.codec cardCodec)) Face.mulliganActions
  openingHandActions <- Fields.defaulted "openingHandActions" [] (Common.list (HandAction.codec cardCodec)) Face.openingHandActions
  -- CR 116.2: the special actions this face grants (Parun.Types.Face).
  specialActions <- Fields.defaulted "specialActions" [] (Common.list SpecialAction.codec) Face.specialActions
  -- CR 113.6g: Counterable is the absence of a card stating it can't be
  -- countered.
  counterability <- Fields.defaulted "counterability" Counterability.Type.Counterable Counterability.codec Face.counterability
  -- CR 903.3a: False is the absence of a card stating it can be your
  -- commander.
  canBeYourCommander <- Fields.defaulted "canBeYourCommander" False Common.boolean Face.canBeYourCommander
  -- CR 103.1c: False is the absence of a card stating its controller is the
  -- starting player.
  claimsStartingPlayer <- Fields.defaulted "claimsStartingPlayer" False Common.boolean Face.claimsStartingPlayer
  -- CR 407.3: False is the absence of the ante reminder.
  anteOnly <- Fields.defaulted "anteOnly" False Common.boolean Face.anteOnly
  pure
    Face.MkFace
      { Face.name = name,
        Face.oracleText = oracleText,
        Face.typeLine = typeLine,
        Face.manaCost = manaCost,
        Face.power = power,
        Face.toughness = toughness,
        Face.loyalty = loyalty,
        Face.defense = defense,
        Face.startingIntensity = startingIntensity,
        Face.vanguard = vanguard,
        Face.characteristicPT = characteristicPT,
        Face.enchant = enchant,
        Face.keywords = keywords,
        Face.colorIndicator = colorIndicator,
        Face.spell = spell,
        Face.staticAbilities = staticAbilities,
        Face.activatedAbilities = activatedAbilities,
        Face.replacementEffects = replacementEffects,
        Face.triggeredAbilities = triggeredAbilities,
        Face.delayedAbilities = delayedAbilities,
        Face.rooms = rooms,
        Face.dungeonEntryQuality = dungeonEntryQuality,
        Face.castingPermissions = castingPermissions,
        Face.castingRestrictions = castingRestrictions,
        Face.playerAbilities = playerAbilities,
        Face.blockRequirements = blockRequirements,
        Face.blockPermissions = blockPermissions,
        Face.attackRequirements = attackRequirements,
        Face.combatRestrictions = combatRestrictions,
        Face.sacrificeRestrictions = sacrificeRestrictions,
        Face.untapRestrictions = untapRestrictions,
        Face.crewRestrictions = crewRestrictions,
        Face.targetRestrictions = targetRestrictions,
        Face.attackPermissions = attackPermissions,
        Face.attachRestrictions = attachRestrictions,
        Face.counterRestrictions = counterRestrictions,
        Face.activationProhibitions = activationProhibitions,
        Face.entryRestrictions = entryRestrictions,
        Face.attackCosts = attackCosts,
        Face.blockCosts = blockCosts,
        Face.additionalCosts = additionalCosts,
        Face.additionalCostChoices = additionalCostChoices,
        Face.modeCosts = modeCosts,
        Face.modeChooser = modeChooser,
        Face.maximumX = maximumX,
        Face.minimumX = minimumX,
        Face.alternativeCosts = alternativeCosts,
        Face.costReductions = costReductions,
        Face.mulliganActions = mulliganActions,
        Face.openingHandActions = openingHandActions,
        Face.specialActions = specialActions,
        Face.counterability = counterability,
        Face.canBeYourCommander = canBeYourCommander,
        Face.claimsStartingPlayer = claimsStartingPlayer,
        Face.anteOnly = anteOnly
      }
