module Parun.Types.StepOfControllerOf where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Phase as Phase

-- | CR 611.2a: Parun.Types.StepBegan with the seat left open: the object whose
-- controller it names when the step begins.
data StepOfControllerOf = MkStepOfControllerOf
  { phase :: Phase.Phase,
    object :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
