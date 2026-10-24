{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachBound where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachBound as AttachBound

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's AttachBound arm.
codec :: Codec.Codec AttachBound.AttachBound
codec = Fields.object $ do
  subject <- Fields.required "subject" SlotName.codec AttachBound.subject
  destination <- Fields.required "destination" SlotName.codec AttachBound.destination
  pure
    AttachBound.MkAttachBound
      { AttachBound.subject = subject,
        AttachBound.destination = destination
      }
