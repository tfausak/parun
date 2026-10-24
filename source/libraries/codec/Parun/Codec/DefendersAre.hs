{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DefendersAre where

import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DefendersAre as DefendersAre

codec :: Codec.Codec DefendersAre.DefendersAre
codec = Fields.object $ do
  players <- Fields.required "players" (Common.list Label.codec) DefendersAre.players
  pure DefendersAre.MkDefendersAre {DefendersAre.players = players}
