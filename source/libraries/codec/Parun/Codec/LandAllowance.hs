module Parun.Codec.LandAllowance where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.LandAllowance as LandAllowance

-- | Tagged rather than an enum, since one arm carries a count.
codec :: Codec.Codec LandAllowance.LandAllowance
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Additional" Common.natural LandAllowance.Additional (\x -> case x of LandAllowance.Additional y -> Just y; _ -> Nothing),
      Arm.nullary "AnyNumber" LandAllowance.AnyNumber
    ]

tagOf :: LandAllowance.LandAllowance -> String
tagOf x = case x of
  LandAllowance.Additional {} -> "Additional"
  LandAllowance.AnyNumber {} -> "AnyNumber"
