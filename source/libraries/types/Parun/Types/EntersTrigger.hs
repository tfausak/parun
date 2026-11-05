module Parun.Types.EntersTrigger where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 603.6a: a permanent entering the battlefield -- which one, and per
-- permanent or per batch (CR 603.2c).
data EntersTrigger = MkEntersTrigger
  { permanent :: ActingPermanent.ActingPermanent,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)

-- | "When this enters": the source, once per entry. The codec's defaults.
defaultValue :: EntersTrigger
defaultValue =
  MkEntersTrigger
    { permanent = ActingPermanent.Self,
      batching = Batching.EachOccurrence
    }

-- | "Whenever a [type] enters": a permanent the Filter admits, once per entry.
matching :: Filter.Filter Keyword.Keyword -> EntersTrigger
matching f = defaultValue {permanent = ActingPermanent.Matching f}
