-- | CR 311 and CR 312, plane and phenomenon cards: which objects are planar
-- cards, and who controls one that is face up.
--
-- A card type and not a format, Parun.Engine.Vanguard's posture: the planar
-- controller is read off the game, and a card of either type announces itself.
module Parun.Engine.Plane where

import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Face as Face
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Source as Source
import qualified Parun.Types.TriggeredAbilitySource as TriggeredAbilitySource
import qualified Parun.Types.TypeLine as TypeLine

-- | CR 311.1 / 312.1: does this face print the plane or the phenomenon card
-- type? A classification over the printed type line.
isPlanarFace :: Face.Face Card.Card -> Bool
isPlanarFace face =
  let types = TypeLine.types (Face.typeLine face)
   in Set.member CardType.Plane types || Set.member CardType.Phenomenon types

-- | CR 312.1: does this face print the phenomenon card type?
isPhenomenonFace :: Face.Face Card.Card -> Bool
isPhenomenonFace face = Set.member CardType.Phenomenon (TypeLine.types (Face.typeLine face))

-- | CR 311.2 / 312.2: is this object a plane or phenomenon card? Read off the
-- printed face, for Parun.Engine.Vanguard.isVanguard's reason: the card never
-- leaves the command zone, where nothing can copy it or change its type.
isPlanarCard :: ObjectId -> GameState -> Bool
isPlanarCard oid gs = maybe False isPlanarFace (Game.faceOf oid gs)

-- | CR 901.10 / 901.10b: the owner of the phenomenon card this object is a
-- triggered ability from, or a copy of one (CR 707.10b), and Nothing for any
-- other object. Through last-known information, since the rule asks it once the
-- phenomenon has left the game with its owner.
phenomenonOwnerOf :: ObjectId -> GameState -> Maybe PlayerId
phenomenonOwnerOf oid gs = case fmap Object.source (Game.lookupObject oid gs) of
  Just (Source.OfTrigger triggered)
    | maybe False isPhenomenonFace (Game.faceOfWithLastKnown source gs) -> Game.ownerWithLastKnown source gs
    where
      source = TriggeredAbilitySource.source triggered
  _ -> Nothing

-- | CR 901.10b: is this a phenomenon's triggered ability whose phenomenon's
-- owner has left the game? It is then the planar controller's, whoever put it
-- on the stack (CR 707.10). The owner gate is unobserved: only a copy another
-- player put on the stack tells it apart, and no card in data/cards copies a
-- triggered ability its caster does not control (gap #4564).
isOrphanedPhenomenonAbility :: ObjectId -> GameState -> Bool
isOrphanedPhenomenonAbility oid gs = maybe False (`List.notElem` Game.stillPlaying gs) (phenomenonOwnerOf oid gs)

-- | CR 311.5 / 312.4 / 901.6: the planar controller, normally the active
-- player. While that seat has left (CR 800.4j keeps it active), CR 800.4p's
-- heir: the next still-playing seat in turn order. Derived, not stored: the
-- designation moves only off a departing holder and reverts at the next turn,
-- so the walk from the active seat always finds it. Parun.PlanechaseSpec's "CR
-- 311.5 a departing active player's plane is replaced from the next seat's
-- planar deck" proves it.
planarController :: GameState -> PlayerId
planarController gs =
  let active = GameState.activePlayer gs
      playing = Game.stillPlaying gs
      order = GameState.turnOrder gs
      after = drop 1 (List.dropWhile (/= active) order) <> order
   in if List.elem active playing then active else Maybe.fromMaybe active (List.find (`List.elem` playing) after)

-- | CR 109.4 for a command-zone object: the planar controller controls a
-- face-up plane or phenomenon card (CR 901.6), and the owner controls
-- everything else there (CR 114.2, CR 902.6).
commandControllerOf :: ObjectId -> Object.Object -> GameState -> PlayerId
commandControllerOf oid obj gs
  | isPlanarCard oid gs = planarController gs
  | otherwise = Object.owner obj

-- | CR 801.18 / 901.13: is this source exempt from the limited range of
-- influence option? A plane or phenomenon card is. Asked by the readers of a
-- static ability's reach: Projection.View's inSourceRangeGiven and
-- controlReaches, CombatRestriction's reachesDeclarer, Replacement's reachOf
-- and PlayerEffect's printedRows. Parun.PlanechaseSpec's "CR 801.18 a face-up Tazeem stops a creature
-- outside the planar controller's range from blocking" proves it.
--
-- Through last-known information, which CR 608.2b reads for a source that has
-- left its zone: an ability of a plane that has since left the command zone is
-- still a planar card's.
-- Parun.PlanechaseSpec's "CR 801.18 Akoum's chaos still reaches outside the
-- range after Akoum leaves the game" proves it.
--
-- Not implemented: CR 901.14's Grand Melee Planechase, where the exemption does
-- not hold (#4465).
exemptFromRange :: ObjectId -> GameState -> Bool
exemptFromRange oid gs = maybe False isPlanarFace (Game.faceOfWithLastKnown oid gs)

-- | CR 801.10 / 801.11 / 801.18: whose range of influence an ability of this
-- source sees and affects through -- its controller's, or nobody's for a
-- source 'exemptFromRange', which Parun.Engine.Players.table reads as the whole
-- table. Asked by trigger detection (Event.Trigger's eventWithinRange), a
-- resolution's player reads (Resolve.Slots' resolutionReads), its
-- battlefield sweep (battlefieldMatching), and targeting's CR 801.4 and CR
-- 801.5a cuts (Target's legalRecipientsGiven and askChooser), a per-player
-- slot's roster (Target's announcedSlots), the graveyards a zone scope names
-- (Target's zoneScopePlayers), and Resolve.Effect's table-wide reads -- its
-- voters among them. Parun.PlanechaseSpec's "CR 801.18 Fields of Summer sees and
-- reaches a caster outside the planar controller's range", "Mutual Epiphany
-- draws four for a player outside", "Astral Arena's chaos damages a creature
-- outside", "Akoum's chaos targets a creature outside", "The Moonbase's chaos
-- takes a card from the graveyard of an opponent outside", "Strixhaven's chaos
-- returns a card from the graveyard of a player outside" and "Prime
-- Minister's Cabinet Room's vote is cast by a player outside" prove them.
rangePerspective :: ObjectId -> PlayerId -> GameState -> Maybe PlayerId
rangePerspective source controller gs = if exemptFromRange source gs then Nothing else Just controller
