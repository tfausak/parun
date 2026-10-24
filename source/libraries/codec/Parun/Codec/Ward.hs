{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Ward where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.PlayerCounterTally as PlayerCounterTally
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Ward as Ward

-- | A bare object keyed by the record's field names, Parun.Codec.Cycling's
-- shape. @perEach@ is defaulted rather than required, so a ward whose cost is a
-- printed number still writes nothing but its cost. The keyword codec is a
-- PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Ward.Ward keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Ward.cost
  perEach <- Fields.defaulted "perEach" Nothing (Common.maybe PlayerCounterTally.codec) Ward.perEach
  pure Ward.MkWard {Ward.cost = cost, Ward.perEach = perEach}
