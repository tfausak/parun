{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Devotion where

import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Devotion as Devotion

-- | A bare object keyed by the record's field names; the tag that picks it is
-- Parun.Codec.Quantity's "Devotion".
codec :: Codec.Codec Devotion.Devotion
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec Devotion.player
  colors <- Fields.required "colors" (Common.set Color.codec) Devotion.colors
  pure Devotion.MkDevotion {Devotion.player = player, Devotion.colors = colors}
