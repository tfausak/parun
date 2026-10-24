module Parun.Codec.Scaling where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Scaling as Scaling

codec :: Codec.Codec Scaling.Scaling
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Multiply" Common.natural Scaling.Multiply (\x -> case x of Scaling.Multiply y -> Just y; _ -> Nothing),
      Arm.payload "AddMore" Common.natural Scaling.AddMore (\x -> case x of Scaling.AddMore y -> Just y; _ -> Nothing),
      Arm.payload "Subtract" Common.natural Scaling.Subtract (\x -> case x of Scaling.Subtract y -> Just y; _ -> Nothing),
      Arm.nullary "Halve" Scaling.Halve
    ]

tagOf :: Scaling.Scaling -> String
tagOf x = case x of
  Scaling.Multiply {} -> "Multiply"
  Scaling.AddMore {} -> "AddMore"
  Scaling.Subtract {} -> "Subtract"
  Scaling.Halve {} -> "Halve"
