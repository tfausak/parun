module Parun.Types.Decider where

import qualified Parun.Types.PlayerId as PlayerId

newtype Decider = MkDecider
  { unwrap :: PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
