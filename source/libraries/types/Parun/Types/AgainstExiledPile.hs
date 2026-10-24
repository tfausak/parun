module Parun.Types.AgainstExiledPile where

import qualified Parun.Types.ExiledPile as ExiledPile

-- | The payload of Parun.Types.Quantity's AgainstExiledPile arm: which of the
-- source's CR 607.2a linked piles to aim at, then what to read off each card in
-- it.
--
-- PARAMETRIC in the quantity for Parun.Types.AgainstSlot's reason: the inner value
-- is a whole Quantity and Quantity names this record.
data AgainstExiledPile quantity = MkAgainstExiledPile
  { pile :: ExiledPile.ExiledPile,
    quantity :: quantity
  }
  deriving (Eq, Ord, Show)
