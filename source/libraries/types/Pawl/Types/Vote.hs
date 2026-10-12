module Pawl.Types.Vote where

import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.VoteChoices as VoteChoices

-- | The payload of Pawl.Types.Effect's Vote arm (CR 701.38a): each player,
-- starting with @starter@ and proceeding in turn order, chooses one of the
-- listed choices, and what the tally decides depends on which kind of choice
-- the card listed (Pawl.Types.VoteChoices).
data Vote = MkVote
  { -- | CR 701.38a's "specified player", the seat the vote starts with.
    starter :: PlayerRef.PlayerRef,
    -- | CR 701.38b: the listed choices.
    choices :: VoteChoices.VoteChoices,
    -- | Whether each ballot is shown to its voter alone until every ballot is
    -- revealed at once: secret council's card text; the ability word has no
    -- rules meaning (CR 207.2c).
    secret :: Bool
  }
  deriving (Eq, Ord, Show)
