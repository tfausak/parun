{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountIs where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountIs as CountIs

codec :: Codec.Codec CountIs.CountIs
codec = Fields.object $ do
  player <- Fields.required "player" Label.codec CountIs.player
  zone <- Fields.required "zone" Arm.keyedEnum CountIs.zone
  card <- Fields.required "card" CardName.codec CountIs.card
  count <- Fields.required "count" Common.natural CountIs.count
  pure
    CountIs.MkCountIs
      { CountIs.player = player,
        CountIs.zone = zone,
        CountIs.card = card,
        CountIs.count = count
      }
