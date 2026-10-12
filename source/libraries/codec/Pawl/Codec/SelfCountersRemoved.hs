{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.SelfCountersRemoved where

import qualified Pawl.Codec.CounterKind as CounterKind
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.SelfCountersRemoved as SelfCountersRemoved

codec :: Codec.Codec SelfCountersRemoved.SelfCountersRemoved
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) SelfCountersRemoved.kind
  pure
    SelfCountersRemoved.MkSelfCountersRemoved
      { SelfCountersRemoved.kind = kind
      }
