{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterPlacement where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterPlacement as CounterPlacement

-- | A bare object keyed by the record's field names, Parun.Codec.SelfCountersReached's
-- shape.
codec :: Codec.Codec CounterPlacement.CounterPlacement
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) CounterPlacement.kind
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) CounterPlacement.permanents
  pure
    CounterPlacement.MkCounterPlacement
      { CounterPlacement.kind = kind,
        CounterPlacement.permanents = permanents
      }
