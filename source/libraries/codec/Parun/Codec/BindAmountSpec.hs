module Parun.Codec.BindAmountSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.BindAmount as BindAmount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BindAmount as BindAmount
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterName as CounterName
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BindAmount" $ do
  Spec.it s "round-trips" $
    Common.assertCodec
      s
      BindAmount.codec
      (BindAmount.MkBindAmount (Quantity.ObjectCounters (CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "charge")))) (SlotName.MkSlotName (Text.pack "charges")))
      " {\"quantity\":{\"type\":\"ObjectCounters\",\"value\":{\"type\":\"Named\",\"value\":\"charge\"}},\"slot\":\"charges\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BindAmount.codec
