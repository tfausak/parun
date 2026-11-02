module Parun.Types.DealsDamageToPermanent where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DamageKind as DamageKind

-- | CR 603.2 / 120.3: which permanent's or spell's damage fires the ability,
-- and the card type of the permanent it has to have been dealt to -- Phage the
-- Untouchable's "deals combat damage to a creature", Hooded Blightfang's
-- "a creature you control with deathtouch deals damage to a planeswalker".
--
-- A card type rather than a Filter: the printed forms qualify the recipient no
-- further, and a Filter would owe CR 608.2h last known information for a
-- recipient the damage has already killed.
data DealsDamageToPermanent = MkDealsDamageToPermanent
  { actor :: ActingPermanent.ActingPermanent,
    recipient :: CardType.CardType,
    -- | Nothing for damage of any kind.
    kind :: Maybe DamageKind.DamageKind
  }
  deriving (Eq, Ord, Show)
