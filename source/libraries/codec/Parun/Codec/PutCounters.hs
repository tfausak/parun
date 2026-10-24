{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PutCounters where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PutCounters as PutCounters

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's PutCounters arm.
codec :: Codec.Codec PutCounters.PutCounters
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) PutCounters.kind
  quantity <- Fields.required "quantity" Quantity.codec PutCounters.quantity
  ref <- Fields.required "ref" ObjectRef.codec PutCounters.ref
  pure
    PutCounters.MkPutCounters
      { PutCounters.kind = kind,
        PutCounters.quantity = quantity,
        PutCounters.ref = ref
      }
