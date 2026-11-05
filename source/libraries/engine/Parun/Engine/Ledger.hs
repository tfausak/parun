-- | The tie between the event log and the writes it reports: the log's new
-- entries, replayed over an earlier state, must give the later state for the
-- fields audited here, and each entry must be a real transition (CR 603.2e,
-- 603.2g). Each happening keeps its own funnel (Parun.Engine.Event's `tap`,
-- `changeLife`, `putCounters`); this checks the funnels after the fact, so a write that skips
-- its record, or a record of a change that did not happen, shows by name.
--
-- Run between priority prompts (Parun.Scenario), never inside a funnel, which
-- may hold a write ahead of its record while a replacement prompt is open
-- (Parun.Engine.Damage's life pass, CR 120.4c).
module Parun.Engine.Ledger where

import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.CounterChange as CounterChange
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.Discrepancy as Discrepancy
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Player as Player
import qualified Parun.Types.TapState as TapState

-- | Where the log between two states fails to account for the later one. Empty
-- when the two are not one game carried forward (`logBetween`).
discrepancies :: GameState.GameState -> GameState.GameState -> [Discrepancy.Discrepancy]
discrepancies before after = case logBetween before after of
  Nothing -> []
  Just logged -> tapping before after logged <> life before after logged <> counting before after logged

-- | The entries logged between two states: the later log past the earlier one,
-- across at most one turn handoff (Parun.Engine.Engine.handoffTurn moves the
-- log to GameState.eventsLastTurn). Nothing where the earlier log is not a
-- prefix -- a reversal cut it (CR 733.1), or Parun.Engine.Cost rewrote it --
-- or the two are different games (CR 727.1, 729.1a) or turns further apart.
logBetween :: GameState.GameState -> GameState.GameState -> Maybe (Seq.Seq LoggedEvent.LoggedEvent)
logBetween before after
  | GameState.gameNumber before /= GameState.gameNumber after = Nothing
  | GameState.turnNumber after == GameState.turnNumber before = past (GameState.events after)
  | GameState.turnNumber after == GameState.turnNumber before + 1 = fmap (<> GameState.events after) (past (GameState.eventsLastTurn after))
  | otherwise = Nothing
  where
    earlier = GameState.events before
    past whole =
      if Seq.take (Seq.length earlier) whole == earlier
        then Just (Seq.drop (Seq.length earlier) whole)
        else Nothing

-- | CR 701.26a, 701.26b: tapped status, over the objects in both states. An
-- object in only one is a new object (CR 400.7), which may enter in either
-- status unlogged (CR 603.2e).
tapping :: GameState.GameState -> GameState.GameState -> Seq.Seq LoggedEvent.LoggedEvent -> [Discrepancy.Discrepancy]
tapping before after logged =
  let turn (held, idle) entry =
        let event = LoggedEvent.event entry
            to status oid = case Map.lookup oid held of
              Just from
                | from == status -> (held, idle Seq.|> Discrepancy.MkIdleEvent event)
                | otherwise -> (Map.insert oid status held, idle)
              Nothing -> (held, idle)
         in case event of
              GameEvent.BecameTapped oid -> to TapState.Tapped oid
              GameEvent.BecameUntapped oid -> to TapState.Untapped oid
              _ -> (held, idle)
      (replayed, idles) = Foldable.foldl' turn (statuses before, Seq.empty) logged
      differing = Map.intersectionWith (,) replayed (statuses after)
   in Foldable.toList idles <> [Discrepancy.MkTapState oid expected actual | (oid, (expected, actual)) <- Map.toList differing, expected /= actual]

statuses :: GameState.GameState -> Map.Map ObjectId.ObjectId TapState.TapState
statuses = fmap Object.tapped . GameState.objects

-- | CR 119.3: life totals. A change happens to one player and its result to
-- every player sharing that total (CR 810.9, Game.lifeSharers).
life :: GameState.GameState -> GameState.GameState -> Seq.Seq LoggedEvent.LoggedEvent -> [Discrepancy.Discrepancy]
life before after logged =
  let change (totals, idle) entry =
        let event = LoggedEvent.event entry
            by sign moved
              | LifeChange.amount moved == 0 = (totals, idle Seq.|> Discrepancy.MkIdleEvent event)
              | otherwise =
                  let delta = sign (toInteger (LifeChange.amount moved))
                   in (Foldable.foldl' (flip (Map.adjust (+ delta))) totals (Game.lifeSharers (LifeChange.player moved) after), idle)
         in case event of
              GameEvent.LifeGained moved -> by id moved
              GameEvent.LifeLost moved -> by negate moved
              _ -> (totals, idle)
      totalsOf = fmap Player.life . GameState.players
      (replayed, idles) = Foldable.foldl' change (totalsOf before, Seq.empty) logged
      differing = Map.intersectionWith (,) replayed (totalsOf after)
   in Foldable.toList idles <> [Discrepancy.MkLife pid expected actual | (pid, (expected, actual)) <- Map.toList differing, expected /= actual]

-- | CR 122.1, 122.6: each object's count of each counter kind, over the objects
-- in both states, an absent kind reading as 0 (Parun.Engine.Damage stores the 0
-- a planeswalker's last loyalty leaves). Each event's count before must be the
-- count the log has reached, so a write between two events shows at the next,
-- and its count after must differ in the event's direction. An object in only
-- one state is a new object (CR 400.7), whose counters ceased to exist or
-- arrived with it (CR 122.2).
counting :: GameState.GameState -> GameState.GameState -> Seq.Seq LoggedEvent.LoggedEvent -> [Discrepancy.Discrepancy]
counting before after logged =
  let step (held, found) entry =
        let event = LoggedEvent.event entry
            moved oid kind from to rising
              | not (Map.member oid (GameState.objects before)) = (held, found)
              | otherwise =
                  let reached = Map.findWithDefault 0 (oid, kind) held
                      broken = [Discrepancy.MkCounters oid kind reached from | reached /= from]
                      idle = [Discrepancy.MkIdleEvent event | if rising then to <= from else to >= from]
                   in (Map.insert (oid, kind) to held, found <> Seq.fromList (broken <> idle))
         in case event of
              GameEvent.CountersPut placed -> moved (CountersPlaced.object placed) (CountersPlaced.kind placed) (CountersPlaced.before placed) (CountersPlaced.after placed) True
              GameEvent.CountersRemoved change -> moved (CounterChange.object change) (CounterChange.kind change) (CounterChange.before change) (CounterChange.after change) False
              _ -> (held, found)
      (replayed, breaks) = Foldable.foldl' step (countsOf before, Seq.empty) logged
      actual = countsOf after
      shared = Map.keysSet (Map.intersection (GameState.objects before) (GameState.objects after))
      keys = Set.filter ((`Set.member` shared) . fst) (Map.keysSet replayed <> Map.keysSet actual)
      pairs = [(key, Map.findWithDefault 0 key replayed, Map.findWithDefault 0 key actual) | key <- Set.toList keys]
   in Foldable.toList breaks
        <> [Discrepancy.MkCounters oid kind expected found | ((oid, kind), expected, found) <- pairs, expected /= found]

countsOf :: GameState.GameState -> Map.Map (ObjectId.ObjectId, CounterKind.CounterKind Keyword.Keyword) Natural.Natural
countsOf gs = Map.fromList [((oid, kind), n) | (oid, obj) <- Map.toList (GameState.objects gs), (kind, n) <- Map.toList (Object.counters obj)]
