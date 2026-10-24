{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Amass where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Amass as Amass

-- | A bare object keyed by the record's field names, the slot ELIDED when absent
-- as Mill's is. The tag that picks it is written by Parun.Codec.Effect's Amass
-- arm.
codec :: Codec.Codec Amass.Amass
codec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec Amass.quantity
  subtype <- Fields.required "subtype" Subtype.codec Amass.subtype
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Amass.slot
  pure
    Amass.MkAmass
      { Amass.quantity = quantity,
        Amass.subtype = subtype,
        Amass.slot = slot
      }
