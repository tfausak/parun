module Parun.Codec.RepeatIfSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.RepeatIf as RepeatIf
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RepeatIf as RepeatIf
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Text.Text' for Parun.Codec.ForEachSpec's reason.
codec :: Codec.Codec (RepeatIf.RepeatIf Text.Text)
codec = RepeatIf.codec Common.text

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RepeatIf" $ do
  -- Grist, the Hunger Tide's shape. The two effect lists differ in length, so a
  -- codec that swapped them is caught.
  Spec.it s "MkRepeatIf" $
    Common.assertCodec
      s
      codec
      ( RepeatIf.MkRepeatIf
          { RepeatIf.process = Seq.fromList [Text.pack "create", Text.pack "mill"],
            RepeatIf.condition = Condition.Compares (Compares.MkCompares (Quantity.InSlot (SlotName.MkSlotName (Text.pack "milled"))) Comparison.AtLeast (Quantity.Literal 1)),
            RepeatIf.ifHolds = Seq.singleton (Text.pack "counter")
          }
      )
      " {\"process\":[\"create\",\"mill\"],\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"InSlot\",\"value\":\"milled\"},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"ifHolds\":[\"counter\"]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
