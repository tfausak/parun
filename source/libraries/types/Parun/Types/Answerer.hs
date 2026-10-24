{-# LANGUAGE RankNTypes #-}

module Parun.Types.Answerer where

import qualified Parun.Types.Asked as Asked

-- | Something that answers the engine's prompts: a scenario's timeline, a
-- person, a bot, or chance.
newtype Answerer m = MkAnswerer
  { unwrap :: forall r. Asked.Asked r -> m r
  }
