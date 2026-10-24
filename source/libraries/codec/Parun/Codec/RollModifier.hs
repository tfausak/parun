module Parun.Codec.RollModifier where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.RollModifier as RollModifier

codec :: Codec.Codec RollModifier.RollModifier
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Reroll" RollModifier.Reroll,
      Arm.payload "IncreaseOrDecrease" Common.natural RollModifier.IncreaseOrDecrease (\x -> case x of RollModifier.IncreaseOrDecrease y -> Just y; _ -> Nothing)
    ]

tagOf :: RollModifier.RollModifier -> String
tagOf x = case x of
  RollModifier.Reroll {} -> "Reroll"
  RollModifier.IncreaseOrDecrease {} -> "IncreaseOrDecrease"
