module Parun.Types.CounterCause where

import qualified Parun.Types.PlayerId as PlayerId

-- | CR 614.1 / 614.16: how a counter placement came about, at the two grains a
-- replacement effect can narrow by -- WHO is putting the counters, and whether an
-- EFFECT is what put them.
--
-- Both matter because printed clauses split on them. CR 614.16's -- "if an effect
-- would put one or more counters on a permanent" -- "apply if the effect of a
-- resolving spell or ability puts a counter on a permanent, and they also apply if
-- another replacement or prevention effect does so", and nothing else; CR 609.1
-- makes a turn-based action neither, which is why Doubling Season does not double
-- the lore counter CR 714.3c hands a Saga. Vorinclex, Monstrous Raider's clauses
-- name a PLAYER instead -- "if you would put", "if an opponent would put" -- and
-- rule 714.3c has a player put that lore counter, so they do reach it.
--
-- Carried into Parun.Engine.Event.putCounters rather than derived there, because
-- nothing about a proposed placement says where it came from -- the object, the
-- kind and the count are identical either way. Every constructor names the putter:
-- CR 122.6a states who that is for the as-it-enters case ("if the effect doesn't
-- specify a player, the object's controller puts those counters on it"), CR 608.2c
-- settles the rest as the resolution's controller, and CR 714.3c names one
-- outright. An effect's controller and the receiving permanent's controller are
-- different players whenever one player puts a counter on another's permanent, so
-- only the caller knows which is which.
--
-- Read by Parun.Engine.Replacement.matchesPutter; Parun.Engine.Event.putCounters
-- records its `putter` on GameEvent.CountersPut.
data CounterCause
  = -- | A resolving spell or ability's effect (CR 609.1), or another replacement
    -- or prevention effect -- CR 614.16's two admitted causes, which it treats
    -- alike. Parun.Engine.Resolve's PutCounters and proliferate arms are the first
    -- kind; CR 714.3a's Saga entry and CR 702.136a's riot are the second.
    ByEffect PlayerId.PlayerId
  | -- | A player paying a cost (CR 601.2h, CR 508.1j \/ 509.1f, CR 118.12):
    -- no effect, so CR 614.16's rows do not reach it, but a clause naming a
    -- player does (docs/decisions.md, "Whether a cost paid on resolution is an
    -- effect").
    ByPayment PlayerId.PlayerId
  | -- | A rule, acting on its own -- CR 714.3c's turn-based action is the only one
    -- today, and its player is that rule's "that player". Not an effect, so CR
    -- 614.16's rows do not reach it; still a player putting counters, so a clause
    -- naming a player does.
    ByRule PlayerId.PlayerId
  deriving (Eq, Ord, Show)

-- | The player putting the counters, which every constructor names (see above).
--
-- The type's own projection and not cross-type logic: it is what lets a caller
-- carrying a cause -- Parun.Engine.Blight.blight -- take the one argument rather
-- than a cause and a redundant player that could disagree with it.
putter :: CounterCause -> PlayerId.PlayerId
putter cause = case cause of
  ByEffect pid -> pid
  ByPayment pid -> pid
  ByRule pid -> pid
