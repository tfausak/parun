module Parun.Types.Repeat where

import qualified Data.Sequence as Seq
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 608.2d's "may repeat this process": the body, then a player's choice
-- whether to run it again -- Kindle the Carnage's "you", Trade Secrets' "that
-- opponent".
--
-- Parametric in the effect for Parun.Types.ForEach's reason.
data Repeat effect = MkRepeat
  { -- | Who is asked after each run.
    chooser :: PlayerRef.PlayerRef,
    -- | The process, run in written order (CR 608.2c) before each ask.
    body :: Seq.Seq effect,
    -- | CR 706.3c: what must hold, after a run, for the chooser to be asked --
    -- Delina, Wild Mage's "15--20 | ... You may roll again". Absent asks every
    -- time.
    gate :: Maybe Condition.Condition,
    -- | Who is asked instead when the gate fails -- Game of Chaos's "that
    -- player decides". Absent ends the loop unasked. Read only beside a gate;
    -- Parun.EffectLintSpec rejects one without.
    otherChooser :: Maybe PlayerRef.PlayerRef,
    -- | What going again does before the next run, in written order -- Game of
    -- Chaos's "double the life stakes". A slot only this binds survives the
    -- per-run rescope.
    ifAgain :: Seq.Seq effect
  }
  deriving (Eq, Ord, Show)
