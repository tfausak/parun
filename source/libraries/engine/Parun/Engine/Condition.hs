-- CR 603.8 / 603.4 / 611.2b / 604.2: is this Condition currently true? The only
-- module that may evaluate a Parun.Types.Condition -- the standing
-- Parun.Engine.Expiry has over Parun.Types.Expiry and Parun.Engine.Projection over
-- Modification.
--
-- Total, so it must collapse the Maybe its two inputs carry: an undeterminable
-- quantity on EITHER side makes the condition FALSE. That is the conservative
-- reading of CR 611.2b -- a "for as long as" whose condition cannot be
-- evaluated ends rather than persists. CR 208.2a's substituted 0 is a different
-- rule scoped to a characteristic-defining ability, which a condition is not.
-- docs/decisions.md, "Whether a condition that cannot be evaluated holds".
--
-- The VIEW is the caller's, and picking it is a rules decision rather than a
-- detail. Three answers, one per kind of question:
--
--   * CR 603.4's intervening "if" asks about objects that may no longer exist --
--     the source of a leaves-the-battlefield ability, or the entrant rule
--     702.100a's clause is about -- so Event.interveningHolds and both arms of
--     Parun.Engine.Stack's CR 608.2a re-check (the object-borne one and the
--     inherent one) pass Projection.viewWithLastKnownAnywhere, which owes CR
--     608.2h to every id it is aimed at rather than to one. Nothing here can
--     compensate for the wrong view -- an object read as an empty one simply
--     answers False.
--   * CR 604.7 settles a static ability's "as long as" clause the other way: it
--     "can't use an object's last known information", so
--     Projection.conditionHolds passes a live Projection.viewUpTo -- bounded
--     rather than full, which is a layer question rather than a last-known one.
--   * CR 702.178a's max speed gate is the same static-ability genre and gets a
--     different answer again: Projection.abilitiesGiven asks it OVER the finished
--     projection rather than inside the fold, so there is no layer to bound
--     against and it passes Projection.fullView.
module Parun.Engine.Condition where

import qualified Data.Map.Strict as Map
import Data.Set (Set)
import Numeric.Natural (Natural)
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Count as Count
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Condition as Condition.Type
import qualified Parun.Types.DuringPhase as DuringPhase
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)
import Parun.Types.Recipient (Recipient)
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TurnScope as TurnScope

