module Pawl.Types.ExileFromGraveyard where

import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Quantity as Quantity

-- | CR 614.1c / 614.13's as-enters exile out of a graveyard: what may be
-- exiled, out of whose graveyards, how many, and what each card exiled buys.
--
-- A PlayerScope rather than Pawl.Types.ZoneScope, whose slot arms an entry
-- replacement cannot answer: no resolution binds a slot as a permanent enters.
data ExileFromGraveyard = MkExileFromGraveyard
  { filter :: Filter.Filter Keyword.Keyword,
    -- | CR 109.5 against the entering permanent's controller: Living Lore's
    -- "your graveyard", Dermotaxi's "a graveyard".
    players :: PlayerScope.PlayerScope,
    -- | Living Lore's "an instant or sorcery card" is one; Sutured Ghoul's "any
    -- number" is UpTo with no ceiling, Frankenstein's Monster's "X" Exactly X.
    count :: HowMany.HowMany,
    -- | CR 614.12 / Frankenstein's Monster: "If you can't, put this creature
    -- into its owner's graveyard instead of onto the battlefield" -- too few
    -- candidates for an Exactly count exiles nothing and unmakes the entry.
    orGraveyard :: Bool,
    -- | Frankenstein's Monster's "a +2/+0, +1/+1, or +0/+2 counter" for each
    -- card exiled: the controller picks one kind per card, asked only where
    -- there are two or more. Empty places nothing.
    kinds :: [CounterKind.CounterKind Keyword.Keyword],
    -- | How many counters of the chosen kind each card exiled buys,
    -- SacrificeAnyNumber's `each`; inert where `kinds` is empty.
    each :: Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
