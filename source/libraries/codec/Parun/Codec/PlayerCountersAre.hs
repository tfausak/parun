{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerCountersAre where

import qualified Parun.Codec.Label as Label
import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerCountersAre as PlayerCountersAre

codec :: Codec.Codec PlayerCountersAre.PlayerCountersAre
codec = Fields.object $ do
  player <- Fields.required "player" Label.codec PlayerCountersAre.player
  kind <- Fields.required "kind" PlayerCounterKind.codec PlayerCountersAre.kind
  count <- Fields.required "count" Common.natural PlayerCountersAre.count
  pure PlayerCountersAre.MkPlayerCountersAre {PlayerCountersAre.player = player, PlayerCountersAre.kind = kind, PlayerCountersAre.count = count}
