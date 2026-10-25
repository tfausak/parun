{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TargetRestriction where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.TargetRestriction as TargetRestriction

-- | An object with named keys, Parun.Codec.CrewRestriction's shape plus the
-- kind of spell or ability stopped and, where narrower than every one of that
-- kind, which. PARAMETRIC in the affected set for the type's reason: a face
-- passes Parun.Codec.Affected's codec, a player effect a Filter's.
codec ::
  (Typeable.Typeable affected) =>
  Codec.Codec affected ->
  Codec.Codec (TargetRestriction.TargetRestriction affected)
codec affectedCodec = Fields.object $ do
  affected <- Fields.required "affected" affectedCodec TargetRestriction.affected
  kind <- Fields.required "kind" StackObjectKind.codec TargetRestriction.kind
  aimers <- Fields.defaulted "aimers" (Filter.And []) (Filter.codec Keyword.codec) TargetRestriction.aimers
  pure TargetRestriction.MkTargetRestriction {TargetRestriction.affected = affected, TargetRestriction.kind = kind, TargetRestriction.aimers = aimers}
