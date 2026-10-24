{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Timed where

import qualified Parun.Codec.Entry as Entry
import qualified Parun.Codec.Reference as Reference
import qualified Parun.Codec.When as When
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Timed as Timed

-- | One flat object: the moment's keys, an optional @source@, and @do@ or
-- @check@.
codec :: Codec.Codec Timed.Timed
codec = Fields.object $ do
  when <- Fields.contramap Timed.when When.fields
  source <- Fields.defaulted "source" Nothing (Common.maybe Reference.codec) Timed.source
  entry <- Fields.contramap Timed.entry Entry.fields
  pure Timed.MkTimed {Timed.when = when, Timed.source = source, Timed.entry = entry}
