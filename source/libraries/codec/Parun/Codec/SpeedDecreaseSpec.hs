module Parun.Codec.SpeedDecreaseSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.SpeedDecrease as SpeedDecrease
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpeedDecrease as SpeedDecrease

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpeedDecrease" $ do
  -- Spikeshell Harrier's own value: "reduce that opponent's speed by 1. This
  -- effect can't reduce their speed below 1."
  Spec.it s "MkSpeedDecrease, with the printed floor" $
    Common.assertCodec
      s
      SpeedDecrease.codec
      (SpeedDecrease.MkSpeedDecrease (PlayerRef.ControllerOfBound (SlotName.MkSlotName (Text.pack "permanent"))) (Quantity.Literal 1) 1)
      " {\"player\":{\"type\":\"ControllerOfBound\",\"value\":\"permanent\"},\"quantity\":{\"type\":\"Literal\",\"value\":1},\"floor\":1} "
  -- A card printing no floor sentence writes none, and 0 is what that means.
  Spec.it s "MkSpeedDecrease, no floor: the key is omitted" $
    Common.assertCodec
      s
      SpeedDecrease.codec
      (SpeedDecrease.MkSpeedDecrease (PlayerRef.Relative PlayerRelation.AnyPlayer) (Quantity.Literal 2) 0)
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SpeedDecrease.codec
