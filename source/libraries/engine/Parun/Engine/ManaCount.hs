-- CR 106.4: the one place a Parun.Types.ManaCount is interpreted. A pure fold --
-- resolve whose pool, keep by the ManaFilter, count the survivors -- that never
-- learns which effect or card produced it, exactly as Parun.Engine.Count's fold
-- over objects does not.
--
-- Takes a ViewOf but no QuantityOf, where Parun.Engine.Count takes both: a mana
-- unit has no characteristics for a projection to supply and a ManaCount holds
-- no inner Quantity, so the view is here only to resolve the PlayerRef -- CR
-- 613.1b's layer-2 controller, which Count.playersFor reads off it.
-- Parun.Engine.Quantity calls this directly.
module Parun.Engine.ManaCount where

import qualified Parun.Engine.Count as Count
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.ManaFilter as ManaFilter
import Parun.Types.GameState (GameState)
import qualified Parun.Types.Mana as Mana
import qualified Parun.Types.ManaCount as ManaCount

-- Nothing when the count cannot be determined -- an unresolvable PlayerRef,
-- which is the only way this fold can fail. It propagates, the posture
-- Parun.Engine.Count.evaluate takes for the same reason.
--
-- Read STRAIGHT OFF GameState.manaPool at the moment of the call, never off a
-- stored or sampled copy: CR 605.3a lets a player activate a mana ability
-- whenever they have priority and CR 605.3b has it resolve immediately without
-- the stack, so the pool moves with no state-based action (CR 704.3) and no
-- priority pass in between.
evaluate :: Count.ViewOf -> Filter.Context -> GameState -> ManaCount.ManaCount -> Maybe Integer
evaluate viewOf context gs count = do
  -- CR 106.4 attaches a pool to a player, so the same PlayerRef reading a
  -- Scope.InZone uses answers WHOSE pool -- one resolution of the reference for
  -- both, which is what keeps the two from disagreeing.
  pids <- Count.playersFor viewOf context gs (ManaCount.player count)
  let units = concatMap (\pid -> Mana.unwrap (Game.poolOf pid gs)) pids
  -- CR 106.4's pool is a multiset of UNITS (Parun.Types.Mana), so counting the
  -- survivors is counting mana: one unit is one mana, whatever its type.
  pure (toInteger (length (filter (ManaFilter.matches (ManaCount.filter count)) units)))
