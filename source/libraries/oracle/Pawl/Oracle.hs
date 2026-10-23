-- Oracle text a card file can be checked against (#9). Pawl.IngestSpec asserts
-- that each pool card 'render' answers for says what its faces'
-- Face.oracleText says, modulo Pawl.Oracle.Normalise.normalise.
--
-- Rendering is compositional over the DSL, one module per type family, never
-- a lookup of known cards' wordings: a card that renders back to its Oracle
-- text is one whose DSL says what the card says (#5477). That check sees what
-- a card SAYS, never what it DOES: an ingested flier is right only because
-- Pawl.Engine.Keyword's flying is (docs/design.md section 4).
module Pawl.Oracle where

import qualified Control.Monad as Monad
import qualified Data.Containers.ListUtils as ListUtils
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
import qualified Pawl.Oracle.Trigger as Trigger
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
import qualified Pawl.Types.TriggerLimit as TriggerLimit
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility
import qualified Pawl.Types.TypeLine as TypeLine

-- | The card's rules text in its current Oracle wording, or 'Nothing' for a
-- card some part of which is not rendered yet: the head wording of each
-- ability, one per line.
render :: Card.Card -> Maybe Text.Text
render card = do
  face <- single card
  fmap (Text.intercalate (Text.pack "\n")) (traverse Maybe.listToMaybe (faceAbilities face))

-- | The card's abilities, each with every wording of it Oracle uses, the
-- current first, and none for an ability not rendered yet. An ability's
-- wordings are its own, so the choices of one ability add to those of the
-- next rather than multiplying with them. Only a single normal face is read
-- yet: every ability of any other card is listed unrendered.
abilities :: Card.Card -> [[Text.Text]]
abilities card = case single card of
  Just face -> faceAbilities face
  Nothing -> concatMap (fmap (const []) . faceAbilities) (Card.faces card)

-- | The card's face, when it is the one normal face this renders: a card of
-- any other layout is not rendered yet, even one whose faces hold nothing.
single :: Card.Card -> Maybe (Face.Face Card.Card)
single card = case Card.faces card of
  face NonEmpty.:| [] | Card.layout card == Layout.Normal -> Just face
  _ -> Nothing

-- | Whether the text says what the card says: each of its abilities takes
-- one of its wordings' pieces from the text's, modulo 'Normalise.normalise',
-- and none is left over. A card some part of which is not rendered yet says
-- nothing.
says :: Card.Card -> CardName.CardName -> Text.Text -> Bool
says card name text =
  Maybe.isJust (render card) && any null (leftovers name text (abilities card))

-- | The text's pieces left over once each ability has taken the pieces of one
-- of its wordings, one list per way they can. The face keeps no printed
-- order, so abilities pair with the text as a multiset, as
-- 'Normalise.normalise' sorts lines; a spell's instructions are one ability
-- even across paragraphs (CR 113.3a), so its wording takes pieces from
-- several lines.
leftovers :: CardName.CardName -> Text.Text -> [[Text.Text]] -> [[Text.Text]]
leftovers name text = Monad.foldM taken (Normalise.normalise name text)
  where
    taken pieces = Maybe.mapMaybe (without pieces . Normalise.normalise name)

-- | The first sorted list less the second, or 'Nothing' when the second is
-- not a sub-multiset of the first.
without :: (Ord a) => [a] -> [a] -> Maybe [a]
without whole part = case (whole, part) of
  (_, []) -> Just whole
  ([], _ : _) -> Nothing
  (w : ws, p : ps) -> case compare w p of
    LT -> fmap (w :) (without ws part)
    EQ -> without ws ps
    GT -> Nothing

-- | A face's abilities, each with its wordings: its keywords, its enchant
-- abilities (CR 702.5a), its characteristic-defining power and toughness
-- (CR 604.3), its static abilities (CR 604), its spell (CR 112), its
-- activated abilities (CR 602) and its triggered abilities (CR 603). A face
-- with no rules text has no abilities, which is what a vanilla creature and a
-- basic land print (CR 305.6, CR 207.2a). Whatever else the face holds is one
-- more ability, never rendered: the face with the fields rendered here
-- cleared must be 'Face.Oracle.bare', so a field nothing here renders keeps
-- the card unrendered rather than silently left out.
faceAbilities :: Face.Face Card.Card -> [[Text.Text]]
faceAbilities face =
  let self = CardName.unwrap (Face.name face)
      context = Target.MkContext self Map.empty (Keyword.keywordWord self) [Text.pack " "] Map.empty []
      rest = face {Face.keywords = Map.empty, Face.spell = Face.defaultSpell, Face.activatedAbilities = [], Face.triggeredAbilities = [], Face.staticAbilities = [], Face.enchant = [], Face.characteristicPT = Nothing}
      subtypes = TypeLine.subtypes (Face.typeLine face)
      unread = rest /= Face.Oracle.bare (Face.name face) (Face.oracleText face) (Face.manaCost face) (Face.colorIndicator face) (Face.typeLine face) (Face.power face) (Face.toughness face) Map.empty
      spell = [Effect.modal context {Target.breaks = [Text.pack " ", Text.pack "\n"]} (Face.spell face) | Face.spell face /= Face.defaultSpell]
      bestowed = any (\k -> case k of Keyword.Type.Bestow _ -> True; _ -> False) (Map.keys (Face.keywords face))
   in Keyword.abilities self (Face.keywords face)
        <> fmap (Continuous.enchant context) (Face.enchant face)
        <> fmap (Continuous.defining context (Face.power face) (Face.toughness face)) (Maybe.maybeToList (Face.characteristicPT face))
        <> fmap (Continuous.static context (Continuous.attachedWord subtypes bestowed) (Face.enchant face)) (Face.staticAbilities face)
        <> spell
        <> fmap (activated context) (Face.activatedAbilities face)
        <> fmap (triggered context (Set.member CardType.Creature (TypeLine.types (Face.typeLine face)))) (Face.triggeredAbilities face)
        <> [[] | unread]

-- | A triggered ability: "[When/Whenever/At] [trigger event], [effect]" (CR
-- 603.1), the effect calling the source "it" once the event has named it
-- (Fire Imp), and with an intervening "if" clause between them (CR 603.4).
-- A limit, a name, or a trigger from another zone is not spelled out here.
triggered :: (Eq ability) => Target.Context -> Bool -> TriggeredAbility.TriggeredAbility Card.Card ability -> [Text.Text]
triggered context creature t
  | Maybe.isNothing (TriggeredAbility.name t),
    TriggeredAbility.limit t == TriggerLimit.Unlimited,
    Set.null (TriggeredAbility.functionsFrom t) = ListUtils.nubOrd $ do
      e <- Trigger.event context creature (TriggeredAbility.condition t)
      -- Free once the event has named the source: "it" (Fire Imp) or the
      -- source's own name (Crimson Roc's "this creature").
      named <- if Trigger.named e then [Text.pack "it", Target.self context] else [Target.self context]
      let after = context {Target.self = named, Target.bound = Trigger.bound e, Target.owned = Trigger.owned e}
      (word, gate) <- case TriggeredAbility.intervening t of
        Nothing -> [(Text.empty, Text.empty)]
        Just c -> do
          condition <- Trigger.condition after c
          word <- Trigger.hellbent condition
          [(word, Text.pack ", if " <> condition)]
      effect <- Effect.modal after (TriggeredAbility.modal t)
      let named' = Text.isPrefixOf (Target.self after) effect && Target.self after /= Text.pack "it"
      [word <> Trigger.opening e <> gate <> Text.pack ", " <> (if named' then effect else Prose.decapitalise effect)]
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
