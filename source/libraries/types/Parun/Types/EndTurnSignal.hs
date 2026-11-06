module Parun.Types.EndTurnSignal where

-- | CR 725.1 / CR 725.2: whether an effect has ended the turn, or the combat
-- phase, underneath the control flow that is still running the step it ended.
--
-- Either one resolves from the stack, so it happens several frames deep --
-- inside a resolution, inside Engine.priorityLoop, inside Engine.runStep -- and
-- CR 725.1d or CR 725.2d has already ended the step those frames are running.
-- CR 725.1f and CR 725.2f are what make the signal load-bearing rather than a
-- schedule rewrite: no player gets priority during the process, and the
-- abilities that triggered during it go onto the stack later, so priorityLoop
-- may neither settle nor grant another round once this is raised.
--
-- ONE signal for both rules rather than two, because the two ask exactly this of
-- priorityLoop and differ only in where the schedule resumes: 725.1f's "during
-- the cleanup step" and 725.2f's "during the following phase" are both just the
-- head of `remaining` that 725.1d or 725.2d left.
--
-- Raised by Resolve's Effect.EndTurn and Effect.EndCombatPhase arms; lowered by
-- Engine.runStep as the step at that head begins. Not a Bool, for
-- Parun.Types.RestartSignal's reason: the two states are an outcome -- "this step
-- is running" and "an effect ended the turn or the combat phase" -- rather than
-- a predicate.
--
-- Scoped per GameState like RestartSignal, so a CR 730.1 subgame runs in its own
-- StateT frame with its own signal.
data EndTurnSignal
  = Running
  | Ended
  deriving (Bounded, Enum, Eq, Ord, Show)
