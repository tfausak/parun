module Pawl.Types.Scenario where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Pawl.Types.Check as Check
import qualified Pawl.Types.Start as Start
import qualified Pawl.Types.Timed as Timed

-- | A game in the terms a person would say it: set up this board, make these
-- decisions, check these facts.
data Scenario = MkScenario
  { description :: Text.Text,
    start :: Start.Start,
    timeline :: Seq.Seq Timed.Timed,
    -- | Checked where the run stopped, the one place a finished game can be.
    final :: Seq.Seq Check.Check
  }
  deriving (Eq, Ord, Show)
