{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterRestriction as CounterRestriction

-- | An object with two named keys, Parun.Codec.EntryRestriction's shape with a
-- counter kind where that one has origin zones. Untagged for that codec's
-- reason: Parun.Types.CounterRestriction is a product with no sum for a tag to
-- discriminate.
--
-- "affected" is REQUIRED and "kind" DEFAULTS to Nothing, and the asymmetry is the
-- two keys' meanings. A missing affected set has no defensible default -- the
-- empty one disarms the prohibition and the full one widens it to the whole
-- board -- while a missing kind is exactly what Solemnity prints, a prohibition
-- naming no kind at all.
codec :: Codec.Codec CounterRestriction.CounterRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec CounterRestriction.affected
  kind <- Fields.defaulted "kind" Nothing (Common.maybe (CounterKind.codec Keyword.codec)) CounterRestriction.kind
  pure
    CounterRestriction.MkCounterRestriction
      { CounterRestriction.affected = affected,
        CounterRestriction.kind = kind
      }
