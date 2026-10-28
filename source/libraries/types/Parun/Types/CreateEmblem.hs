module Parun.Types.CreateEmblem where

import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 114.2's "[Player] gets an emblem with [ability]": WHO gets it, and the
-- card its abilities ride on.
--
-- Parametric in @card@ for 'Parun.Types.Effect.Effect'\'s reason: the emblem's
-- card is card DATA nested inside card data.
data CreateEmblem card = MkCreateEmblem
  { card :: card,
    -- | CR 114.2's [player], the emblem's owner and controller. CR 109.5's
    -- "you" is the default and elided; Garruk, Apex Predator's "target
    -- opponent" is a 'PlayerRef.InSlot'. 'Parun.Types.Create.creator''s
    -- shape: a reference naming several players gives each one an emblem, in
    -- APNAP order, and one naming nobody gives none.
    player :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
