module Parun.Codec.ChooseNumberSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ChooseNumber as ChooseNumber
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChooseNumber as ChooseNumber
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChooseNumber" $ do
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
