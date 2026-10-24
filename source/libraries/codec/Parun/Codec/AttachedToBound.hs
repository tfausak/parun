{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachedToBound where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachedToBound as AttachedToBound

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.ObjectRef's AttachedToBound arm.
codec :: Codec.Codec AttachedToBound.AttachedToBound
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec AttachedToBound.slot
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) AttachedToBound.filter
  pure
    AttachedToBound.MkAttachedToBound
      { AttachedToBound.slot = slot,
        AttachedToBound.filter = filter_
      }
