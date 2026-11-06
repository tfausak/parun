{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterLink where

import qualified Parun.Codec.Acquisition as Acquisition
import qualified Parun.Codec.CounterLinked as CounterLinked
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.CounterLink as CounterLink

-- | An object keyed by the record's field names; "acquisition" defaults to
-- Own, Parun.Codec.EntryLink's reason.
codec :: Codec.Codec CounterLink.CounterLink
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec CounterLink.source
  acquisition <- Fields.defaulted "acquisition" Acquisition.Own Acquisition.codec CounterLink.acquisition
  moved <- Fields.required "moved" (CounterLinked.codec Keyword.codec) CounterLink.moved
  pure CounterLink.MkCounterLink {CounterLink.source = source, CounterLink.acquisition = acquisition, CounterLink.moved = moved}
