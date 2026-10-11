module Pawl.Types.ExiledWith where

-- | Which of the cards exiled with a source a
-- Pawl.Types.Filter.IsExiledWithSource candidate must be.
data ExiledWith
  = -- | CR 607.2a: the last one -- Ice Cauldron's "the last card exiled with
    -- this artifact", baked onto a mana unit at production.
    LastExiled
  | -- | CR 607.2b / 614.14: any card the source's as-enters exile took --
    -- Mimeoplasm, Revered One's "target creature card exiled with it".
    ExiledAsItEntered
  deriving (Bounded, Enum, Eq, Ord, Show)
