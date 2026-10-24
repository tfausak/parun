module Parun.Types.SelfCountersRemoved where

import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword

-- | A counter removal from the ability's own object: which counter kind. Where
-- the ability functions is its own (Parun.Types.TriggeredAbility.functionsFrom).
newtype SelfCountersRemoved = MkSelfCountersRemoved
  { kind :: CounterKind.CounterKind Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
