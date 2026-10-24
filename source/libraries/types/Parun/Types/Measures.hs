module Parun.Types.Measures where

import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Operand as Operand

-- | The payload of Parun.Types.Filter's Measures atom: the candidate's measure
-- relates thus to the operand.
data Measures = MkMeasures
  { measure :: Measure.Measure,
    comparison :: Comparison.Comparison,
    operand :: Operand.Operand
  }
  deriving (Eq, Ord, Show)
