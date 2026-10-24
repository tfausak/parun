{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Craft where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.ExileMaterials as ExileMaterials
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Craft as Craft

-- | A bare object keyed by the record's field names, Parun.Codec.Equip's shape.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Craft.Craft keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Craft.cost
  materials <- Fields.required "materials" (ExileMaterials.codec keywordCodec) Craft.materials
  pure Craft.MkCraft {Craft.cost = cost, Craft.materials = materials}
