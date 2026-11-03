module Parun.Codec.ChosenQuality where

import qualified Parun.Codec.ChooseBetween as ChooseBetween
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ChosenQuality as ChosenQuality

codec :: Codec.Codec ChosenQuality.ChosenQuality
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Colors" ChooseBetween.codec ChosenQuality.Colors (\x -> case x of ChosenQuality.Colors y -> Just y; _ -> Nothing),
      Arm.nullary "BasicLandType" ChosenQuality.BasicLandType,
      Arm.nullary "CreatureType" ChosenQuality.CreatureType,
      Arm.payload "Number" ChooseBetween.codec ChosenQuality.Number (\x -> case x of ChosenQuality.Number y -> Just y; _ -> Nothing)
    ]

tagOf :: ChosenQuality.ChosenQuality -> String
tagOf x = case x of
  ChosenQuality.Colors {} -> "Colors"
  ChosenQuality.BasicLandType -> "BasicLandType"
  ChosenQuality.Number {} -> "Number"
  ChosenQuality.CreatureType -> "CreatureType"
