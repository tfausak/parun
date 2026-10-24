{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ReturnPermanents where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ReturnPermanents as ReturnPermanents

-- | A bare object keyed by the record's field names, Parun.Codec.TapPermanents'
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ReturnPermanents.ReturnPermanents keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural ReturnPermanents.count
  whichPermanents <- Fields.required "whichPermanents" (Filter.codec keywordCodec) ReturnPermanents.whichPermanents
  pure ReturnPermanents.MkReturnPermanents {ReturnPermanents.count = count, ReturnPermanents.whichPermanents = whichPermanents}
