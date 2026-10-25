{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EnteredZone where

import qualified Data.Set as Set
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EnteredZone as EnteredZone

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.CardsPutIntoZone is. The origin zones are defaulted, "from
-- anywhere" naming none.
codec :: Codec.Codec EnteredZone.EnteredZone
codec = Fields.object $ do
  to <- Fields.required "to" Zone.codec EnteredZone.to
  from <- Fields.defaulted "from" Set.empty (Common.set Zone.codec) EnteredZone.from
  pure EnteredZone.MkEnteredZone {EnteredZone.to = to, EnteredZone.from = from}
