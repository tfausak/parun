{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.UntapRestriction where

import qualified Pawl.Codec.Affected as Affected
import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.Codec.UntapHold as UntapHold
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.UntapHold as UntapHold.Type
import qualified Pawl.Types.UntapRestriction as UntapRestriction

-- | An object of named keys, Pawl.Codec.SacrificeRestriction's shape and for its
-- reason: Pawl.Types.UntapRestriction is a record, so there is no sum for a tag
-- to discriminate. `hold` is omitted at UntapHold.Forbidden, what every
-- "doesn't untap" printing means, and `while` where the restriction always
-- applies.
codec :: Codec.Codec UntapRestriction.UntapRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec UntapRestriction.affected
  hold <- Fields.defaulted "hold" UntapHold.Type.Forbidden UntapHold.codec UntapRestriction.hold
  while <- Fields.defaulted "while" Nothing (Common.maybe Condition.codec) UntapRestriction.while
  pure UntapRestriction.MkUntapRestriction {UntapRestriction.affected = affected, UntapRestriction.hold = hold, UntapRestriction.while = while}
