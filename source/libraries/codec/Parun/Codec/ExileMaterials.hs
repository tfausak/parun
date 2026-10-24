{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileMaterials where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileMaterials as ExileMaterials

-- | A bare object keyed by the record's field names,
-- Parun.Codec.ExileCardsFromGraveyard's shape. The keyword codec is a PARAMETER;
-- see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ExileMaterials.ExileMaterials keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural ExileMaterials.count
  orMore <- Fields.defaulted "orMore" False Common.boolean ExileMaterials.orMore
  whichObjects <- Fields.required "whichObjects" (Filter.codec keywordCodec) ExileMaterials.whichObjects
  pure ExileMaterials.MkExileMaterials {ExileMaterials.count = count, ExileMaterials.orMore = orMore, ExileMaterials.whichObjects = whichObjects}
