{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SkipPhase where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Uses as Uses
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Duration as Duration.Type
import qualified Parun.Types.SkipPhase as SkipPhase
import qualified Parun.Types.Uses as Uses.Type

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's SkipPhase arm. `uses` and `duration` default
-- to CR 614.10a's "next" occurrence, whenever it comes.
codec :: Codec.Codec SkipPhase.SkipPhase
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec SkipPhase.player
  selector <- Fields.required "selector" PhaseSelector.codec SkipPhase.selector
  uses <- Fields.defaulted "uses" Uses.Type.Once Uses.codec SkipPhase.uses
  duration <- Fields.defaulted "duration" Duration.Type.Indefinite Duration.codec SkipPhase.duration
  pure
    SkipPhase.MkSkipPhase
      { SkipPhase.player = player,
        SkipPhase.selector = selector,
        SkipPhase.uses = uses,
        SkipPhase.duration = duration
      }
