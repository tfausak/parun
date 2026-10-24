{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.When where

import qualified Parun.Codec.Label as Label
import qualified Parun.Codec.Phase as Phase
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.When as When

codec :: Codec.Codec When.When
codec = Fields.object fields

-- | The keys alone, which Parun.Codec.Timed writes into its own object.
fields :: Fields.Fields When.When When.When
fields = do
  turn <- Fields.required "turn" Common.natural When.turn
  phase <- Fields.required "step" Phase.flat When.phase
  player <- Fields.required "player" Label.codec When.player
  pure When.MkWhen {When.turn = turn, When.phase = phase, When.player = player}
