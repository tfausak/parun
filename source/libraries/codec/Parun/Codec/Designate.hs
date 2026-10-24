{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Designate where

import qualified Parun.Codec.Designation as Designation
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Designate as Designate

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Designate arm.
codec :: Codec.Codec Designate.Designate
codec = Fields.object $ do
  designation <- Fields.required "designation" Designation.codec Designate.designation
  slot <- Fields.required "slot" SlotName.codec Designate.slot
  value <- Fields.defaulted "value" Nothing (Common.maybe Quantity.codec) Designate.value
  pure
    Designate.MkDesignate
      { Designate.designation = designation,
        Designate.slot = slot,
        Designate.value = value
      }
