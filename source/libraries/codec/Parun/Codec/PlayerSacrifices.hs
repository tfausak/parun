{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerSacrifices where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerSacrifices as PlayerSacrifices

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's PlayerSacrifices arm.
codec :: Codec.Codec PlayerSacrifices.PlayerSacrifices
codec = Fields.object $ do
  players <- Fields.required "players" PlayerRef.codec PlayerSacrifices.players
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PlayerSacrifices.filter
  quantity <- Fields.required "quantity" Quantity.codec PlayerSacrifices.quantity
  permanents <- Fields.defaulted "permanents" Nothing (Common.maybe SlotName.codec) PlayerSacrifices.permanents
  pure
    PlayerSacrifices.MkPlayerSacrifices
      { PlayerSacrifices.players = players,
        PlayerSacrifices.filter = filter_,
        PlayerSacrifices.quantity = quantity,
        PlayerSacrifices.permanents = permanents
      }
