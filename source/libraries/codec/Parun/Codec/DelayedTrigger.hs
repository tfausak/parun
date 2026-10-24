{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DelayedTrigger where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Binding as Binding
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.Codec.TurnWindow as TurnWindow
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DelayedTrigger as DelayedTrigger

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec DelayedTrigger.DelayedTrigger
codec = Fields.object $ do
  ability <- Fields.required "ability" (TriggeredAbility.codec Card.codec (GrantedAbility.codec Card.codec)) DelayedTrigger.ability
  source <- Fields.required "source" ObjectId.codec DelayedTrigger.source
  controller <- Fields.required "controller" PlayerId.codec DelayedTrigger.controller
  bindings <- Fields.defaulted "bindings" Map.empty Binding.codecMap DelayedTrigger.bindings
  -- CR 603.7a: TurnWindow.AnyTurn for an ability armed with no onset gate.
  -- Always present, unlike the expiry below, because "no restriction" is one of
  -- the windows rather than the absence of one.
  window <- Fields.required "window" TurnWindow.codec DelayedTrigger.window
  -- CR 603.7b: absent for an ability with no stated duration.
  expiry <- Fields.defaulted "expiry" Nothing (Common.maybe Expiry.codec) DelayedTrigger.expiry
  -- CR 603.7a: always present, an entry having been created at some moment.
  createdAt <- Fields.required "createdAt" Timestamp.codec DelayedTrigger.createdAt
  pure
    DelayedTrigger.MkDelayedTrigger
      { DelayedTrigger.ability = ability,
        DelayedTrigger.source = source,
        DelayedTrigger.controller = controller,
        DelayedTrigger.bindings = bindings,
        DelayedTrigger.window = window,
        DelayedTrigger.expiry = expiry,
        DelayedTrigger.createdAt = createdAt
      }
