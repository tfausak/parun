{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CrewRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CrewRestriction as CrewRestriction

-- | An object with one named key, Parun.Codec.SacrificeRestriction's shape and for
-- its reason: Parun.Types.CrewRestriction is a newtype over one field, so there is
-- no sum for a tag to discriminate.
codec :: Codec.Codec CrewRestriction.CrewRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec CrewRestriction.affected
  pure CrewRestriction.MkCrewRestriction {CrewRestriction.affected = affected}
