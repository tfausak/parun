module Parun.Types.TurnResume where

-- | CR 807.4b / 807.5: where a running Grand Melee turn picks up when the
-- scheduler next works it (Parun.Engine.Engine.runStep). A marker whose
-- holder is waiting to begin (CR 807.4d) has no turn running, which is
-- Parun.Types.TurnMarker's underWay.
data TurnResume
  = -- | CR 500.1: its current step has yet to begin.
    AtStepStart
  | -- | CR 117.3: its step's priority window is open.
    InWindow
  | -- | CR 500.5: its step's priority window has closed, and the step has yet
    -- to end.
    AtStepEnd
  deriving (Bounded, Enum, Eq, Ord, Show)
