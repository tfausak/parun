{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.While where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.While as While

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be.
codec :: Codec.Codec While.While
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec While.player
  condition <- Fields.required "condition" Condition.codec While.condition
  pure While.MkWhile {While.player = player, While.condition = condition}
