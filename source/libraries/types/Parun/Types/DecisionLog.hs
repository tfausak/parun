module Parun.Types.DecisionLog where

import qualified Parun.Types.Response as Response

data DecisionLog = MkDecisionLog
  { seed :: Int,
    responses :: [Response.Response]
  }
  deriving (Eq, Ord, Show)
