{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttachAll where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttachAll as AttachAll

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's AttachAll arm.
codec :: Codec.Codec AttachAll.AttachAll
codec = Fields.object $ do
  subjects <- Fields.required "subjects" ObjectRef.codec AttachAll.subjects
  destination <- Fields.required "destination" (Filter.codec Keyword.codec) AttachAll.destination
  pure
    AttachAll.MkAttachAll
      { AttachAll.subjects = subjects,
        AttachAll.destination = destination
      }
