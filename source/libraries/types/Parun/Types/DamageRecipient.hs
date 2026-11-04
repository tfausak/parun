module Parun.Types.DamageRecipient where

import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 120.1: one recipient a damage trigger admits.
data DamageRecipient
  = -- | A player the relation admits, read against CR 109.5's "you".
    Player PlayerRelation.PlayerRelation
  | -- | A permanent of the card type (CR 120.1a), its recipient tag unioned
    -- with its types (Parun.Engine.Projection.damagedCardTypes). A card type
    -- rather than a Filter: no printing qualifies it further, and a Filter would
    -- owe CR 608.2h last known information for a recipient the damage killed.
    Permanent CardType.CardType
  deriving (Eq, Ord, Show)
