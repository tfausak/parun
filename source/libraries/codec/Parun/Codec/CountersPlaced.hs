{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountersPlaced where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountersPlaced as CountersPlaced

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec CountersPlaced.CountersPlaced
codec = Fields.object $ do
  putter <- Fields.required "putter" PlayerId.codec CountersPlaced.putter
  object <- Fields.required "object" ObjectId.codec CountersPlaced.object
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) CountersPlaced.kind
  before <- Fields.required "before" Common.natural CountersPlaced.before
  after <- Fields.required "after" Common.natural CountersPlaced.after
  pure
    CountersPlaced.MkCountersPlaced
      { CountersPlaced.putter = putter,
        CountersPlaced.object = object,
        CountersPlaced.kind = kind,
        CountersPlaced.before = before,
        CountersPlaced.after = after
      }
