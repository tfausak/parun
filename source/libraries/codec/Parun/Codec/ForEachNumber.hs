{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ForEachNumber where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ForEachNumber as ForEachNumber

-- | A bare object keyed by the record's field names, every one required, as
-- Parun.Codec.ForEach's structural fields are. The effect codec is a parameter
-- for that module's reason.
codec ::
  (Typeable.Typeable effect) =>
  Codec.Codec effect ->
  Codec.Codec (ForEachNumber.ForEachNumber effect)
codec effectCodec = Fields.object $ do
  upTo <- Fields.required "upTo" Quantity.codec ForEachNumber.upTo
  slot <- Fields.required "slot" SlotName.codec ForEachNumber.slot
  body <- Fields.required "body" (Common.seq effectCodec) ForEachNumber.body
  pure
    ForEachNumber.MkForEachNumber
      { ForEachNumber.upTo = upTo,
        ForEachNumber.slot = slot,
        ForEachNumber.body = body
      }
