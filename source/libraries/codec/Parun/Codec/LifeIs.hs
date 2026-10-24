{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeIs where

import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeIs as LifeIs

codec :: Codec.Codec LifeIs.LifeIs
codec = Fields.object $ do
  player <- Fields.required "player" Label.codec LifeIs.player
  life <- Fields.required "life" Common.integer LifeIs.life
  pure LifeIs.MkLifeIs {LifeIs.player = player, LifeIs.life = life}
