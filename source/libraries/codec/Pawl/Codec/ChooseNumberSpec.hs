module Pawl.Codec.ChooseNumberSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.ChooseNumber as ChooseNumber
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ChooseNumber as ChooseNumber
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ChooseNumber" $ do
  Spec.it s "unbounded" $
    Common.assertCodec
      s
      ChooseNumber.codec
      (ChooseNumber.MkChooseNumber (SlotName.MkSlotName (Text.pack "number")) Nothing (PlayerRef.Relative PlayerRelation.You))
      " {\"slot\":\"number\"} "
  Spec.it s "bounded" $
    Common.assertCodec
      s
      ChooseNumber.codec
      (ChooseNumber.MkChooseNumber (SlotName.MkSlotName (Text.pack "drawn")) (Just 4) (PlayerRef.Relative PlayerRelation.You))
      " {\"slot\":\"drawn\",\"upTo\":4} "
  Spec.it s "a chooser other than you" $
    Common.assertCodec
      s
      ChooseNumber.codec
      (ChooseNumber.MkChooseNumber (SlotName.MkSlotName (Text.pack "drawn")) (Just 2) (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "player"))))
      " {\"slot\":\"drawn\",\"upTo\":2,\"chooser\":{\"type\":\"InSlot\",\"value\":\"player\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChooseNumber.codec
