{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Splice where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Splice as Splice

-- | A bare object keyed by the record's field names, Parun.Codec.Craft's shape.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Splice.Splice keyword)
codec keywordCodec = Fields.object $ do
  onto <- Fields.required "onto" (Filter.codec keywordCodec) Splice.onto
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Splice.cost
  pure Splice.MkSplice {Splice.onto = onto, Splice.cost = cost}
