module Parun.Codec.DivideSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Divide as Divide
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Divide as Divide
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Divide" $ do
  let slot = SlotName.MkSlotName . Text.pack
  Spec.it s "the default chooser is omitted" $
    Common.assertCodec
      s
      Divide.codec
      (Divide.MkDivide (Quantity.Literal 3) (ObjectRef.InSlot (slot "wolves")) (PlayerRef.Relative PlayerRelation.You) (slot "split"))
      " {\"quantity\":{\"type\":\"Literal\",\"value\":3},\"among\":{\"type\":\"InSlot\",\"value\":\"wolves\"},\"slot\":\"split\"} "
  Spec.it s "another chooser is written" $
    Common.assertCodec
      s
      Divide.codec
      (Divide.MkDivide (Quantity.Literal 3) (ObjectRef.InSlot (slot "wolves")) (PlayerRef.ControllerOfBound (slot "target")) (slot "split"))
      " {\"quantity\":{\"type\":\"Literal\",\"value\":3},\"among\":{\"type\":\"InSlot\",\"value\":\"wolves\"},\"chooser\":{\"type\":\"ControllerOfBound\",\"value\":\"target\"},\"slot\":\"split\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Divide.codec
