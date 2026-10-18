{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.FromAnywhere where

import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.FromAnywhere as FromAnywhere

-- | A bare object keyed by the record's field names, @among@ omitted when it
-- names no slot.
codec :: Codec.Codec FromAnywhere.FromAnywhere
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec FromAnywhere.slot
  among <- Fields.defaulted "among" Nothing (Common.maybe SlotName.codec) FromAnywhere.among
  pure
    FromAnywhere.MkFromAnywhere
      { FromAnywhere.slot = slot,
        FromAnywhere.among = among
      }
