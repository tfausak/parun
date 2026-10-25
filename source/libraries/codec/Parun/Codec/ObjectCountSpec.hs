module Parun.Codec.ObjectCountSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ObjectCount as ObjectCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ObjectCount" $ do
  Spec.it s "Fixed" $
    Common.assertCodec
      s
      ObjectCount.codec
      (ObjectCount.Exactly (CostAmount.Fixed 2))
      " {\"type\":\"Fixed\",\"value\":2} "
  Spec.it s "Announced" $
    Common.assertCodec
      s
      ObjectCount.codec
      (ObjectCount.Exactly (CostAmount.Announced (SlotName.MkSlotName (Text.pack "x"))))
      " {\"type\":\"Announced\",\"value\":\"x\"} "
  Spec.it s "Every" $
    Common.assertCodec
      s
      ObjectCount.codec
      ObjectCount.Every
      " {\"type\":\"Every\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ObjectCount.codec
