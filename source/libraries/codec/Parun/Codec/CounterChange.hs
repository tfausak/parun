{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterChange where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterChange as CounterChange

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec CounterChange.CounterChange
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec CounterChange.object
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) CounterChange.kind
  before <- Fields.required "before" Common.natural CounterChange.before
  after <- Fields.required "after" Common.natural CounterChange.after
  pure
    CounterChange.MkCounterChange
      { CounterChange.object = object,
        CounterChange.kind = kind,
        CounterChange.before = before,
        CounterChange.after = after
      }
