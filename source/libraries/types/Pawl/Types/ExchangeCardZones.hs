module Pawl.Types.ExchangeCardZones where

import qualified Pawl.Types.ObjectRef as ObjectRef

-- | CR 701.12d: the one card each ref names exchange zones -- Darkpact's
-- "Exchange that card with the top card of your library", rule 702.65a's
-- "exchange this permanent with an Aura card in your hand".
data ExchangeCardZones = MkExchangeCardZones
  { -- | One side; a ref naming no card or several exchanges nothing.
    one :: ObjectRef.ObjectRef,
    -- | The other side, asked only once `one` has named its card.
    other :: ObjectRef.ObjectRef
  }
  deriving (Eq, Ord, Show)
