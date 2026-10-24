module Parun.Codec.GraveyardOrder where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.GraveyardOrder as GraveyardOrder

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec GraveyardOrder.GraveyardOrder
codec = Arm.enum
