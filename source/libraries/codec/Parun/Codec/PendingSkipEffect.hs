{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PendingSkipEffect where

import qualified Parun.Codec.ExtraTurn as ExtraTurn
import qualified Parun.Codec.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Codec.TurnMarker as TurnMarker
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PendingSkipEffect as PendingSkipEffect

codec :: Codec.Codec PendingSkipEffect.PendingSkipEffect
codec = Fields.object $ do
  pending <- Fields.required "pending" PendingReplacementEffect.codec PendingSkipEffect.pending
  extraTurns <- Fields.defaulted "extraTurns" [] (Common.list ExtraTurn.codec) PendingSkipEffect.extraTurns
  turnMarkers <- Fields.defaulted "turnMarkers" [] (Common.list TurnMarker.codec) PendingSkipEffect.turnMarkers
  pure
    PendingSkipEffect.MkPendingSkipEffect
      { PendingSkipEffect.pending = pending,
        PendingSkipEffect.extraTurns = extraTurns,
        PendingSkipEffect.turnMarkers = turnMarkers
      }
