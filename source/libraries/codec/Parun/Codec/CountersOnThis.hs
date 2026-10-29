{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountersOnThis where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountersOnThis as CountersOnThis

-- | The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (CountersOnThis.CountersOnThis keyword)
codec keywordCodec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec keywordCodec) CountersOnThis.kind
  count <- Fields.required "count" Common.natural CountersOnThis.count
  pure CountersOnThis.MkCountersOnThis {CountersOnThis.kind = kind, CountersOnThis.count = count}
