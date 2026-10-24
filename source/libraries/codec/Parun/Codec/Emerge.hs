{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Emerge where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Emerge as Emerge

-- | A bare object keyed by the record's field names, Parun.Codec.Equip's shape.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Emerge.Emerge keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Emerge.cost
  quality <- Fields.required "quality" (Common.maybe (Filter.codec keywordCodec)) Emerge.quality
  pure Emerge.MkEmerge {Emerge.cost = cost, Emerge.quality = quality}
