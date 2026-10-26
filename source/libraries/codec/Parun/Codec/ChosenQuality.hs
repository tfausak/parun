module Parun.Codec.ChosenQuality where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ChosenQuality as ChosenQuality

codec :: Codec.Codec ChosenQuality.ChosenQuality
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Colors" Common.natural ChosenQuality.Colors (\x -> case x of ChosenQuality.Colors y -> Just y; _ -> Nothing),
      Arm.nullary "BasicLandType" ChosenQuality.BasicLandType,
      Arm.nullary "CreatureType" ChosenQuality.CreatureType
    ]

tagOf :: ChosenQuality.ChosenQuality -> String
tagOf x = case x of
  ChosenQuality.Colors {} -> "Colors"
  ChosenQuality.BasicLandType -> "BasicLandType"
  ChosenQuality.CreatureType -> "CreatureType"
