{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Hybrid where

import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Hybrid as Hybrid

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec Hybrid.Hybrid
codec = Fields.object $ do
  left <- Fields.required "left" ManaType.codec Hybrid.left
  right <- Fields.required "right" ManaType.codec Hybrid.right
  pure Hybrid.MkHybrid {Hybrid.left = left, Hybrid.right = right}
