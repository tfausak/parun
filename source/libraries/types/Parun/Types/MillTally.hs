module Parun.Types.MillTally where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName

-- | What a mill (CR 701.17) records about itself for a LATER effect of the same
-- resolution to read -- CR 728.1's "for each nonland card milled this way, that
-- player loses 1 life and removes one rad counter from themselves".
--
-- Carried by the opcode rather than by the milled cards, for
-- Parun.Types.EntryRiders' reason: "was milled by this effect" is a fact about
-- the effect, not a characteristic of a card (CR 109.3).
--
-- Two fields because the rule asks two things. `slot` is where the number goes,
-- read back as Quantity.InSlot off the effect's source, which is the same
-- binding Parun.Engine.Resolve's Destroy arm writes for Bane of Progress' "for
-- each permanent destroyed this way". `filter` is which of the milled cards
-- count, because no rule in the pool tallies ALL of them: rule 728.1 says
-- "nonland card", and every printed reader of a mill in the Fallout set
-- (The Wise Mothman, Screeching Scorchbeast) says the same words.
--
-- A card that wanted every milled card would spell that as a filter matching
-- everything rather than as a second, filterless shape, so this stays one type.
--
-- `filter` shadows the Prelude's, for the reason Parun.Types.Count's does.
data MillTally = MkMillTally
  { slot :: SlotName.SlotName,
    filter :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
