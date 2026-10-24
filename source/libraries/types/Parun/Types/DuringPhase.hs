module Parun.Types.DuringPhase where

import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.TurnScope as TurnScope

-- | CR 602.5's timing rider: WHICH phase or step the activation is confined to,
-- and WHOSE turns count. Also a static ability's "during your end step" gate
-- (Parun.Types.Condition's During).

-- There is deliberately no scope-less form: the axis is not a default a card may
-- omit, so a payload naming only a window is a decode failure rather than a
-- silent EachTurn.
data DuringPhase = MkDuringPhase
  { window :: PhaseSelector.PhaseSelector,
    scope :: TurnScope.TurnScope
  }
  deriving (Eq, Ord, Show)
