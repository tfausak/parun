{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Cycling where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Cycling as Cycling

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). The keyword codec is a PARAMETER; see
-- Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Cycling.Cycling keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Cycling.cost
  searchFor <- Fields.required "searchFor" (Common.maybe (Filter.codec keywordCodec)) Cycling.searchFor
  pure Cycling.MkCycling {Cycling.cost = cost, Cycling.searchFor = searchFor}
