{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntryRestriction where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntryRestriction as EntryRestriction

-- | An object with two named keys, Parun.Codec.SacrificeRestriction's shape plus
-- the origin zones. Untagged for that codec's reason: Parun.Types.EntryRestriction
-- is a product with no sum for a tag to discriminate.
--
-- Both keys are REQUIRED. "origins" in particular has no defensible default: the
-- empty set would silently disarm the prohibition, and the full set would silently
-- widen a card that names two zones to all seven -- so a card that forgets the key
-- must fail to load rather than run wrong.
codec :: Codec.Codec EntryRestriction.EntryRestriction
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec EntryRestriction.affected
  origins <- Fields.required "origins" (Common.set Zone.codec) EntryRestriction.origins
  pure
    EntryRestriction.MkEntryRestriction
      { EntryRestriction.affected = affected,
        EntryRestriction.origins = origins
      }
