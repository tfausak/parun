{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Arrival where

import qualified Parun.Codec.ArrivalEnd as ArrivalEnd
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Arrival as Arrival

codec :: Codec.Codec Arrival.Arrival
codec = Fields.object $ do
  owner <- Fields.required "owner" PlayerId.codec Arrival.owner
  end <- Fields.required "end" ArrivalEnd.codec Arrival.end
  cards <- Fields.required "cards" (Common.seq ObjectId.codec) Arrival.cards
  pure
    Arrival.MkArrival
      { Arrival.owner = owner,
        Arrival.end = end,
        Arrival.cards = cards
      }
