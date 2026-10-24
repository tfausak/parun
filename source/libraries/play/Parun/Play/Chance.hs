{-# LANGUAGE GADTs #-}

-- | Chance: every random prompt answered from the generator.
module Parun.Play.Chance where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Play.SplitMix as SplitMix
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.CoinFace as CoinFace
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.SplitMix as SplitMix.Type

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
