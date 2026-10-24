module Parun.Types.Timed where

import qualified Parun.Types.Entry as Entry
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.When as When

-- | One entry on a scenario's timeline. Entries sharing a moment are taken in
-- timeline order.
data Timed = MkTimed
  { when :: When.When,
    -- | The object whose prompt this answers, where several prompts share one
    -- moment in an order a scenario cannot predict (CR 510.1's per-attacker
    -- assignments). It selects the entry rather than annotating the head.
    source :: Maybe Reference.Reference,
    entry :: Entry.Entry
  }
  deriving (Eq, Ord, Show)
