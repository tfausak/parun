module Parun.Codec.ExchangedValueSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExchangedValue as ExchangedValue
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExchangedValue as ExchangedValue
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExchangedValue" $ do
  Spec.it s "LifeTotal" $
    Common.assertCodec
      s
      ExchangedValue.codec
      (ExchangedValue.LifeTotal (PlayerRef.Relative PlayerRelation.You))
      " {\"type\":\"LifeTotal\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  Spec.it s "Power" $
    Common.assertCodec
      s
      ExchangedValue.codec
      (ExchangedValue.Power (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))))
      " {\"type\":\"Power\",\"value\":{\"type\":\"InSlot\",\"value\":\"self\"}} "
  Spec.it s "Toughness" $
    Common.assertCodec
      s
      ExchangedValue.codec
      (ExchangedValue.Toughness (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))))
      " {\"type\":\"Toughness\",\"value\":{\"type\":\"InSlot\",\"value\":\"self\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExchangedValue.codec
