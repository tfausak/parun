{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerLosesLife where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerLosesLife as PlayerLosesLife
import qualified Parun.Types.TriggerFrequency as TriggerFrequencyType

-- | A bare object keyed by the record's field names. EveryTime writes no
-- frequency key.
codec :: Codec.Codec PlayerLosesLife.PlayerLosesLife
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PlayerLosesLife.player
  frequency <- Fields.defaulted "frequency" TriggerFrequencyType.EveryTime TriggerFrequency.codec PlayerLosesLife.frequency
  pure
    PlayerLosesLife.MkPlayerLosesLife
      { PlayerLosesLife.player = player,
        PlayerLosesLife.frequency = frequency
      }
