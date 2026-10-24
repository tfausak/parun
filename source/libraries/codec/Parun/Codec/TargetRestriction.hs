{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TargetRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TargetRestriction as TargetRestriction

-- | An object with two named keys, Parun.Codec.CrewRestriction's shape plus the
-- kind of spell or ability stopped.
codec :: Codec.Codec TargetRestriction.TargetRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec TargetRestriction.affected
  kind <- Fields.required "kind" StackObjectKind.codec TargetRestriction.kind
  pure TargetRestriction.MkTargetRestriction {TargetRestriction.affected = affected, TargetRestriction.kind = kind}
