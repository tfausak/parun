module Parun.Codec.ControlSidesSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ControlSides as ControlSides
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlSides as ControlSides
import qualified Parun.Types.ControlSlots as ControlSlots
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlSides" $ do
  Spec.it s "WithinSlot" $
    Common.assertCodec
      s
      ControlSides.codec
      (ControlSides.WithinSlot (SlotName.MkSlotName (Text.pack "creatures")))
      " {\"type\":\"WithinSlot\",\"value\":\"creatures\"} "
  Spec.it s "WithSource" $
    Common.assertCodec
      s
      ControlSides.codec
      (ControlSides.WithSource (SlotName.MkSlotName (Text.pack "permanent")))
      " {\"type\":\"WithSource\",\"value\":\"permanent\"} "
  Spec.it s "BetweenSlots" $
    Common.assertCodec
      s
      ControlSides.codec
      (ControlSides.BetweenSlots (ControlSlots.MkControlSlots (SlotName.MkSlotName (Text.pack "mine")) (SlotName.MkSlotName (Text.pack "theirs"))))
      " {\"type\":\"BetweenSlots\",\"value\":{\"first\":\"mine\",\"second\":\"theirs\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ControlSides.codec
