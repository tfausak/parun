{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeTrigger where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.TriggerFrequency as TriggerFrequencyType

-- | A bare object keyed by the record's field names. EveryTime writes no
-- frequency key.
codec :: Codec.Codec LifeTrigger.LifeTrigger
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec LifeTrigger.player
  frequency <- Fields.defaulted "frequency" TriggerFrequencyType.EveryTime TriggerFrequency.codec LifeTrigger.frequency
  pure
    LifeTrigger.MkLifeTrigger
      { LifeTrigger.player = player,
        LifeTrigger.frequency = frequency
      }
