module Parun.Types.Gift where

import qualified Parun.Types.Subtype as Subtype

-- | CR 702.174a's [something]: what "Gift a [something]" promises, which CR
-- 702.174b turns into the second ability's effect.
--
-- A type of its own rather than a bare Parun.Types.Effect on the keyword: rule
-- 702.174b writes the effect out in the rulebook from this word alone, so the
-- card prints the word and Parun.Engine.Keyword mints the effect.
--
-- Not implemented: CR 702.174g's extra turn (#3833).
data Gift
  = -- | CR 702.174e: "Gift a card" -- the chosen player draws a card.
    Card
  | -- | CR 702.174d: "Gift a Food" -- the chosen player creates a Food token.
    Food
  | -- | CR 702.174f: "Gift a tapped Fish" -- the chosen player creates a tapped
    -- 1\/1 blue creature token of this type: Fish as printed, or the type a CR
    -- 612.2a text change put in its place.
    TappedFish Subtype.Subtype
  | -- | CR 702.174i: "Gift an Octopus" -- the chosen player creates an 8\/8 blue
    -- creature token of this type: Octopus as printed, or the type a CR 612.2a
    -- text change put in its place.
    Octopus Subtype.Subtype
  | -- | CR 702.174h: "Gift a Treasure" -- the chosen player creates a Treasure
    -- token.
    Treasure
  deriving (Eq, Ord, Show)
