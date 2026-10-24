-- Rule 708 in the one voice the rest of the engine cannot supply for itself: CR
-- 116.2b's special action that turns a face-down permanent face up.
--
-- Everything ELSE rule 708 says is arranged so that no module has to know this
-- one exists. CR 708.2's substitution lives at Parun.Engine.Game.faceOf, so every
-- characteristic read gets it for free; CR 708.3/708.4's turning-over-before-the-
-- move lives at Parun.Engine.Event.changeZoneFaceDown; CR 708.9's reveal is
-- Object.newIncarnation putting the status back to FaceUp, and the Revealed
-- event Parun.Engine.Event.changeZoneAttaching and
-- Parun.Engine.Departure.objectsLeaveWith record; the turning-over itself, its
-- CR 708.7 event and its CR 614.1e proposed event, is
-- Parun.Engine.Event.performTurnFaceUp, below this module because a CR 614.1a
-- replacement (Illusionary Mask's) turns a permanent up from inside the CR 616.1
-- loop. What is left is an action a player takes, and an action needs a place
-- to be offered from and performed in.
--
-- FOUR PROCEDURES, because CR 708.7's permission belongs to whatever allowed
-- the permanent to be face down and four rules write one: CR 702.37e's, at the
-- morph cost; CR 702.168d's, at the disguise cost; CR 701.40b's, at the card's
-- mana cost; and CR 701.58b's, at the card's mana cost too. CR 701.40c and CR
-- 701.58d are the cases where two are open at once, and the engine offers both
-- rather than picking.
--
-- A FURTHER ROAD UP that is not a procedure at all: an Effect.TurnFaceUp
-- (Showstopping Surprise), which pays nothing and shows nothing. It shares
-- Event.performTurnFaceUp with the four procedures because CR 701.40g replaces the
-- TURNING OVER and does not care what proposed it.
--
-- THE INVARIANT: rules 701.40, 701.58, 702.37 and 702.168 are part of the
-- rulebook, so reading Keyword.Morph's cost or a FaceDownReason here is the
-- same closed-half act as reading a Phase. This module never asks which CARD is
-- underneath.
module Parun.Engine.FaceDown where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Types.CardType as CardType
import Parun.Types.Cost (Cost)
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import Parun.Types.Game (Game)
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.Keyword (Keyword)
import qualified Parun.Types.ManaAbilityPerformer as ManaAbilityPerformer
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.PaymentSubject as PaymentSubject
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Prompt as Prompt
import Parun.Types.TurnUpProcedure (TurnUpProcedure)
import qualified Parun.Types.TurnUpProcedure as TurnUpProcedure

-- CR 702.37e: "what the permanent's morph cost WOULD BE if it were face up",
-- one entry per distinct morph cost (Keyword.morphCosts). Empty when the
-- permanent would have no morph ability face up, which is the rule's own
-- parenthesis -- "if the permanent wouldn't have a morph cost if it were face
-- up, it can't be turned face up this way". Read off `faceUpKeywords` below.
morphCostsOf :: ObjectId -> GameState -> [Cost Keyword]
morphCostsOf oid gs = Keyword.morphCosts (faceUpKeywords oid gs)

-- CR 702.168d: "show all players what the permanent's disguise cost WOULD BE if
-- it were face up" -- morphCostsOf with rule 702.168d's price list in place of
-- rule 702.37e's, read off the same keywords.
disguiseCostsOf :: ObjectId -> GameState -> [Cost Keyword]
disguiseCostsOf oid gs = Keyword.disguiseCosts (faceUpKeywords oid gs)

-- The keywords rule 702.37e's and rule 702.168d's counterfactual asks about:
-- the permanent's own projection on a board where it is face up. CR 708.8's
-- "any effects that have been applied to the face-down permanent still apply"
-- is why that board, so a grant counts and a removal counts. The MKM and DSK
-- rulings: "If a face-down creature loses its abilities, it can't be turned face
-- up with a disguise or morph ability because it will no longer have that
-- ability (or the associated cost) once face up." Parun.FaceDownSpec's "CR
-- 702.37e / 708.8 a face-down permanent that lost its abilities can't be turned
-- up by morph" proves the removal.
--
-- A projected read of the face-down permanent itself would find none of the
-- card's keywords (CR 708.2), only what the allower listed. Face up, the
-- copiable values are the card's or a copy stamp's (CR 707.2), and a disguise
-- granted at the card's own mana cost (Disguise Agent) is priced at that face-up
-- cost rather than at the face-down permanent's none (CR 708.2a):
-- Parun.CommanderSpec's "CR 702.168a Disguise Agent's disguise casts a commander
-- face down and turns it up for its mana cost".
faceUpKeywords :: ObjectId -> GameState -> Set.Set Keyword
faceUpKeywords oid gs =
  let up = gs {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.FaceUp}) oid (GameState.objects gs)}
   in Map.keysSet (Projection.keywordsOf oid up)

