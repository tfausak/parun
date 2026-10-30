module Parun.Types.Modal where

import qualified Data.Sequence as Seq
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeMemory as ModeMemory
import qualified Parun.Types.ModeSelection as ModeSelection

-- | CR 700.2: a spell's or ability's modal payload. `modes` is a Seq -- ordered
-- (printed order, indexed by ModeIndex) and NON-EMPTY by invariant (a payload has
-- at least one mode; the codec rejects an empty modes array, the UnsafeX/textToX
-- posture -- there is no NonEmpty Seq in base). A non-modal payload is one Mode with
-- ChooseExactly 1.
data Modal card ability = MkModal
  { modes :: Seq.Seq (Mode.Mode card ability),
    selection :: ModeSelection.ModeSelection,
    -- | Which earlier choices bar a mode (Demonic Pact's rulings). Read only
    -- where a triggered ability is put on the stack
    -- (Parun.Engine.Engine.placeBorne).
    --
    -- Not implemented: on an activated ability (#5782), or "this turn" (#5783).
    memory :: ModeMemory.ModeMemory
  }
  deriving (Eq, Ord, Show)
