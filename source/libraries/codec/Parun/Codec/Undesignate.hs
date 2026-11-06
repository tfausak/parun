{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Undesignate where

import qualified Parun.Codec.Designation as Designation
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Undesignate as Undesignate

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Undesignate arm.
codec :: Codec.Codec Undesignate.Undesignate
codec = Fields.object $ do
  designation <- Fields.required "designation" Designation.codec Undesignate.designation
  ref <- Fields.required "ref" ObjectRef.codec Undesignate.ref
  pure
    Undesignate.MkUndesignate
      { Undesignate.designation = designation,
        Undesignate.ref = ref
      }
