module Pawl.Types.ExiledWith where

-- | Which of the cards exiled with a source (CR 607.2a / 614.14) a
-- Pawl.Types.Filter.IsExiledWithSource candidate must be.
data ExiledWith
  = -- | The last one -- Ice Cauldron's "the last card exiled with this
    -- artifact", baked onto a mana unit at production.
    LastExiled
  | -- | Any of them -- Mimeoplasm, Revered One's "target creature card exiled
    -- with it".
    AnyExiled
  deriving (Bounded, Enum, Eq, Ord, Show)