-- CR 701.40b and CR 701.58b, which say it in the same words: "show all players
-- that the card representing that permanent IS A CREATURE CARD and what THAT
-- CARD'S MANA COST is, pay that cost". Their shared parenthesis is the two
-- guards below: "if the card representing that permanent isn't a creature card
-- or it doesn't have a mana cost, it can't be turned face up this way."
--
-- ONE function for the two rules, and the PRICE is the whole of what it answers:
-- which permanents each rule is open to is its subject rather than its cost, and
-- that lives in canTurnFaceUp's `eligible` below.
--
-- Both guards are about "the CARD representing that permanent", so they read
-- Event.representingCardOf and never the permanent, which CR 708.2a has left
-- with no card type and no mana cost at all.
creatureCardCostOf :: ObjectId -> GameState -> Maybe (Cost Keyword)
creatureCardCostOf oid gs = do
  (face, types) <- Event.representingCardOf oid gs
  Monad.guard (Set.member CardType.Creature types)
  manaCost <- Face.manaCost face
  pure (Cost.Type.MkCost (Just manaCost) [])

-- What one of CR 708.7's four procedures may cost on this permanent, empty when
-- that procedure is closed to it. A classification of the four rules, never of
-- a card: which procedure is which is CR 701.40c's own distinction.
costsOf :: TurnUpProcedure -> ObjectId -> GameState -> [Cost Keyword]
costsOf procedure oid gs = case procedure of
  TurnUpProcedure.Morph -> morphCostsOf oid gs
  TurnUpProcedure.Disguise -> disguiseCostsOf oid gs
  TurnUpProcedure.Manifest -> Maybe.maybeToList (creatureCardCostOf oid gs)
  -- CR 701.58b's price list is rule 701.40b's, so the same reader answers both.
  TurnUpProcedure.Cloak -> Maybe.maybeToList (creatureCardCostOf oid gs)

