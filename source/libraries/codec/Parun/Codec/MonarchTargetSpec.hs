module Parun.Codec.MonarchTargetSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.MonarchTarget as MonarchTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.MonarchTarget as MonarchTarget
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MonarchTarget" $ do
  Spec.it s "TheController" $
    Common.assertCodec
      s
      MonarchTarget.codec
      MonarchTarget.TheController
      " {\"type\":\"TheController\"} "
  Spec.it s "ControllerOfSource" $
    Common.assertCodec
      s
      MonarchTarget.codec
      MonarchTarget.ControllerOfSource
      " {\"type\":\"ControllerOfSource\"} "
  Spec.it s "InSlot" $
    Common.assertCodec
      s
      MonarchTarget.codec
      (MonarchTarget.InSlot (SlotName.MkSlotName (Text.pack "player")))
      " {\"type\":\"InSlot\",\"value\":\"player\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s MonarchTarget.codec
