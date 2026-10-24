{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Connive where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Connive as Connive

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Connive arm.
codec :: Codec.Codec Connive.Connive
codec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec Connive.quantity
  ref <- Fields.required "ref" ObjectRef.codec Connive.ref
  pure
    Connive.MkConnive
      { Connive.quantity = quantity,
        Connive.ref = ref
      }
