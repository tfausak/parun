{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeTrigger where

import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.LifeDirection as LifeDirection
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Batching as BatchingType
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequencyType
import qualified Parun.Types.TurnScope as TurnScopeType

-- | A bare object keyed by the record's field names. @Relative AnyPlayer@, EachOccurrence
-- and EveryTime write no key.
codec :: Codec.Codec LifeTrigger.LifeTrigger
codec = Fields.object $ do
  direction <- Fields.required "direction" LifeDirection.codec LifeTrigger.direction
  player <- Fields.required "player" PlayerRelation.codec LifeTrigger.player
  scope <- Fields.defaulted "scope" (TurnScopeType.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer)) TurnScope.codec LifeTrigger.scope
  batching <- Fields.defaulted "batching" BatchingType.EachOccurrence Batching.codec LifeTrigger.batching
  frequency <- Fields.defaulted "frequency" TriggerFrequencyType.EveryTime TriggerFrequency.codec LifeTrigger.frequency
  pure
    LifeTrigger.MkLifeTrigger
      { LifeTrigger.direction = direction,
        LifeTrigger.player = player,
        LifeTrigger.scope = scope,
        LifeTrigger.batching = batching,
        LifeTrigger.frequency = frequency
      }
