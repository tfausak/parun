module Parun.Types.LifeLossR where

import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.LifeLossRewrite as LifeLossRewrite

-- | The payload of Parun.Types.ReplacementEffect's LifeLossR arm: which life
-- losses are intercepted, and what happens instead -- how much of the loss
-- survives, or that none of it does.
data LifeLossR = MkLifeLossR
  { matching :: LifeLossPattern.LifeLossPattern,
    rewrite :: LifeLossRewrite.LifeLossRewrite
  }
  deriving (Eq, Ord, Show)
