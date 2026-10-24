{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachRestriction as AttachRestriction

-- | An object with two named keys, Parun.Codec.CantBeBlockedBy's shape and for its
-- reason: Parun.Types.AttachRestriction is one record with no sum for a tag to
-- discriminate, and its two permanent-naming keys are not interchangeable.
-- Naming them is what stops a card file barring the hosts from themselves.
--
-- Both required. A prohibition with no 'attachers' bars nothing and one with no
-- 'affected' names nobody, so neither has a default a card could mean.
codec :: Codec.Codec AttachRestriction.AttachRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AttachRestriction.affected
  attachers <- Fields.required "attachers" (Filter.codec Keyword.codec) AttachRestriction.attachers
  pure
    AttachRestriction.MkAttachRestriction
      { AttachRestriction.affected = affected,
        AttachRestriction.attachers = attachers
      }
