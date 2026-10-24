{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AfterTurn where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AfterTurn as AfterTurn

-- | A bare object keyed by the record's field names, like Parun.Codec.While
-- beside it.
codec :: Codec.Codec AfterTurn.AfterTurn
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec AfterTurn.player
  turn <- Fields.required "turn" Common.natural AfterTurn.turn
  pure AfterTurn.MkAfterTurn {AfterTurn.player = player, AfterTurn.turn = turn}
