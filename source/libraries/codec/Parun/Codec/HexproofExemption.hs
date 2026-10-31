{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.HexproofExemption where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.HexproofExemption as HexproofExemption

-- | A bare object keyed by the record's field names, as every other
-- Parun.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec HexproofExemption.HexproofExemption
codec = Fields.object $ do
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) HexproofExemption.permanents
  players <- Fields.defaulted "players" False Common.boolean HexproofExemption.players
  pure
    HexproofExemption.MkHexproofExemption
      { HexproofExemption.permanents = permanents,
        HexproofExemption.players = players
      }
