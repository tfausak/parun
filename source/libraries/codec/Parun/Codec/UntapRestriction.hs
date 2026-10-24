{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.UntapRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.UntapHold as UntapHold
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.UntapHold as UntapHold.Type
import qualified Parun.Types.UntapRestriction as UntapRestriction

-- | An object of named keys, Parun.Codec.SacrificeRestriction's shape and for its
-- reason: Parun.Types.UntapRestriction is a record, so there is no sum for a tag
-- to discriminate. `hold` is omitted at UntapHold.Forbidden, what every
-- "doesn't untap" printing means, and `while` where the restriction always
-- applies.
codec :: Codec.Codec UntapRestriction.UntapRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec UntapRestriction.affected
  hold <- Fields.defaulted "hold" UntapHold.Type.Forbidden UntapHold.codec UntapRestriction.hold
  while <- Fields.defaulted "while" Nothing (Common.maybe Condition.codec) UntapRestriction.while
  pure UntapRestriction.MkUntapRestriction {UntapRestriction.affected = affected, UntapRestriction.hold = hold, UntapRestriction.while = while}
