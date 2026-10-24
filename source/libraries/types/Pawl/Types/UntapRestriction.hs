module Pawl.Types.UntapRestriction where

import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.UntapHold as UntapHold

-- | CR 502.3 / CR 101.2: one printed UNTAP PROHIBITION -- an effect saying a
-- permanent "doesn't untap during its controller's untap step". Tsabo's Web's
-- second sentence is one printing; `untapRestrictions` in data/cards is the rest.
-- Amber Prison's "You may choose not to untap this artifact during your untap
-- step" is the same restriction with the active player's choice holding it
-- (UntapHold.Elective), and Static Orb's "players can't untap more than two
-- permanents" the same restriction with a cap on how many (UntapHold.AtMost).
--
-- Pawl.Types.SacrificeRestriction's shape and its filing, one turn-based action
-- over: CR 613.11 puts a continuous effect that "affects game rules rather than
-- objects" outside the layer system, CR 101.2a says such an effect is not an
-- ability being added or removed, and no layer of Pawl.Engine.Projection rewrites them.
-- Every step of that type's argument for why it cannot be a
-- Pawl.Types.Modification holds here unchanged.
--
-- CR 101.2 is what gives the prohibition its force over CR 502.3's untap: the
-- turn-based action directs the untap and this states it can't happen, so the
-- "can't" wins. Nothing else in the rules asks -- an untap the ACTIVE PLAYER's
-- untap step does not perform (Effect.Untap, CR 701.26b) is a different action,
-- which this sentence does not name and so does not touch.
--
-- A record rather than a sum, for SacrificeRestriction's reason: CR 502.3 is one
-- action, and a restriction names a subject and what holds it back -- an
-- effect's "can't", a cap on how many, or its controller's own choice
-- (Pawl.Types.UntapHold) -- and the "as long as" it applies under (CR 611.3a,
-- Static Orb's "as long as this artifact is untapped").
--
-- Gathered LIVE from the battlefield at the untap step and never captured, the
-- posture every sibling carrier takes: a Tsabo's Web that left lifts its
-- prohibition with nothing to unwind.
--
-- THE STATIC HALF ONLY, and the "next" is what separates the two: this sentence
-- forbids the untap for as long as the printing is on the battlefield, while
-- Elvish Hunter's "doesn't untap during its controller's NEXT untap step" is a
-- one-shot left behind and outliving its source. That one is
-- Object.doesNotUntapFor, written by Effect.DoesNotUntapNext; CR 508.1g's exert
-- payment writes Object.exertedBy beside it, keyed to the exerting player rather
-- than to the victim's controller (CR 701.43a). Both are stored on the victim and
-- spent by Pawl.Engine.Engine.untapAll, which is the one place every carrier is
-- read; the fourth, a resolution's stored row (Pawl.Types.ActiveObjectProhibition),
-- reaches it through Pawl.Engine.UntapRestriction beside this one.
--
-- Open-half card data, classified rather than identified:
-- Pawl.Engine.UntapRestriction is the only module that may read it, and it
-- answers a set of ids.
data UntapRestriction = MkUntapRestriction
  { -- | Which permanents it holds back, or counts under a cap. An Affected, not
    -- a bare ObjectId, so the set is re-derived every untap step -- CR 613.11
    -- lets a rule-modifying continuous effect reach objects that were not
    -- affected when it began, which is what Tsabo's Web's set does as lands
    -- enter and leave.
    affected :: Affected.Affected,
    -- | Whether an effect forbids the untap, caps it, or leaves it to the
    -- active player.
    hold :: UntapHold.UntapHold,
    -- | CR 611.3a: the condition the restriction applies under, read at each
    -- untap step; Nothing where it always does.
    while :: Maybe Condition.Condition
  }
  deriving (Eq, Ord, Show)
