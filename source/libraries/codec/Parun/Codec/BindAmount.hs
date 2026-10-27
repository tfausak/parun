{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BindAmount where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BindAmount as BindAmount

codec :: Codec.Codec BindAmount.BindAmount
codec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec BindAmount.quantity
  slot <- Fields.required "slot" SlotName.codec BindAmount.slot
  pure
    BindAmount.MkBindAmount
      { BindAmount.quantity = quantity,
        BindAmount.slot = slot
      }
