module Parun.Types.Phase where

import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.EndingStep as EndingStep

data Phase
  = Beginning BeginningStep.BeginningStep
  | PrecombatMain
  | Combat CombatStep.CombatStep
  | PostcombatMain
  | Ending EndingStep.EndingStep
  deriving (Eq, Ord, Show)
