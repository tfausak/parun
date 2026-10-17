{-# LANGUAGE RankNTypes #-}

module Pawl.Types.Answerer where

import qualified Pawl.Types.Asked as Asked

-- | Something that answers the engine's prompts: a scenario's timeline, a
-- person, a bot, or chance.
newtype Answerer m = MkAnswerer
  { unwrap :: forall r. Asked.Asked r -> m r
  }
