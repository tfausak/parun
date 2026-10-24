{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerActed where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerAction as PlayerAction
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerActed as PlayerActed

-- | A bare object keyed by the record's field names, the player written with
-- whichever codec its parameter takes.
codec :: (Typeable.Typeable player) => Codec.Codec player -> Codec.Codec (PlayerActed.PlayerActed player)
codec player = Fields.object $ do
  action <- Fields.required "action" PlayerAction.codec PlayerActed.action
  actor <- Fields.required "player" player PlayerActed.player
  pure PlayerActed.MkPlayerActed {PlayerActed.action = action, PlayerActed.player = actor}
