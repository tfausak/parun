module Parun.Codec.AloneAmong where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AloneAmong as AloneAmong

-- | Nullary tags, Parun.Codec.LoyaltyClause's shape.
codec :: Codec.Codec AloneAmong.AloneAmong
codec = Arm.enum
