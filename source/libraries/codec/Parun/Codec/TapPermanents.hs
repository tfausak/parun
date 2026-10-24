{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TapPermanents where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CostAmount as CostAmount
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TapPermanents as TapPermanents

-- | A bare object keyed by the record's field names, Parun.Codec.Sacrifice's
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (TapPermanents.TapPermanents keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" CostAmount.codec TapPermanents.count
  whichPermanents <- Fields.required "whichPermanents" (Filter.codec keywordCodec) TapPermanents.whichPermanents
  sharingACreatureType <- Fields.defaulted "sharingACreatureType" False Common.boolean TapPermanents.sharingACreatureType
  pure TapPermanents.MkTapPermanents {TapPermanents.count = count, TapPermanents.whichPermanents = whichPermanents, TapPermanents.sharingACreatureType = sharingACreatureType}
