module Parun.Codec.OperandSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Operand as Operand
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Operand" $ do
  Spec.it s "Literal" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.Literal 4)
      " {\"type\":\"Literal\",\"value\":4} "
  Spec.it s "OfSource" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.OfSource Measure.Toughness)
      " {\"type\":\"OfSource\",\"value\":{\"type\":\"Toughness\"}} "
  Spec.it s "Own" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.Own Measure.Power)
      " {\"type\":\"Own\",\"value\":{\"type\":\"Power\"}} "
  Spec.it s "OfBound" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.OfBound (BoundMeasure.MkBoundMeasure (SlotName.MkSlotName (Text.pack "thatExploitedCreature")) Measure.Toughness))
      " {\"type\":\"OfBound\",\"value\":{\"slot\":\"thatExploitedCreature\",\"measure\":{\"type\":\"Toughness\"}}} "
  Spec.it s "AmountInSlot" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.AmountInSlot (SlotName.MkSlotName (Text.pack "paid")))
      " {\"type\":\"AmountInSlot\",\"value\":\"paid\"} "
  Spec.it s "EnclosingAmount" $
    Common.assertCodec
      s
      Operand.codec
      Operand.EnclosingAmount
      " {\"type\":\"EnclosingAmount\"} "
  Spec.it s "OfEachOtherCandidate" $
    Common.assertCodec
      s
      Operand.codec
      (Operand.OfEachOtherCandidate Measure.ManaValue)
      " {\"type\":\"OfEachOtherCandidate\",\"value\":{\"type\":\"ManaValue\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Operand.codec
