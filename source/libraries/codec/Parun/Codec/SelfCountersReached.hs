{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SelfCountersReached where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SelfCountersReached as SelfCountersReached

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be.
codec :: Codec.Codec SelfCountersReached.SelfCountersReached
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) SelfCountersReached.kind
  amount <- Fields.required "amount" Common.natural SelfCountersReached.amount
  pure
    SelfCountersReached.MkSelfCountersReached
      { SelfCountersReached.kind = kind,
        SelfCountersReached.amount = amount
      }
