{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Sacrifice where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CostAmount as CostAmount
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Sacrifice as Sacrifice

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). The keyword codec is a PARAMETER; see
-- Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Sacrifice.Sacrifice keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" CostAmount.codec Sacrifice.count
  whichPermanents <- Fields.required "whichPermanents" (Filter.codec keywordCodec) Sacrifice.whichPermanents
  pure Sacrifice.MkSacrifice {Sacrifice.count = count, Sacrifice.whichPermanents = whichPermanents}
