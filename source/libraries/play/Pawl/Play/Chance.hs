{-# LANGUAGE GADTs #-}

-- | Chance: every random prompt answered from the generator.
module Pawl.Play.Chance where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Pawl.Engine.Replay as Replay
import qualified Pawl.Play.SplitMix as SplitMix
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.CoinFace as CoinFace
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.SplitMix as SplitMix.Type

-- | Each random prompt drawn from the generator (CR 701.24a's shuffle, CR
-- 706's die, CR 705's coin); every other prompt answered by
-- 'Replay.defaultAnswer'.
chance :: (Monad m) => Answerer.Answerer (State.StateT SplitMix.Type.SplitMix m)
chance = Answerer.MkAnswerer $ \asked -> case Asked.prompt asked of
  Prompt.Shuffle ids -> SplitMix.shuffle ids
  Prompt.RandomFirstPlayer order -> SplitMix.pick order
  Prompt.RandomObject candidates -> SplitMix.pick candidates
  Prompt.RandomStickerSheet slots -> SplitMix.pick slots
  Prompt.RandomPlayer candidates -> SplitMix.pick candidates
  Prompt.RandomCard candidates -> SplitMix.pick candidates
  Prompt.RollDie sides -> SplitMix.between 1 sides
  Prompt.RandomDepth depth -> SplitMix.between 1 depth
  Prompt.FlipCoin -> SplitMix.pick (CoinFace.Heads NonEmpty.:| [CoinFace.Tails])
  prompt -> pure (Replay.defaultAnswer prompt)
