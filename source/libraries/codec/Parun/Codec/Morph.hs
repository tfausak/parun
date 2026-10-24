{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Morph where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.MorphVariant as MorphVariant
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Morph as Morph

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). The keyword codec is a PARAMETER; see
-- Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Morph.Morph keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Morph.cost
  variant <- Fields.required "variant" MorphVariant.codec Morph.variant
  pure Morph.MkMorph {Morph.cost = cost, Morph.variant = variant}
