-- Oracle text a card file can be checked against (#9). Pawl.IngestSpec asserts
-- that each pool card 'renderings' answers for says what its faces'
-- Face.oracleText says, modulo Pawl.Oracle.Normalise.normalise.
--
-- Rendering is compositional over the DSL, one module per type family, never
-- a lookup of known cards' wordings: a card that renders back to its Oracle
-- text is one whose DSL says what the card says (#5477). That check sees what
-- a card SAYS, never what it DOES: an ingested flier is right only because
-- Pawl.Engine.Keyword's flying is (docs/design.md section 4).
module Pawl.Oracle where

import qualified Control.Monad as Monad
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Pawl.Oracle.Cost as Cost
import qualified Pawl.Oracle.Effect as Effect
import qualified Pawl.Oracle.Keyword as Keyword
import qualified Pawl.Oracle.Normalise as Normalise
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Oracle.Target as Target
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Activator as Activator
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Cost as Cost.Type
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.Counterability as Counterability
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Keyword as Keyword.Type
import qualified Pawl.Types.Layout as Layout
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.Power as Power
import qualified Pawl.Types.Toughness as Toughness
import qualified Pawl.Types.TriggerCondition as TriggerCondition
import qualified Pawl.Types.TriggerLimit as TriggerLimit
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility
import qualified Pawl.Types.TypeLine as TypeLine

-- | The card's rules text in its current Oracle wording, or 'Nothing' for a
-- card some part of which is not rendered yet.
render :: Card.Card -> Maybe Text.Text
render = Maybe.listToMaybe . renderings

-- | Every wording of the card's rules text Oracle uses, the current first;
-- empty for a card some part of which is not rendered yet. Only a single
-- normal face renders yet, and only the parts of it the fields below name:
-- its keywords, its spell (CR 112), its activated abilities (CR 602) and its
-- triggered abilities (CR 603). A card with no rules text renders as no
-- text, which is what a vanilla creature and a basic land print (CR 305.6, CR
-- 207.2a).
renderings :: Card.Card -> [Text.Text]
renderings card = case Card.faces card of
  face NonEmpty.:| [] | Card.layout card == Layout.Normal -> faceText face
  _ -> []

-- | Whether the text is one of the card's renderings, modulo
-- 'Normalise.normalise'.
says :: Card.Card -> CardName.CardName -> Text.Text -> Bool
says card name text = elem (Normalise.normalise name text) (fmap (Normalise.normalise name) (renderings card))

-- | A face's rules text, one ability per line. The face with the fields
-- rendered here cleared must be 'bare', so a field nothing here renders keeps
-- the card unrendered rather than silently left out.
faceText :: Face.Face Card.Card -> [Text.Text]
faceText face = do
  let self = CardName.unwrap (Face.name face)
      context = Target.MkContext self Map.empty (Keyword.keywordWord self) [Text.pack " "]
      rest = face {Face.keywords = Map.empty, Face.spell = Face.defaultSpell, Face.activatedAbilities = [], Face.triggeredAbilities = []}
  Monad.guard (rest == bare (Face.name face) (Face.oracleText face) (Face.manaCost face) (Face.colorIndicator face) (Face.typeLine face) (Face.power face) (Face.toughness face) Map.empty)
  keywords <- Keyword.lines self (Face.keywords face)
  spell <-
    if Face.spell face == Face.defaultSpell
      then [[]]
      else fmap pure (Effect.modal context {Target.breaks = [Text.pack " ", Text.pack "\n"]} (Face.spell face))
  abilities <- traverse (activated context) (Face.activatedAbilities face)
  triggers <- traverse (triggered context) (Face.triggeredAbilities face)
  [Text.intercalate (Text.pack "\n") (keywords <> spell <> abilities <> triggers)]

-- | A triggered ability: "[When/Whenever/At] [trigger event], [effect]" (CR
-- 603.1), the effect calling the source "it" once the event has named it
-- (Fire Imp). Only a trigger on its source entering or dying renders yet (CR
-- 603.6a, CR 700.4), dying in either its current wording or the older "is put
-- into a graveyard from the battlefield" (Chromatic Star); an intervening
-- "if", a limit, a name, or a trigger from another zone is not spelled out
-- here.
triggered :: Target.Context -> TriggeredAbility.TriggeredAbility card ability -> [Text.Text]
triggered context t
  | Maybe.isNothing (TriggeredAbility.intervening t),
    Maybe.isNothing (TriggeredAbility.name t),
    TriggeredAbility.limit t == TriggerLimit.Unlimited,
    Set.null (TriggeredAbility.functionsFrom t) = do
      event <- case TriggeredAbility.condition t of
        TriggerCondition.SelfEnters -> [Text.pack " enters"]
        TriggerCondition.SelfDies -> [Text.pack " dies", Text.pack " is put into a graveyard from the battlefield"]
        _ -> []
      let self = Target.self context
      effect <- concatMap (\c -> Effect.modal c (TriggeredAbility.modal t)) [context, context {Target.self = Text.pack "it"}]
      let lowered = if Text.isPrefixOf self effect then effect else Prose.decapitalise effect
      [Text.pack "When " <> self <> event <> Text.pack ", " <> lowered]
  | otherwise = []

-- | An activated ability: "[Cost]: [Effect.]" (CR 602.1a). An ability whose
-- cost sacrifices its source may call it "it" after that (Mogg Mob). Only an
-- ability its controller activates at any time renders yet: a restriction, a
-- condition, a named or keyword ability, or a bound on X is not spelled out
-- here.
activated :: Target.Context -> ActivatedAbility.ActivatedAbility card ability -> [Text.Text]
activated context a
  | null (ActivatedAbility.maximumX a),
    ActivatedAbility.minimumX a == 0,
    Maybe.isNothing (ActivatedAbility.definedX a),
    null (ActivatedAbility.restrictions a),
    ActivatedAbility.activator a == Activator.Controller,
    Maybe.isNothing (ActivatedAbility.condition a),
    Maybe.isNothing (ActivatedAbility.name a),
    Maybe.isNothing (ActivatedAbility.keyword a) = do
      cost <- Cost.cost (Target.self context) (ActivatedAbility.cost a)
      let sacrificed = elem CostComponent.SacrificeThis (Cost.Type.components (ActivatedAbility.cost a))
          selves = context : [context {Target.self = Text.pack "it"} | sacrificed]
      effect <- concatMap (\c -> Effect.modal c (ActivatedAbility.modal a)) selves
      [cost <> Text.pack ": " <> effect]
  | otherwise = []

-- | A face with the given Oracle text, characteristics and keywords and nothing
-- else. Every field is spelled out, so a field added to 'Face.Face' fails to
-- compile here rather than being silently ignored by 'faceText'.
bare ::
  CardName.CardName ->
  Maybe Text.Text ->
  Maybe ManaCost.ManaCost ->
  Set.Set Color.Color ->
  TypeLine.TypeLine ->
  Maybe Power.Power ->
  Maybe Toughness.Toughness ->
  Map.Map Keyword.Type.Keyword Natural.Natural ->
  Face.Face Card.Card
bare n t c i l p x k =
  Face.MkFace
    { Face.name = n,
      Face.oracleText = t,
      Face.manaCost = c,
      Face.typeLine = l,
      Face.power = p,
      Face.toughness = x,
      Face.loyalty = Nothing,
      Face.defense = Nothing,
      Face.startingIntensity = Nothing,
      Face.vanguard = Nothing,
      Face.canBeYourCommander = False,
      Face.claimsStartingPlayer = False,
      Face.anteOnly = False,
      Face.keywords = k,
      Face.colorIndicator = i,
      Face.characteristicPT = Nothing,
      Face.staticAbilities = [],
      Face.spell = Face.defaultSpell,
      Face.activatedAbilities = [],
      Face.replacementEffects = [],
      Face.triggeredAbilities = [],
      Face.delayedAbilities = Map.empty,
      Face.rooms = Seq.empty,
      Face.dungeonEntryQuality = Nothing,
      Face.castingPermissions = [],
      Face.castingRestrictions = [],
      Face.enchant = [],
      Face.counterability = Counterability.Counterable,
      Face.additionalCosts = [],
      Face.additionalCostChoices = [],
      Face.modeCosts = Map.empty,
      Face.maximumX = [],
      Face.minimumX = 0,
      Face.alternativeCosts = [],
      Face.costReductions = [],
      Face.playerAbilities = [],
      Face.blockRequirements = [],
      Face.blockPermissions = [],
      Face.attackRequirements = [],
      Face.combatRestrictions = [],
      Face.sacrificeRestrictions = [],
      Face.untapRestrictions = [],
      Face.crewRestrictions = [],
      Face.attackPermissions = [],
      Face.attachRestrictions = [],
      Face.entryRestrictions = [],
      Face.counterRestrictions = [],
      Face.activationProhibitions = [],
      Face.attackCosts = [],
      Face.blockCosts = [],
      Face.mulliganActions = [],
      Face.openingHandActions = [],
      Face.specialActions = []
    }
