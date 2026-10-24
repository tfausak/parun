{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExtraTurn where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExtraTurn as ExtraTurn

-- | The CR 500.11 skips travel WITH the turn rather than referencing it, so they
-- are a field here and not a separate collection keyed by turn.
codec :: Codec.Codec ExtraTurn.ExtraTurn
codec = Fields.object $ do
  taker <- Fields.required "taker" PlayerId.codec ExtraTurn.taker
  source <- Fields.required "source" ObjectId.codec ExtraTurn.source
  skipped <- Fields.required "skipped" (Common.set PhaseSelector.codec) ExtraTurn.skipped
  createdAt <- Fields.required "createdAt" Timestamp.codec ExtraTurn.createdAt
  pure
    ExtraTurn.MkExtraTurn
      { ExtraTurn.taker = taker,
        ExtraTurn.source = source,
        ExtraTurn.skipped = skipped,
        ExtraTurn.createdAt = createdAt
      }
