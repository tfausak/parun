{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamagePart where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamagePart as DamagePart

-- | A bare object keyed by the record's field names, written inside
-- Parun.Codec.DealDamage's "parts" array.
codec :: Codec.Codec DamagePart.DamagePart
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec DamagePart.ref
  quantity <- Fields.required "quantity" Quantity.codec DamagePart.quantity
  pure DamagePart.MkDamagePart {DamagePart.ref = ref, DamagePart.quantity = quantity}
