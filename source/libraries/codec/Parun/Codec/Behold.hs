{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Behold where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Behold as Behold

-- | A bare object keyed by the record's field names, Parun.Codec.ExileMaterials'
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Behold.Behold keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural Behold.count
  whichObjects <- Fields.required "whichObjects" (Filter.codec keywordCodec) Behold.whichObjects
  pure Behold.MkBehold {Behold.count = count, Behold.whichObjects = whichObjects}
