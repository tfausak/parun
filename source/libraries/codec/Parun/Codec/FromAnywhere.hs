{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FromAnywhere where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FromAnywhere as FromAnywhere

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
