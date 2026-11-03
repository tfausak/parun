{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntryLink where

import qualified Parun.Codec.Acquisition as Acquisition
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.EntryLink as EntryLink

-- | An object keyed by the record's field names; "acquisition" defaults to
-- Own, the abilities the source has of its own.
codec :: Codec.Codec EntryLink.EntryLink
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec EntryLink.source
  acquisition <- Fields.defaulted "acquisition" Acquisition.Own Acquisition.codec EntryLink.acquisition
  pure EntryLink.MkEntryLink {EntryLink.source = source, EntryLink.acquisition = acquisition}
