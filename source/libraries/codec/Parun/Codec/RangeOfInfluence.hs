module Parun.Codec.RangeOfInfluence where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence

-- | Keyed by a PlayerId, so 'Common.naturalMap', as Parun.Codec.Teams is.
codec :: Codec.Codec RangeOfInfluence.RangeOfInfluence
codec = Common.wrapper (Common.naturalMap PlayerId.codec Common.natural) RangeOfInfluence.MkRangeOfInfluence RangeOfInfluence.unwrap