holds :: Count.ViewOf -> Filter.Context -> GameState -> ObjectId -> Condition.Type.Condition -> Bool
holds viewOf context gs oid condition =
  let evaluate = Quantity.evaluate viewOf context gs oid
   in case condition of
        -- Both sides are evaluated against `oid` and with the same view, so a
        -- Quantity.Measure on either side reads the same object and a Quantity.Count on
        -- either side sweeps the same board. Only the Comparison is oriented.
        Condition.Type.Compares c ->
          case (evaluate (Compares.measured c), evaluate (Compares.threshold c)) of
            (Just n, Just t) -> Filter.compares (Compares.comparison c) n t
            _ -> False
        -- Each disjunct collapses its own unanswerable quantities to False, so an
        -- empty list is False and a disjunct reading a slot nothing filled cannot
        -- poison the ones beside it.
        Condition.Type.Any conditions -> any (holds viewOf context gs oid) conditions
        -- Each conjunct collapses its own unanswerable quantities to False, so a
        -- conjunct nothing could evaluate makes the whole conjunction False rather
        -- than leaving it undetermined -- the same conservative reading the header
        -- gives one comparison. An empty list is True, the fold's unit.
        Condition.Type.All conditions -> all (holds viewOf context gs oid) conditions
        -- CR 500.1's window by containment, and CR 109.5's "your" as the
        -- context's perspective: the reader's two conjuncts
        -- (Parun.Engine.ActivationRestriction's DuringPhase arm). With no
        -- perspective only a scope naming no player can hold.
        Condition.Type.During (DuringPhase.MkDuringPhase window scope) ->
          Turn.inWindow window (GameState.phase gs)
            && maybe (scope == TurnScope.EachTurn) (Turn.turnScopeAdmits (Count.scopePlayers viewOf context gs) gs scope (GameState.activePlayer gs)) (Filter.perspective context)

-- CR 107.3m: the amounts a triggered ability's condition may read off the spell
-- that became its source. Seeded into Filter.Context's boundAmounts by CR 603.4's
-- gather-time check (Parun.Engine.Event.Trigger.interveningHolds) and CR 608.2a's
-- re-check (Parun.Engine.Stack.interveningStillHolds) alike, which is what keeps
-- the two from disagreeing.
--
-- CASED ON THE TRIGGER'S CONDITION, rule 107.3m's own boundary and the one
-- Parun.Engine.Engine.placeBorne already draws for CR 601.2c's target count: an
-- enters-the-battlefield ability reads the spell's X, "although the value of X for
-- that permanent is 0", so every other ability of the same permanent keeps reading
-- nothing.
--
-- The CHANNEL is boundAmounts rather than the object, for the reason
-- Parun.Engine.Quantity's InSlot arm gives: CR 400.7 mints the permanent with no
-- bindings, so the announcement is off-object here. Object.announcedX is where it
-- landed instead (Parun.Engine.Event.changeZoneAttaching).
--
-- ZERO and not an absent key where the permanent carries none -- a token copy, or
-- one an effect put onto the battlefield -- which is rule 107.3m's own number and
-- Game.announcedXOf's answer for the replacement half of the same keyword.
-- An absent key would leave the comparison unanswerable, which Condition.holds
-- reads as False; that agrees for "5 or more" and would not for a clause naming a
-- smaller threshold.
--
-- Parun.EntryReplacementSpec's Ravenous group is what proves it: CR 702.156a's "if X
-- is 5 or more" is the one condition in the pool that reads this.
inheritedX :: TriggerCondition.TriggerCondition -> ObjectId -> GameState -> Map.Map SlotName Natural
inheritedX condition oid gs = case condition of
  TriggerCondition.SelfEnters ->
    Map.singleton Binding.variableX (Game.announcedXOf oid gs)
  _ -> Map.empty

-- CR 611.2b: the condition with every slot-reading PlayerRef inside it baked to
-- the seat or object the resolution's chosen recipients name (Quantity.bakeBound,
-- which carries the argument). Applied where a stored condition outlives its
-- resolution -- Parun.Engine.Expiry.arm as a "for as long as" duration begins, and
-- a granted play permission's condition -- and nowhere else: a condition a STATIC
-- ability states (CR 604.2) is re-derived every projection with no resolution
-- behind it, and an intervening "if" (CR 603.4) is read while the bindings are
-- still reachable.
bakeBound :: Map.Map SlotName (Set Recipient) -> Condition.Type.Condition -> Condition.Type.Condition
bakeBound targets condition = case condition of
  Condition.Type.Compares c ->
    let players = Binding.playersIn targets
        objects = Binding.objectsIn targets
     in Condition.Type.Compares
          c
            { Compares.measured = Quantity.bakeBound players objects (Compares.measured c),
              Compares.threshold = Quantity.bakeBound players objects (Compares.threshold c)
            }
  Condition.Type.Any conditions -> Condition.Type.Any (fmap (bakeBound targets) conditions)
  Condition.Type.All conditions -> Condition.Type.All (fmap (bakeBound targets) conditions)
  Condition.Type.During _ -> condition

-- The condition read for ONE affected player: every PlayerRef.Candidate inside
-- it substituted by that seat (Quantity.forCandidate). Angelic Arbiter's "each
-- opponent who cast a spell this turn" is a player static ability's condition
-- asked once per player it would affect (Parun.Engine.PlayerEffect.printedRows).
forCandidate :: PlayerId -> Condition.Type.Condition -> Condition.Type.Condition
forCandidate pid condition = case condition of
  Condition.Type.Compares c ->
    Condition.Type.Compares
      c
        { Compares.measured = Quantity.forCandidate pid (Compares.measured c),
          Compares.threshold = Quantity.forCandidate pid (Compares.threshold c)
        }
  Condition.Type.Any conditions -> Condition.Type.Any (fmap (forCandidate pid) conditions)
  Condition.Type.All conditions -> Condition.Type.All (fmap (forCandidate pid) conditions)
  Condition.Type.During _ -> condition
