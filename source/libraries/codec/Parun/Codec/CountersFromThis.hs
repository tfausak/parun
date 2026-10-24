{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountersFromThis where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountersFromThis as CountersFromThis

-- | The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (CountersFromThis.CountersFromThis keyword)
codec keywordCodec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec keywordCodec) CountersFromThis.kind
  count <- Fields.required "count" Common.natural CountersFromThis.count
  pure CountersFromThis.MkCountersFromThis {CountersFromThis.kind = kind, CountersFromThis.count = count}
