module Parun.Types.PriorityWindow where

import qualified Parun.Types.LoopTrail as LoopTrail

-- | CR 117.4: where one priority decision leaves the step's priority window.
data PriorityWindow
  = -- | Still open, with the choices its loop has seen (CR 733.3).
    Open LoopTrail.LoopTrail
  | -- | Closed: the step ends, or the game or the turn's process stopped it.
    Closed
  deriving (Eq, Show)
