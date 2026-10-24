{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountersAre where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountersAre as CountersAre

-- | The kind is spelled as a placement's counters spell it.
codec :: Codec.Codec CountersAre.CountersAre
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec CountersAre.object
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) CountersAre.kind
  count <- Fields.required "count" Common.natural CountersAre.count
  pure CountersAre.MkCountersAre {CountersAre.object = object, CountersAre.kind = kind, CountersAre.count = count}
