module Pawl.Types.WordFamily where

-- | CR 612.2: which kind of word a text-changing effect replaces, since a
-- text-changer changes only words used in the correct way. Named for the words a
-- card's own text names -- Magical Hack says "one basic land type", Artificial
-- Evolution "one creature type", Sleight of Mind "one color word".
-- Pawl.Engine.TextWord classifies a word into one.
data WordFamily
  = -- | CR 305.6's five, a subset of CR 205.3i's land types, which is the family
    -- CR 612.2 gates on.
    BasicLandType
  | -- | CR 205.3m's list, CR 612.2's "creature type word used as a creature
    -- type".
    CreatureType
  | -- | CR 205.3h's list. CR 612.2's word classes are examples, so a text change
    -- may name this family too.
    EnchantmentType
  | -- | CR 105.1's five, CR 612.2's "color word being used as a color word".
    Color
  deriving (Bounded, Enum, Eq, Ord, Show)
