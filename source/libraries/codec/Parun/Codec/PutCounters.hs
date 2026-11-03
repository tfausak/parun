{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PutCounters where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PutCounters as PutCounters

-- | A bare object keyed by the record's field names, the limit elided when
-- absent. The tag that picks it is written by Parun.Codec.Effect's PutCounters
-- arm.
codec :: Codec.Codec PutCounters.PutCounters
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) PutCounters.kind
  quantity <- Fields.required "quantity" Quantity.codec PutCounters.quantity
  ref <- Fields.required "ref" ObjectRef.codec PutCounters.ref
  totalAtMost <- Fields.defaulted "totalAtMost" Nothing (Common.maybe Common.natural) PutCounters.totalAtMost
  pure
    PutCounters.MkPutCounters
      { PutCounters.kind = kind,
        PutCounters.quantity = quantity,
        PutCounters.ref = ref,
        PutCounters.totalAtMost = totalAtMost
      }
