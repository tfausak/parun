{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SacrificeRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SacrificeRestriction as SacrificeRestriction

-- | An object with one named key, the shape Parun.Codec.AttackRequirement has and
-- for its reason: Parun.Types.SacrificeRestriction is a newtype over one field,
-- so there is no sum for a tag to discriminate. Parun.Codec.CombatRestriction is
-- tagged because that type has six arms.
--
-- The key is "affected" and not "subject": CR 701.21a's prohibition names the
-- permanents it restricts, which is the word CombatRestriction's payload spells,
-- where a requirement's "subject" is opposed to an object it acts on.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec SacrificeRestriction.SacrificeRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec SacrificeRestriction.affected
  pure SacrificeRestriction.MkSacrificeRestriction {SacrificeRestriction.affected = affected}
