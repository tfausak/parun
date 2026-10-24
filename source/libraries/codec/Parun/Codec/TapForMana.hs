{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TapForMana where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaRestriction as ManaRestriction
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TapForMana as TapForMana

-- | A bare object keyed by the record's field names, as every other
-- Parun.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec TapForMana.TapForMana
codec = Fields.object $ do
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) TapForMana.permanents
  restriction <- Fields.defaulted "restriction" Nothing (Common.maybe ManaRestriction.codec) TapForMana.restriction
  pure
    TapForMana.MkTapForMana
      { TapForMana.permanents = permanents,
        TapForMana.restriction = restriction
      }
