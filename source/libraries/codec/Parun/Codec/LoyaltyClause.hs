module Parun.Codec.LoyaltyClause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LoyaltyClause as LoyaltyClause

-- | Nullary tags, Parun.Codec.LoyaltyKind's shape.
codec :: Codec.Codec LoyaltyClause.LoyaltyClause
codec = Arm.enum
