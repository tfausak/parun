module Parun.Types.RandomCard where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HiddenZone as HiddenZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity

-- | CR 701.20a over CR 402.3, and Alchemy's seek over CR 401.2, with no choice
-- in either: which hidden zone randomness reaches, whose, what it may name
-- there, and how many cards it names.

-- ONE PlayerRef, Parun.Types.ChosenCardInHand's reason -- CR 402.3 and CR 401.2
-- hide the zone from everyone but (for a hand) its owner, so the zone's owner
-- and the seat carrying the instruction out collapse onto one player -- with
-- randomness standing where that type's chooser stands (CR 701.9b). The ZONE is
-- the whole difference between Merfolk Spy's "a card at random from their hand"
-- and Gate to Seatower's seek; Parun.Types.RandomCardInGraveyard stays its own
-- type because CR 400.2 makes that zone public, so its seats come from a
-- ZoneScope rather than one PlayerRef.
--
-- The FILTER narrows the candidates handed to Prompt.RandomObject rather than
-- adding a roll, so it changes what is asked and not who answers: Gate to
-- Seatower's "seek a nonland card" is one pick among the nonland cards, not a
-- pick that may miss.
--
-- The COUNT is a Quantity for Parun.Types.TopOfLibrary's reason, and it is
-- a count of DISTINCT cards per seat: the printed "two cards at random" (Fall)
-- names two cards rather than making two picks that may coincide, so
-- Parun.Engine.Resolve.Common.randomCards drops each card it names from the
-- candidates before asking again. CR 609.3 covers the shortfall -- a zone
-- holding fewer matches than the count gives what it has, and an empty one
-- nothing.
--
-- Seek is digital-only, so Arena's text rather than the CR is its authority, and
-- that text states what separates it from CR 701.23's search: nobody looks at
-- the library, nothing is revealed and nothing is shuffled.
--
-- The fields are named rather than positional for ChosenCardInHand's reason.
data RandomCard = MkRandomCard
  { zone :: HiddenZone.HiddenZone,
    player :: PlayerRef.PlayerRef,
    filter :: Filter.Filter Keyword.Keyword,
    count :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
