{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.TargetRestriction where

import qualified Pawl.Codec.Affected as Affected
import qualified Pawl.Codec.StackObjectKind as StackObjectKind
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.TargetRestriction as TargetRestriction

-- | An object with two named keys, Pawl.Codec.CrewRestriction's shape plus the
-- kind of spell or ability stopped.
codec :: Codec.Codec TargetRestriction.TargetRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec TargetRestriction.affected
  kind <- Fields.required "kind" StackObjectKind.codec TargetRestriction.kind
  pure TargetRestriction.MkTargetRestriction {TargetRestriction.affected = affected, TargetRestriction.kind = kind}
