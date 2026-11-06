{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TurnMarker where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TurnMarker as TurnMarker

codec :: Codec.Codec TurnMarker.TurnMarker
codec = Fields.object $ do
  number <- Fields.required "number" Common.natural TurnMarker.number
  holder <- Fields.required "holder" PlayerId.codec TurnMarker.holder
  underWay <- Fields.required "underWay" Common.boolean TurnMarker.underWay
  owesTurn <- Fields.required "owesTurn" Common.boolean TurnMarker.owesTurn
  removals <- Fields.required "removals" Common.natural TurnMarker.removals
  pure
    TurnMarker.MkTurnMarker
      { TurnMarker.number = number,
        TurnMarker.holder = holder,
        TurnMarker.underWay = underWay,
        TurnMarker.owesTurn = owesTurn,
        TurnMarker.removals = removals
      }
