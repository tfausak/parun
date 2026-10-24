{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PendingReplacementEffect where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.SlotName as SlotName

-- | Parun.Codec.PreventionRider's shape, field for field: the snapshotted target
-- map takes 'Common.textMap' for that codec's reason.
codec :: Codec.Codec PendingReplacementEffect.PendingReplacementEffect
codec = Fields.object $ do
  effects <- Fields.required "effects" (Common.seq (Effect.codec Card.codec (GrantedAbility.codec Card.codec))) PendingReplacementEffect.effects
  targets <- Fields.required "targets" (Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) (Common.set Recipient.codec)) PendingReplacementEffect.targets
  controller <- Fields.required "controller" PlayerId.codec PendingReplacementEffect.controller
  source <- Fields.required "source" ObjectId.codec PendingReplacementEffect.source
  pure
    PendingReplacementEffect.MkPendingReplacementEffect
      { PendingReplacementEffect.effects = effects,
        PendingReplacementEffect.targets = targets,
        PendingReplacementEffect.controller = controller,
        PendingReplacementEffect.source = source
      }
