module Parun.Types.PermissionPool where

import qualified Parun.Types.ExiledPile as ExiledPile

-- | CR 601.3 / 607.2a: which cards of the zone a CR 601.3 permission opens it
-- reaches, before its Filter narrows them.
data PermissionPool
  = -- | Every card in the zone (Yawgmoth's Will, Garruk's Horde).
    EveryCard
  | -- | CR 607.2a: only the cards in one of the permission's source's linked
    -- piles (Dawnhand Dissident's "cards you own exiled with this creature").
    InExiledPile ExiledPile.ExiledPile
  deriving (Eq, Ord, Show)