-- CR 116.2b: may this player turn this permanent face up right now, by this
-- procedure? Five conjuncts, each a clause of the rule:
--
--   * it is FACE DOWN (CR 708.2b's mirror -- there is nothing to turn up
--     otherwise);
--   * it is a PERMANENT this player CONTROLS (CR 702.37e's "a face-down
--     permanent you control", CR 701.40b's "a manifested permanent you
--     control"), which is why the battlefield membership and the projected
--     controller are both asked;
--   * the procedure is one this permanent is ELIGIBLE for, which is the only
--     conjunct the two rules disagree on and is `eligible` below;
--   * the procedure's cost exists on the card underneath;
--   * one such cost is payable. An action the player cannot take is not offered,
--     which is Parun.Engine.Action.legalActions' posture for every other action
--     on the menu.
--
-- The payability check is Cost.canPay and NOT Cost.total's CR 601.2f
-- adjustments: that rule totals the cost of a spell being cast or an ability
-- being activated, and a special action is neither -- the same reading
-- Parun.Engine.Activate takes of an activation cost (#90).
--
-- The TIMING clause has no conjunct here because the engine is the timing: CR
-- 702.37e's and CR 701.40b's shared "any time you have priority" is satisfied by
-- legalActions being asked only of the priority holder, exactly as CR 116.2a's
-- land play relies on.
canTurnFaceUp :: PlayerId -> TurnUpProcedure -> ObjectId -> GameState -> Bool
canTurnFaceUp pid procedure oid gs =
  let -- CR 701.40b's subject is "a MANIFESTED permanent", so this procedure is
      -- open only to a permanent CR 701.40a turned over; the reason on the status
      -- is how that is known (CR 708.6). Without this guard a morph-CAST creature
      -- could be turned face up for its mana cost, which CR 702.37c/702.37e
      -- allow nowhere.
      --
      -- CR 702.37e's subject is only "a face-down permanent you control WITH A
      -- MORPH ABILITY", which asks about the card and not about the allower --
      -- so that procedure has no reason guard at all, and a permanent Backslide
      -- turned face down is turnable by it. That asymmetry is the rule's, not a
      -- shortcut.
      eligible = case procedure of
        TurnUpProcedure.Morph -> True
        -- CR 702.168d's subject is "a face-down permanent you control WITH A
        -- DISGUISE ABILITY", rule 702.37e's shape exactly, so this one asks about
        -- the card and not about the allower either. A permanent cloaked or
        -- manifested off a disguise card is turnable this way, which is CR
        -- 701.58d in as many words.
        TurnUpProcedure.Disguise -> True
        TurnUpProcedure.Manifest ->
          fmap (Facing.reasonOf . Object.facing) (Game.lookupObject oid gs)
            == Just (Just FaceDownReason.Manifested)
        -- CR 701.58b's subject is "a CLOAKED permanent you control", the arm
        -- above's shape one rule over: the reason on the status is how that is
        -- known (CR 708.6), and without this guard a manifested permanent would
        -- be turnable by a rule whose subject it is not.
        TurnUpProcedure.Cloak ->
          fmap (Facing.reasonOf . Object.facing) (Game.lookupObject oid gs)
            == Just (Just FaceDownReason.Cloaked)
   in maybe False (Facing.isFaceDown . Object.facing) (Game.lookupObject oid gs)
        && Projection.controllerOf oid gs == Just pid
        && eligible
        && any (payable pid oid gs) (costsOf procedure oid gs)

-- Cost.canPay for the special action, canTurnFaceUp's last conjunct and the
-- filter turnFaceUp offers its choice through. A cost with an X in it is
-- payable when it is payable with X chosen as zero (CR 107.3d).
payable :: PlayerId -> ObjectId -> GameState -> Cost Keyword -> Bool
payable pid oid gs cost = Cost.actionPayableAt (PaymentSubject.TurningFaceUp oid) 0 pid oid cost gs

-- Every way this player may turn a permanent face up right now, in battlefield
-- order -- what Action.TurnFaceUp is built from.
--
-- ONE ENTRY PER PROCEDURE, so a manifested morph card appears twice. That is CR
-- 701.40c (and CR 701.58d for disguise) in the shape Parun.Engine.Room.unlockable
-- takes for CR 709.5e's doors:
-- "its controller MAY turn that card face up using EITHER ... OR", two prices,
-- and offering both as legal actions is how the engine declines to choose
-- (docs/design.md's second invariant).
turnableFaceUp :: PlayerId -> GameState -> [(ObjectId, TurnUpProcedure)]
turnableFaceUp pid gs =
  do
    oid <- Set.toAscList (GameState.battlefield gs)
    procedure <- [TurnUpProcedure.Morph, TurnUpProcedure.Disguise, TurnUpProcedure.Manifest, TurnUpProcedure.Cloak]
    Monad.guard (canTurnFaceUp pid procedure oid gs)
    pure (oid, procedure)

-- CR 702.37e, CR 702.168d, CR 701.40b and CR 701.58b, in the order all four
-- rules share: show all players what the procedure's cost is, pay it, then turn
-- the permanent face up. ONE function for all of them, because everything after the payment is
-- the same game action -- the rules differ only in what they showed and what they
-- charged, which is `costOf` and nothing else.
--
-- The SHOWING is not a reveal and logs nothing: CR 701.20a reveals a card,
-- and these rules show a cost or that the card is a creature card. A paid cost
-- turns the card face up anyway, and a payment that cannot be completed
-- reverses the whole action (CR 733.1), the showing with it.
--
-- REJECT-NOT-REPAIR, the posture Cast.castSpell and Activate.activateAbility
-- both take: a payment that fails restores the state from before it was
-- attempted and the permanent stays face down. The rules' order is what makes
-- that correct rather than merely tidy -- the cost is paid BEFORE the permanent
-- turns over, so a failed payment has turned nothing over to undo.
--
-- The UNPAID branch is quiet, and for a reason of its own: CR 702.37e's
-- reject-not-repair restores the state the attempt began with, log and all, and
-- CR 708.2 leaves the still-face-down permanent with no ability watching a
-- payment anyway -- disguise's listed ward (CR 702.168b) watches CR 702.21a's
-- targeting and nothing else.
--
-- Everything from the status write on is Event.performTurnFaceUp, which the
-- effect road shares.
turnFaceUp :: ManaAbilityPerformer.ManaAbilityPerformer -> PlayerId -> TurnUpProcedure -> ObjectId -> Game ()
turnFaceUp perform pid procedure oid = do
  before <- State.get
  if not (canTurnFaceUp pid procedure oid before)
    then pure ()
    else do
      -- CR 702.37b's "a megamorph cost is a morph cost": a card printing two
      -- morph abilities has two prices for one procedure, and which is paid is
      -- the player's (Prompt.ChooseCost, Activate's posture), since CR 702.37b's
      -- counter hangs on it. Only the payable ones are offered, and a question
      -- with one answer is not asked.
      chosen <- case filter (payable pid oid before) (costsOf procedure oid before) of
        [] -> pure Nothing
        [only] -> pure (Just only)
        offered -> do
          answer <- Game.choose (Prompt.ChooseCost (Decide.deciderFor pid before) pid oid (fmap Cost.untagged offered))
          pure (List.find ((== answer) . Cost.untagged) offered)
      Monad.forM_ chosen $ \cost -> do
        paid <- Cost.payAction perform before (PaymentSubject.TurningFaceUp oid) 0 pid oid cost
        -- The PRINTED cost rides the proposed event, since CR 702.37b's
        -- megamorph row compares it against the card's; the X rides beside it,
        -- and nothing where the cost has no X.
        Monad.forM_ paid $ \announcedX ->
          Event.performTurnFaceUp (Just (procedure, cost)) (if Cost.hasVariable cost then Just announcedX else Nothing) oid
