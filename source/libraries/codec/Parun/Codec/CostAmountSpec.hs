module Parun.Codec.CostAmountSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CostAmount as CostAmount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostAmount" $ do
  Spec.it s "Fixed" $
    Common.assertCodec
      s
      CostAmount.codec
      (CostAmount.Fixed 3)
      " {\"type\":\"Fixed\",\"value\":3} "
  Spec.it s "Announced" $
    Common.assertCodec
      s
      CostAmount.codec
      (CostAmount.Announced (SlotName.MkSlotName (Text.pack "X")))
      " {\"type\":\"Announced\",\"value\":\"X\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CostAmount.codec
