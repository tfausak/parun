module Parun.Codec.TargetChooserSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.TargetChooser as TargetChooser
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetChooser as TargetChooser

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TargetChooser" $ do
  Spec.it s "Relative" $
    Common.assertCodec
      s
      TargetChooser.codec
      (TargetChooser.Relative PlayerRelation.Opponent)
      " {\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}} "
  Spec.it s "InSlot" $
    Common.assertCodec
      s
      TargetChooser.codec
      (TargetChooser.InSlot (SlotName.MkSlotName (Text.pack "thatAttackingPlayer")))
      " {\"type\":\"InSlot\",\"value\":\"thatAttackingPlayer\"} "
  Spec.it s "ControllerOfBound" $
    Common.assertCodec
      s
      TargetChooser.codec
      (TargetChooser.ControllerOfBound (SlotName.MkSlotName (Text.pack "thatDepartedPermanent")))
      " {\"type\":\"ControllerOfBound\",\"value\":\"thatDepartedPermanent\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TargetChooser.codec
