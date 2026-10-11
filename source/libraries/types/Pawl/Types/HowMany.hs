module Pawl.Types.HowMany where

import qualified Pawl.Types.Quantity as Quantity

-- | CR 608.2d: how many of its candidates a resolution-time choice names.
data HowMany
  = -- | CR 608.2d: exactly that many distinct picks, fewer only where fewer
    -- match (CR 609.3) -- Hanweir Battlements' "a creature named Hanweir
    -- Garrison", Ancestral Memories' "two of them".
    Exactly Quantity.Quantity
  | -- | CR 608.2d: any number up to the ceiling, the empty answer legal; no
    -- ceiling is "any number" (Tovolar, Dire Overlord, Lead the Stampede), a
    -- ceiling "up to two" (Teferi, Hero of Dominaria, Uncovered Clues).
    UpTo (Maybe Quantity.Quantity)
  deriving (Eq, Ord, Show)

-- | The printed singular, every choice's default on the wire.
one :: HowMany
one = Exactly (Quantity.Literal 1)

-- | The Quantity this count reads, where it reads one: SlotCount's `quantity`
-- for the same walks.
quantity :: HowMany -> Maybe Quantity.Quantity
quantity c = case c of
  Exactly q -> Just q
  UpTo q -> q
