module Parun.Types.Throw where

import qualified Data.Sequence as Seq
import qualified Numeric.Natural as Natural
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.ThrowKind as ThrowKind

-- | The payload of Parun.Types.ProposedEvent's WouldThrow arm (CR 705.1 / 706.1
-- / 614.1a): a flip of coins or a roll of dice, as CR 614's loop settles it.
--
-- ONE type for both, because Pokey, the Scallywagg turns one into the other
-- inside the same CR 616.1 loop (CR 614.6), unit for unit, and keeps the rest
-- of the event: Krark's Thumb's extra coins become extra dice and Pixie Guide's
-- ignored die an ignored coin. `kind` is the classification a row reads --
-- Krark's Thumb applies to coins and Pixie Guide to dice.
--
-- `thrower` is the player the instruction is aimed at -- CR 705.2's flipper,
-- one of Parun.Types.RollDie's rollers.
--
-- `units` has one entry per coin or die the INSTRUCTION names, and one per die
-- a row adds (Pixie Guide's "that many dice plus one"); each entry is how many
-- are thrown for it, of which one is kept by the thrower's choice -- Krark's
-- Thumb's "flip two coins and ignore one", whose ruling replaces "each
-- individual coin flip". A printed instruction's entries are all 1.
--
-- `ignored` is CR 706.6's count of the lowest units then thrown away, zero
-- until Pixie Guide applies. A coin standing for a die is low on tails, Pokey's
-- "tails is 1". What is left -- `units` less `ignored` -- is what the
-- instruction reads: one face for a flip, its count of results for a roll.
--
-- `instead` marks a throw made INSTEAD of the other kind (CR 614.6, Pokey), so
-- the funnel that proposed it reads the result back as what it stands for:
-- "1-10 is tails and 11-20 is heads", "tails is 1 and heads is 20".
data Throw = MkThrow
  { thrower :: PlayerId.PlayerId,
    kind :: ThrowKind.ThrowKind,
    units :: Seq.Seq Natural.Natural,
    ignored :: Natural.Natural,
    instead :: Bool
  }
  deriving (Eq, Ord, Show)
