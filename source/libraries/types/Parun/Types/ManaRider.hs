module Parun.Types.ManaRider where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaRiderEffect as ManaRiderEffect

-- | CR 106.6's second shape: a mana-producing spell or ability that has "an
-- additional effect that affects the spell or ability that mana is spent on".
--
-- A SECOND carrier beside Parun.Types.ManaRestriction rather than a field of it,
-- because rule 106.6 lists the two as alternatives and the printings take them
-- separately: Boseiju, Who Shelters All prints a rider and no restriction,
-- Mishra's Workshop a restriction and no rider, and Delighted Halfling both at
-- once. Folding the rider into the restriction would also make an unconditional
-- rider read as an unconditional restriction, which is the opposite of what a
-- restriction says -- a restriction is a VETO on what the mana may pay for, and
-- a rider narrows nothing.
--
-- The condition is the printed "if that mana is spent on ..." clause, evaluated
-- against the object being paid for, exactly as a restriction's filter is
-- (Parun.Engine.Mana.admitsUnder) -- so Boseiju's is
-- @Or [HasCardType Instant, HasCardType Sorcery]@. It is ONE filter and not
-- Parun.Types.ManaRestriction's two halves, because no printing riding a payment
-- distinguishes the two payment kinds: every one of them says "that spell".
-- Delighted Halfling's clause narrows nothing at all, which is
-- Parun.Types.Filter's trivial @And []@.
--
-- Rides Parun.Types.ManaAddition and is copied onto every unit that instruction
-- adds (Parun.Types.ManaUnit), for CR 106.6a's reason -- "any restrictions or
-- additional effects created by the spell or ability will apply to all mana
-- produced" names both carriers in one sentence.
data ManaRider = MkManaRider
  { -- | Which objects the rider is about. CR 106.6 says an additional effect
    -- "affects the spell or ability that mana is spent on", and this narrows
    -- WHICH such objects the printing means.
    condition :: Filter.Filter Keyword.Keyword,
    -- | What it does to one. A closed classification
    -- (Parun.Types.ManaRiderEffect), never a Parun.Types.Effect.
    effect :: ManaRiderEffect.ManaRiderEffect
  }
  deriving (Eq, Ord, Show)
