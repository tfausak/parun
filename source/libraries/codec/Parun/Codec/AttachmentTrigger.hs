{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachmentTrigger where

import qualified Parun.Codec.AttachDirection as AttachDirection
import qualified Parun.Codec.AttachmentEnd as AttachmentEnd
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachmentTrigger as AttachmentTrigger

-- | A bare object keyed by the record's field names. Every key is required:
-- each printing names its end, its direction and the other end's quality.
codec :: Codec.Codec AttachmentTrigger.AttachmentTrigger
codec = Fields.object $ do
  end <- Fields.required "end" AttachmentEnd.codec AttachmentTrigger.end
  direction <- Fields.required "direction" AttachDirection.codec AttachmentTrigger.direction
  other <- Fields.required "other" (Filter.codec Keyword.codec) AttachmentTrigger.other
  pure AttachmentTrigger.MkAttachmentTrigger {AttachmentTrigger.end = end, AttachmentTrigger.direction = direction, AttachmentTrigger.other = other}
