module Parun.Codec.Operand where

import qualified Parun.Codec.BoundMeasure as BoundMeasure
import qualified Parun.Codec.Measure as Measure
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Operand as Operand

codec :: Codec.Codec Operand.Operand
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Literal" Common.integer Operand.Literal (\x -> case x of Operand.Literal y -> Just y; _ -> Nothing),
      Arm.payload "OfSource" Measure.codec Operand.OfSource (\x -> case x of Operand.OfSource y -> Just y; _ -> Nothing),
      Arm.payload "Own" Measure.codec Operand.Own (\x -> case x of Operand.Own y -> Just y; _ -> Nothing),
      Arm.payload "OfBound" BoundMeasure.codec Operand.OfBound (\x -> case x of Operand.OfBound y -> Just y; _ -> Nothing),
      Arm.payload "AmountInSlot" SlotName.codec Operand.AmountInSlot (\x -> case x of Operand.AmountInSlot y -> Just y; _ -> Nothing),
      Arm.nullary "EnclosingAmount" Operand.EnclosingAmount,
      Arm.payload "OfEachOtherCandidate" Measure.codec Operand.OfEachOtherCandidate (\x -> case x of Operand.OfEachOtherCandidate y -> Just y; _ -> Nothing)
    ]

tagOf :: Operand.Operand -> String
tagOf x = case x of
  Operand.Literal {} -> "Literal"
  Operand.OfSource {} -> "OfSource"
  Operand.Own {} -> "Own"
  Operand.OfBound {} -> "OfBound"
  Operand.AmountInSlot {} -> "AmountInSlot"
  Operand.EnclosingAmount {} -> "EnclosingAmount"
  Operand.OfEachOtherCandidate {} -> "OfEachOtherCandidate"
