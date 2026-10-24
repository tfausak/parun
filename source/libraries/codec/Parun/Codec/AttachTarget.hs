{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachTarget where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachTarget as AttachTarget

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's AttachTarget arm.
codec :: Codec.Codec AttachTarget.AttachTarget
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec AttachTarget.slot
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) AttachTarget.filter
  pure
    AttachTarget.MkAttachTarget
      { AttachTarget.slot = slot,
        AttachTarget.filter = filter_
      }
