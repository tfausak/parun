{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PendingEntryEffect where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PendingEntryEffect as PendingEntryEffect

-- | `controller` is read at APPLICATION rather than re-derived at drain time (CR
-- 614.12), so it is stored beside the program and encoded with it.
codec :: Codec.Codec PendingEntryEffect.PendingEntryEffect
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec PendingEntryEffect.object
  controller <- Fields.required "controller" PlayerId.codec PendingEntryEffect.controller
  effects <- Fields.required "effects" (Common.seq (Effect.codec Card.codec (GrantedAbility.codec Card.codec))) PendingEntryEffect.effects
  pure
    PendingEntryEffect.MkPendingEntryEffect
      { PendingEntryEffect.object = object,
        PendingEntryEffect.controller = controller,
        PendingEntryEffect.effects = effects
      }
