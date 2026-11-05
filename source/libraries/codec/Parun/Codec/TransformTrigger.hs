{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TransformTrigger where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.CardName as CardName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TransformTrigger as TransformTrigger

-- | A bare object keyed by the record's field names. The source and any face
-- write no key (TransformTrigger.defaultValue).
codec :: Codec.Codec TransformTrigger.TransformTrigger
codec = Fields.object $ do
  permanent <- Fields.defaulted "permanent" (TransformTrigger.permanent TransformTrigger.defaultValue) ActingPermanent.codec TransformTrigger.permanent
  into <- Fields.defaulted "into" (TransformTrigger.into TransformTrigger.defaultValue) (Common.maybe CardName.codec) TransformTrigger.into
  pure
    TransformTrigger.MkTransformTrigger
      { TransformTrigger.permanent = permanent,
        TransformTrigger.into = into
      }
