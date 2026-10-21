{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.SkipPhase where

import qualified Pawl.Codec.Duration as Duration
import qualified Pawl.Codec.PhaseSelector as PhaseSelector
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.Codec.Uses as Uses
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Duration as Duration.Type
import qualified Pawl.Types.SkipPhase as SkipPhase
import qualified Pawl.Types.Uses as Uses.Type

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.Effect's SkipPhase arm. `uses` and `duration` default
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
