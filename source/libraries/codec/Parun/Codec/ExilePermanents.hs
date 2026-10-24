{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExilePermanents where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExilePermanents as ExilePermanents

-- | A bare object keyed by the record's field names, Parun.Codec.TapPermanents'
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ExilePermanents.ExilePermanents keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural ExilePermanents.count
  whichPermanents <- Fields.required "whichPermanents" (Filter.codec keywordCodec) ExilePermanents.whichPermanents
  pure ExilePermanents.MkExilePermanents {ExilePermanents.count = count, ExilePermanents.whichPermanents = whichPermanents}
