{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntryOrigin where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntryOrigin as EntryOrigin

-- | `holder` defaulted to absent and `index` to 0, so a shared zone is its zone
-- alone.
codec :: Codec.Codec EntryOrigin.EntryOrigin
codec = Fields.object $ do
  zone <- Fields.required "zone" Zone.codec EntryOrigin.zone
  holder <- Fields.defaulted "holder" Nothing (Common.maybe PlayerId.codec) EntryOrigin.holder
  index <- Fields.defaulted "index" 0 Common.natural EntryOrigin.index
  pure
    EntryOrigin.MkEntryOrigin
      { EntryOrigin.zone = zone,
        EntryOrigin.holder = holder,
        EntryOrigin.index = index
      }
