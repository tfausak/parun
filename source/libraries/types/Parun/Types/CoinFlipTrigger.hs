module Parun.Types.CoinFlipTrigger where

import qualified Parun.Types.FlipOutcome as FlipOutcome
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 705.2: whose coin flip, and how it came out -- Tavern Scoundrel's
-- "whenever you win a coin flip", Karplusan Minotaur's "lose".
data CoinFlipTrigger = MkCoinFlipTrigger
  { -- | The flipper, read against CR 109.5's "you".
    player :: PlayerRelation.PlayerRelation,
    outcome :: FlipOutcome.FlipOutcome
  }
  deriving (Eq, Ord, Show)
