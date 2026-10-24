module Parun.Codec.CostChoice where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CostChoice as CostChoice

-- | A bare ARRAY of costs, Parun.Codec.ManaCost's shape and for its reason: a
-- named domain type wrapping a collection gets a $defs entry of its own, and the
-- wrapper adds no key a card author would have to write.
--
-- 'Common.nonEmpty' is what rejects the empty array on the wire, which
-- Parun.Types.CostChoice says is a cost with no way to pay it.
codec :: Codec.Codec CostChoice.CostChoice
codec =
  Common.wrapper
    (Common.nonEmpty (Cost.codec Keyword.codec))
    CostChoice.MkCostChoice
    CostChoice.unwrap
