module Pawl.Types.DurationEvent where

import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | CR 611.2a: the event a stated "until ..." duration ends at.
data DurationEvent
  = -- | CR 701.27b: the effect's source is turned face down (Vesuvan Shapeshifter).
    SourceTurnedFaceDown
  | -- | CR 601.2i: a player casts a spell this matches (Soul Sculptor).
    SpellCast (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
