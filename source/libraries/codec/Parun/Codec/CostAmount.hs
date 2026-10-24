module Parun.Codec.CostAmount where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CostAmount as CostAmount

codec :: Codec.Codec CostAmount.CostAmount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Fixed" Common.natural CostAmount.Fixed (\x -> case x of CostAmount.Fixed y -> Just y; _ -> Nothing),
      Arm.payload "Announced" SlotName.codec CostAmount.Announced (\x -> case x of CostAmount.Announced y -> Just y; _ -> Nothing)
    ]

tagOf :: CostAmount.CostAmount -> String
tagOf x = case x of
  CostAmount.Fixed {} -> "Fixed"
  CostAmount.Announced {} -> "Announced"
