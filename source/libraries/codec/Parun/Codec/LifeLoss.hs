{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeLoss where

import qualified Parun.Codec.LifeLossCause as LifeLossCause
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LifeLossCause as LifeLossCause.Type

-- | Parun.Codec.PlayerQuantity's two keys, so a printing that loses life is
-- written exactly as it was before the cause existed, plus a "cause" ELIDED at
-- CR 119.3's ordinary one -- which is every printing in data\/cards\/.
codec :: Codec.Codec LifeLoss.LifeLoss
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec LifeLoss.player
  quantity <- Fields.required "quantity" Quantity.codec LifeLoss.quantity
  cause <- Fields.defaulted "cause" LifeLossCause.Type.ByEffect LifeLossCause.codec LifeLoss.cause
  tally <- Fields.defaulted "tally" Nothing (Common.maybe SlotName.codec) LifeLoss.tally
  pure
    LifeLoss.MkLifeLoss
      { LifeLoss.player = player,
        LifeLoss.quantity = quantity,
        LifeLoss.cause = cause,
        LifeLoss.tally = tally
      }
