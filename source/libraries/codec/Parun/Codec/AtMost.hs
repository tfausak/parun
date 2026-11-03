{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AtMost where

import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AtMost as AtMost

-- | A bare object keyed by the record's field names. The quantity codec is a
-- PARAMETER for Parun.Codec.Plus's reason.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (AtMost.AtMost quantity)
codec quantityCodec = Fields.object $ do
  quantity <- Fields.required "quantity" quantityCodec AtMost.quantity
  limits <- Fields.required "limits" (Common.nonEmpty quantityCodec) AtMost.limits
  pure AtMost.MkAtMost {AtMost.quantity = quantity, AtMost.limits = limits}
