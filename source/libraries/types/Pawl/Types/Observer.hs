{-# LANGUAGE RankNTypes #-}

module Pawl.Types.Observer where

import qualified Pawl.Types.Asked as Asked

-- | Something that watches each prompt before it is answered and each answer
-- after, and answers nothing itself.
data Observer m = MkObserver
  { before :: forall r. Asked.Asked r -> m (),
    after :: forall r. Asked.Asked r -> r -> m ()
  }
