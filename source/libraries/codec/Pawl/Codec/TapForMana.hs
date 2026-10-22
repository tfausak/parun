{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.TapForMana where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.ManaRestriction as ManaRestriction
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.TapForMana as TapForMana

-- | A bare object keyed by the record's field names, as every other
-- Pawl.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec TapForMana.TapForMana
codec = Fields.object $ do
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) TapForMana.permanents
  restriction <- Fields.defaulted "restriction" Nothing (Common.maybe ManaRestriction.codec) TapForMana.restriction
  pure
    TapForMana.MkTapForMana
      { TapForMana.permanents = permanents,
        TapForMana.restriction = restriction
      }
