module Pawl.Types.SelfCountersRemoved where

import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Keyword as Keyword

-- | A counter removal from the ability's own object: which counter kind. Where
-- the ability functions is its own (Pawl.Types.TriggeredAbility.functionsFrom).
newtype SelfCountersRemoved = MkSelfCountersRemoved
  { kind :: CounterKind.CounterKind Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
