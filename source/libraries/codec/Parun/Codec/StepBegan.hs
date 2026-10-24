{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StepBegan where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StepBegan as StepBegan

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec StepBegan.StepBegan
codec = Fields.object $ do
  phase <- Fields.required "phase" Phase.codec StepBegan.phase
  player <- Fields.required "player" PlayerId.codec StepBegan.player
  pure
    StepBegan.MkStepBegan
      { StepBegan.phase = phase,
        StepBegan.player = player
      }
