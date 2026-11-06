module Parun.Types.FromOutsideTheGame where

import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Types.DifferentIn as DifferentIn
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.OutsidePick as OutsidePick

-- | CR 400.11c: which of the cards a player owns outside the game an
-- instruction may bring in, how many, where it puts what it brings, and whether
-- that instruction shows the cards first.

-- A record rather than a bare Filter because the axes are independent. The
-- wish cycle prints filter and reveal together -- Burning Wish's "reveal a
-- sorcery card you own from outside the game and put it into your hand" --
-- while Death Wish prints the move alone, and CR 701.20a's showing is a keyword
-- action separate from the move it accompanies; The Raven's Warning then prints
-- the same move to another zone, and Research another count.
data FromOutsideTheGame = MkFromOutsideTheGame
  { -- | How many cards the instruction brings in: the wish cycle's "a card" is
    -- one, Research's "up to four cards" four.
    --
    -- A Natural rather than Parun.Types.Search's Maybe Quantity: every printing
    -- states a literal count, and none states "any number" of cards it puts in
    -- (MTGJSON dump of 2026-08-23, text "outside the game"; Spawnsire of
    -- Ulamog's "any number" CASTS, which is not this instruction).
    count :: Natural.Natural,
    -- | Whether the printed count is "up to", a ceiling the player chooses
    -- within -- Research's. Parun.Types.Search.upTo's reading: without it the
    -- player brings in as many of the admitted cards as the count allows.
    upTo :: Bool,
    -- | Where the cards this instruction brings in arrive (CR 400.11b).
    destination :: OutsideDestination.OutsideDestination,
    -- | Which cards out there the instruction admits (CR 400.11c), matched
    -- against the PRINTED FACE since CR 604.3 leaves nothing else out there to
    -- read.
    --
    -- Not a Maybe: an instruction naming no quality -- Death Wish's "a card you
    -- own from outside the game" -- is @And []@, which admits everything, so a
    -- Maybe would give one instruction two spellings.
    filter :: Filter.Filter Keyword.Keyword,
    -- | Whether CR 701.20a's reveal rides along, as the wish cycle prints it and
    -- Death Wish does not.
    reveal :: Bool,
    -- | A characteristic no two of the cards may share -- Extrapolate the
    -- Impossible's "with different names" (CR 201.2b), Parun.Types.Search's
    -- field. Empty where the sentence prints no such clause.
    differentIn :: Set.Set DifferentIn.DifferentIn,
    -- | Who chooses which of the revealed cards come in, and how many -- the
    -- rest stay outside the game. Nothing where every card comes in.
    pick :: Maybe OutsidePick.OutsidePick
  }
  deriving (Eq, Ord, Show)
