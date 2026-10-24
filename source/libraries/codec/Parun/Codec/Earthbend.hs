{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Earthbend where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Earthbend as Earthbend

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Earthbend arm.
codec :: Codec.Codec Earthbend.Earthbend
codec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec Earthbend.quantity
  ref <- Fields.required "ref" ObjectRef.codec Earthbend.ref
  pure
    Earthbend.MkEarthbend
      { Earthbend.quantity = quantity,
        Earthbend.ref = ref
      }
