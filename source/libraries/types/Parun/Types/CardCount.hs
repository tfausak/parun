module Parun.Types.CardCount where

import qualified Numeric.Natural as Natural

-- | How many matching cards a cost takes out of a zone (Parun.Types.DiscardCards).
data CardCount
  = -- | This many, chosen by the payer: Cathartic Reunion's "Discard two cards".
    Exactly Natural.Natural
  | -- | Every matching card, so nothing is chosen and none is needed: Slate of
    -- Ancestry's "Discard your hand" (CR 701.9a).
    Every
  deriving (Eq, Ord, Show)
