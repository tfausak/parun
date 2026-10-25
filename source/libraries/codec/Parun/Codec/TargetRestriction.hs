{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TargetRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.TargetRestriction as TargetRestriction

-- | An object with named keys, Parun.Codec.CrewRestriction's shape plus the
-- kind of spell or ability stopped and, where narrower than every one of that
-- kind, which.
codec :: Codec.Codec TargetRestriction.TargetRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec TargetRestriction.affected
  kind <- Fields.required "kind" StackObjectKind.codec TargetRestriction.kind
  aimers <- Fields.defaulted "aimers" (Filter.And []) (Filter.codec Keyword.codec) TargetRestriction.aimers
  pure TargetRestriction.MkTargetRestriction {TargetRestriction.affected = affected, TargetRestriction.kind = kind, TargetRestriction.aimers = aimers}
