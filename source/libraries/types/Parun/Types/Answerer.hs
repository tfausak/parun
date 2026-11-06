{-# LANGUAGE RankNTypes #-}

module Parun.Types.Answerer where

-- | Something that answers the engine's questions, each put as a `q`: a
-- scenario's timeline, a person, a bot, or chance. The engine puts them as
-- 'Parun.Types.Asked.Asked' over the whole state, a seat's answerer as Asked
-- over that seat's view.
newtype Answerer q m = MkAnswerer
  { unwrap :: forall r. q r -> m r
  }
