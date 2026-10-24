module Parun.Types.ExchangeValues where

import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ExchangedValue as ExchangedValue

-- | The payload of Parun.Types.Effect's ExchangeValues arm: the two numerical
-- values CR 701.12g exchanges, each becoming the other's previous value, and
-- how long a power or toughness side's setting effect lasts (CR 611.2a).
data ExchangeValues = MkExchangeValues
  { one :: ExchangedValue.ExchangedValue,
    other :: ExchangedValue.ExchangedValue,
    duration :: Duration.Duration
  }
  deriving (Eq, Ord, Show)
