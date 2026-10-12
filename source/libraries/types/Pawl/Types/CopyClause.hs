module Pawl.Types.CopyClause where

import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.CopyException as CopyException
import qualified Pawl.Types.WithCounters as WithCounters

-- | CR 707.9: one part of a copy effect's "except ..." clause -- the
-- characteristics it modifies and the counters it adds, applied whenever the
-- copy is made, or only if a condition holds (CR 707.9f): Spark Double's "it
-- enters with an additional +1\/+1 counter on it if it's a creature", Vizier of
-- Many Faces' "if this creature was embalmed, ...".
--
-- A condition is judged against the permanent as the copy effect would make it
-- with only the UNCONDITIONAL parts applied (Pawl.Engine.Event.becomeCopyAs), its
-- source being that permanent and Pawl.Engine.Binding.copiedObject naming the
-- object copied (Undercover Operative's "if you control that creature").
data CopyClause ability = MkCopyClause
  { -- | CR 707.9f: Nothing for a part that always applies.
    condition :: Maybe Condition.Condition,
    -- | CR 707.9a / 707.9b: modifications written into the copiable values.
    exceptions :: [CopyException.CopyException ability],
    -- | CR 707.9e: the additional effect of entering with these counters.
    --
    -- Not a CopyException: every arm of that type writes a characteristic into
    -- the copiable snapshot (CR 707.9a, CR 707.9b), and CR 122.1 makes a counter
    -- a marker placed ON an object rather than one of its characteristics. The
    -- same sentence over CR 707.1's token mint is Littjara Mirrorlake's, and it
    -- is CreateCopy's `riders` rather than one of its `exceptions` for this
    -- reason.
    --
    -- Placed through Pawl.Engine.Event's addCopyExceptionCounters, the funnel
    -- the CR 614.1c row uses, so CR 614.16 sees it (Doubling Season), and only
    -- where the copy is actually made. CR 707.9e's second sentence takes them
    -- back when a later copy effect is applied to the same entry: the scenario
    -- "CR 707.9e a copy effect applied after Altered Ego's takes back its
    -- additional counters" proves it.
    counters :: Maybe WithCounters.WithCounters
  }
  deriving (Eq, Ord, Show)
