module Parun.Types.DiscardSubject where

import qualified Parun.Types.PlayerActsOn as PlayerActsOn

-- | CR 603.2: whose discard a discard trigger watches.
data DiscardSubject
  = -- | The bearer is the discarded card ("when you discard this card"),
    -- compared by id. Its discarder is its owner (CR 701.9a), the seat CR 113.8
    -- makes the ability's controller, so no relation is asked.
    Self
  | -- | A player the relation admits discarded a card the Filter admits, judged
    -- with last known information (Megrim, Waste Not, Prickly Marmoset).
    Discarder PlayerActsOn.PlayerActsOn
  deriving (Eq, Ord, Show)
