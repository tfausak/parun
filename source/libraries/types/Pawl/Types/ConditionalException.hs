module Pawl.Types.ConditionalException where

import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.CopyException as CopyException
import qualified Pawl.Types.WithCounters as WithCounters

-- | CR 707.9f: part of a copy effect's "except ..." clause that applies only if
-- a condition holds -- Spark Double's "it enters with an additional +1\/+1
-- counter on it if it's a creature", Vizier of Many Faces' "if this creature was
-- embalmed, ...". AsCopy's own `exceptions` and `counters` are the same pair
-- with no condition.
--
-- The condition is judged against the permanent as the copy effect would make
-- it WITHOUT any of its conditional parts (Pawl.Engine.Event.becomeCopyAs), its
-- source being that permanent and Pawl.Engine.Binding.copiedObject naming the
-- object copied (Undercover Operative's "if you control that creature").
data ConditionalException ability = MkConditionalException
  { condition :: Condition.Condition,
    -- | CR 707.9a / 707.9b: AsCopy.exceptions' payload, applied when the
    -- condition holds.
    exceptions :: [CopyException.CopyException ability],
    -- | CR 707.9e: AsCopy.counters' payload, placed when the condition holds.
    counters :: Maybe WithCounters.WithCounters
  }
  deriving (Eq, Ord, Show)
