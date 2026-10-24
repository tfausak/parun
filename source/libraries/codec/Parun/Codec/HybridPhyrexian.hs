{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.HybridPhyrexian where

import qualified Parun.Codec.Color as Color
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.HybridPhyrexian as HybridPhyrexian

-- | A bare object keyed by the record's field names, Parun.Codec.Hybrid's shape
-- (#1464) with a colour on each side.
codec :: Codec.Codec HybridPhyrexian.HybridPhyrexian
codec = Fields.object $ do
  left <- Fields.required "left" Color.codec HybridPhyrexian.left
  right <- Fields.required "right" Color.codec HybridPhyrexian.right
  pure HybridPhyrexian.MkHybridPhyrexian {HybridPhyrexian.left = left, HybridPhyrexian.right = right}
