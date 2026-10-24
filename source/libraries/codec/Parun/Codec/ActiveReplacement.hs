{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveReplacement where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PreventionRider as PreventionRider
import qualified Parun.Codec.ReplacementEffect as ReplacementEffect
import qualified Parun.Codec.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.Uses as Uses
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.SlotName as SlotName

-- | The effect codec is CLOSED here rather than a parameter, unlike
-- Parun.Codec.ReplacementEffect's: the type fixes it at
-- @ReplacementEffect (Effect Card)@, so there is nothing to thread.
--
-- `slots` is keyed by a slot name, which is a Text newtype, so it takes
-- 'Common.textMap' -- the wrap Parun.Codec.Binding and Parun.Codec.PreventionRider
-- pass. Its VALUE is a set of ids rather than one, because CR 603.7c's snapshot
-- can name several.
codec :: Codec.Codec ActiveReplacement.ActiveReplacement
codec = Fields.object $ do
  effect <- Fields.required "effect" (ReplacementEffect.codec Card.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec))) ActiveReplacement.effect
  source <- Fields.required "source" ObjectId.codec ActiveReplacement.source
  controller <- Fields.required "controller" PlayerId.codec ActiveReplacement.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveReplacement.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveReplacement.expiry
  uses <- Fields.required "uses" Uses.codec ActiveReplacement.uses
  origin <- Fields.required "origin" ReplacementOrigin.codec ActiveReplacement.origin
  condition <- Fields.required "condition" (Common.maybe Condition.codec) ActiveReplacement.condition
  rider <- Fields.required "rider" (Common.maybe PreventionRider.codec) ActiveReplacement.rider
  slots <-
    Fields.required
      "slots"
      (Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) (Common.set ObjectId.codec))
      ActiveReplacement.slots
  pure
    ActiveReplacement.MkActiveReplacement
      { ActiveReplacement.effect = effect,
        ActiveReplacement.source = source,
        ActiveReplacement.controller = controller,
        ActiveReplacement.timestamp = timestamp,
        ActiveReplacement.expiry = expiry,
        ActiveReplacement.uses = uses,
        ActiveReplacement.origin = origin,
        ActiveReplacement.condition = condition,
        ActiveReplacement.rider = rider,
        ActiveReplacement.slots = slots
      }
