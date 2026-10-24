{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SelfCountersRemoved where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SelfCountersRemoved as SelfCountersRemoved

codec :: Codec.Codec SelfCountersRemoved.SelfCountersRemoved
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) SelfCountersRemoved.kind
  pure
    SelfCountersRemoved.MkSelfCountersRemoved
      { SelfCountersRemoved.kind = kind
      }
