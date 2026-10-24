module Parun.Codec.Loyalty where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Loyalty as Loyalty

-- | Tagged like every other sum, so that CR 107.3's printed X is a wire value
-- rather than a sentinel number the decoder would have to reserve.
codec :: Codec.Codec Loyalty.Loyalty
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Literal" Common.natural Loyalty.Literal (\x -> case x of Loyalty.Literal y -> Just y; _ -> Nothing),
      Arm.nullary "Variable" Loyalty.Variable
    ]

tagOf :: Loyalty.Loyalty -> String
tagOf x = case x of
  Loyalty.Literal {} -> "Literal"
  Loyalty.Variable {} -> "Variable"
