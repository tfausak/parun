{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Protection where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Protection as Protection

-- | A bare object keyed by the record's field names, Parun.Codec.Cycling's shape.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Protection.Protection keyword)
codec keywordCodec = Fields.object $ do
  quality <- Fields.required "quality" (Filter.codec keywordCodec) Protection.quality
  spares <- Fields.required "spares" (Common.maybe (Filter.codec keywordCodec)) Protection.spares
  pure Protection.MkProtection {Protection.quality = quality, Protection.spares = spares}
