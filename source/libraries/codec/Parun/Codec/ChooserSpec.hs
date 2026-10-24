module Parun.Codec.ChooserSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Chooser as Chooser
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Chooser as Chooser
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Chooser" $ do
  Spec.it s "TheController" $
    Common.assertCodec
      s
      Chooser.codec
      Chooser.TheController
      " {\"type\":\"TheController\"} "
  Spec.it s "EachInScope" $
    Common.assertCodec
      s
      Chooser.codec
      Chooser.EachInScope
      " {\"type\":\"EachInScope\"} "
  Spec.it s "BoundInSlot" $
    Common.assertCodec
      s
      Chooser.codec
      (Chooser.BoundInSlot (SlotName.MkSlotName (Text.pack "opponent")))
      " {\"type\":\"BoundInSlot\",\"value\":\"opponent\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Chooser.codec
