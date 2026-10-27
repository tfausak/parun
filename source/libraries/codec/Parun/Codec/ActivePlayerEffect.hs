{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActivePlayerEffect where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.AffectedPlayers as AffectedPlayers
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerEffect as PlayerEffect
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.SourceChoices as SourceChoices
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.Types.SlotName as SlotName

-- | `scope` is the PLAYER instantiation of Parun.Types.AffectedPlayers: a stored
-- row's Named arm holds the seat CR 601.2c's slot was answered with, where a card
-- writes the slot name. Parun.Codec.AffectedPlayers takes its inner codec as a
-- parameter so both instantiations go through the one bundle.
codec :: Codec.Codec ActivePlayerEffect.ActivePlayerEffect
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActivePlayerEffect.source
  controller <- Fields.required "controller" PlayerId.codec ActivePlayerEffect.controller
  choices <- Fields.required "choices" SourceChoices.codec ActivePlayerEffect.choices
  timestamp <- Fields.required "timestamp" Timestamp.codec ActivePlayerEffect.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActivePlayerEffect.expiry
  scope <- Fields.required "scope" (AffectedPlayers.codec PlayerId.codec) ActivePlayerEffect.scope
  effect <- Fields.required "effect" PlayerEffect.codec ActivePlayerEffect.effect
  ability <- Fields.defaulted "ability" Nothing (Common.maybe AbilityName.codec) ActivePlayerEffect.ability
  slots <-
    Fields.defaulted
      "slots"
      Map.empty
      (Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) (Common.set ObjectId.codec))
      ActivePlayerEffect.slots
  pure
    ActivePlayerEffect.MkActivePlayerEffect
      { ActivePlayerEffect.source = source,
        ActivePlayerEffect.controller = controller,
        ActivePlayerEffect.choices = choices,
        ActivePlayerEffect.timestamp = timestamp,
        ActivePlayerEffect.expiry = expiry,
        ActivePlayerEffect.scope = scope,
        ActivePlayerEffect.effect = effect,
        ActivePlayerEffect.ability = ability,
        ActivePlayerEffect.slots = slots
      }
