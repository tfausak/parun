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
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Oracle.Continuous as Continuous
import qualified Pawl.Oracle.Cost as Cost
import qualified Pawl.Oracle.Effect as Effect
import qualified Pawl.Oracle.Face as Face.Oracle
import qualified Pawl.Oracle.Keyword as Keyword
import qualified Pawl.Oracle.Normalise as Normalise
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Oracle.Target as Target
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Activator as Activator
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Cost as Cost.Type
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Keyword as Keyword.Type
import qualified Pawl.Types.Layout as Layout
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
-- its keywords, its enchant abilities (CR 702.5a), its static abilities (CR
-- 604), its spell (CR 112), its activated abilities (CR 602) and its
-- triggered abilities (CR 603). A card with no rules text renders as no text,
-- which is what a vanilla creature and a basic land print (CR 305.6, CR
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
-- rendered here cleared must be 'Face.Oracle.bare', so a field nothing here
-- renders keeps the card unrendered rather than silently left out.
faceText :: Face.Face Card.Card -> [Text.Text]
faceText face = do
  let self = CardName.unwrap (Face.name face)
      context = Target.MkContext self Map.empty (Keyword.keywordWord self) [Text.pack " "] Nothing
      rest = face {Face.keywords = Map.empty, Face.spell = Face.defaultSpell, Face.activatedAbilities = [], Face.triggeredAbilities = [], Face.staticAbilities = [], Face.enchant = []}
      subtypes = TypeLine.subtypes (Face.typeLine face)
  Monad.guard (rest == Face.Oracle.bare (Face.name face) (Face.oracleText face) (Face.manaCost face) (Face.colorIndicator face) (Face.typeLine face) (Face.power face) (Face.toughness face) Map.empty)
  keywords <- Keyword.lines self (Face.keywords face)
  spell <-
    if Face.spell face == Face.defaultSpell
      then [[]]
      else fmap pure (Effect.modal context {Target.breaks = [Text.pack " ", Text.pack "\n"]} (Face.spell face))
  enchants <- traverse (Continuous.enchant context) (Face.enchant face)
  let bestowed = any (\k -> case k of Keyword.Type.Bestow _ -> True; _ -> False) (Map.keys (Face.keywords face))
  statics <- traverse (Continuous.static context (Continuous.attachedWord subtypes bestowed) (Face.enchant face)) (Face.staticAbilities face)
  abilities <- traverse (activated context) (Face.activatedAbilities face)
  triggers <- traverse (triggered context (Set.member CardType.Creature (TypeLine.types (Face.typeLine face)))) (Face.triggeredAbilities face)
  [Text.intercalate (Text.pack "\n") (keywords <> enchants <> statics <> spell <> abilities <> triggers)]

-- | A triggered ability: "[When/Whenever/At] [trigger event], [effect]" (CR
-- 603.1), the effect calling the source "it" once the event has named it
-- (Fire Imp), and the card it became in a graveyard "it" too (Undying
-- Beast). Only a trigger on its source entering or dying renders yet (CR
-- 603.6a). A creature "dies"; any other permanent "is put into a graveyard
-- from the battlefield", the same event (CR 700.4) in the words Oracle text
-- keeps for it (Chromatic Star). An intervening "if", a limit, a name, or a
-- trigger from another zone is not spelled out here.
triggered :: (Eq ability) => Target.Context -> Bool -> TriggeredAbility.TriggeredAbility Card.Card ability -> [Text.Text]
triggered context creature t
  | Maybe.isNothing (TriggeredAbility.intervening t),
    Maybe.isNothing (TriggeredAbility.name t),
    TriggeredAbility.limit t == TriggerLimit.Unlimited,
    Set.null (TriggeredAbility.functionsFrom t) = do
      (event, became) <- case TriggeredAbility.condition t of
        TriggerCondition.SelfEnters -> [(Text.pack " enters", Nothing)]
        TriggerCondition.SelfDies
          | creature -> [(Text.pack " dies", Just (Text.pack "it"))]
          | otherwise -> [(Text.pack " is put into a graveyard from the battlefield", Just (Text.pack "it"))]
        _ -> []
      effect <- Effect.modal context {Target.self = Text.pack "it", Target.became = became} (TriggeredAbility.modal t)
      [Text.pack "When " <> Target.self context <> event <> Text.pack ", " <> Prose.decapitalise effect]
  | otherwise = []

-- | An activated ability: "[Cost]: [Effect.]" (CR 602.1a). An ability whose
-- cost sacrifices its source calls it "it" after that (Mogg Mob). Only an
-- ability its controller activates at any time renders yet: a restriction, a
-- condition, a named or keyword ability, or a bound on X is not spelled out
-- here.
activated :: (Eq ability) => Target.Context -> ActivatedAbility.ActivatedAbility Card.Card ability -> [Text.Text]
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
          after = if sacrificed then context {Target.self = Text.pack "it"} else context
      effect <- Effect.modal after (ActivatedAbility.modal a)
      [cost <> Text.pack ": " <> effect]
  | otherwise = []
