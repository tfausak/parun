{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PreventionRider where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.SlotName as SlotName

-- | The snapshotted target map is keyed by a slot name, which is a Text newtype,
-- so it takes 'Common.textMap' rather than 'Common.naturalMap' -- the same wrap
-- Parun.Codec.Binding and Parun.Codec.TargetSlot pass.
codec :: Codec.Codec PreventionRider.PreventionRider
codec = Fields.object $ do
  effects <- Fields.required "effects" (Common.seq (Effect.codec Card.codec (GrantedAbility.codec Card.codec))) PreventionRider.effects
  targets <- Fields.required "targets" (Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) (Common.set Recipient.codec)) PreventionRider.targets
  controller <- Fields.required "controller" PlayerId.codec PreventionRider.controller
  source <- Fields.required "source" ObjectId.codec PreventionRider.source
  pure
    PreventionRider.MkPreventionRider
      { PreventionRider.effects = effects,
        PreventionRider.targets = targets,
        PreventionRider.controller = controller,
        PreventionRider.source = source
      }
