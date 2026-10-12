module Pawl.Codec.ConditionalExceptionSpec where

import qualified Data.Set as Set
import qualified Pawl.Codec.ConditionalException as ConditionalException
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.ConditionalException as ConditionalException
import qualified Pawl.Types.CopyException as CopyException
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.WithCounters as WithCounters

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ConditionalException" $ do
  -- CR 707.9e under CR 707.9f: Spark Double's counters, the exceptions key
  -- defaulted away.
  Spec.it s "MkConditionalException, counters alone" $
    Common.assertCodec
      s
      (ConditionalException.codec Common.text)
      (ConditionalException.MkConditionalException (Condition.All []) [] (Just (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1))))
      " {\"condition\":{\"type\":\"All\",\"value\":[]},\"counters\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]} "
  -- CR 707.9b under CR 707.9f: Vizier of Many Faces' colour, the counters key
  -- defaulted away.
  Spec.it s "MkConditionalException, exceptions alone" $
    Common.assertCodec
      s
      (ConditionalException.codec Common.text)
      (ConditionalException.MkConditionalException (Condition.All []) [CopyException.SetColors (Set.singleton Color.White)] Nothing)
      " {\"condition\":{\"type\":\"All\",\"value\":[]},\"exceptions\":[{\"type\":\"SetColors\",\"value\":[{\"type\":\"White\"}]}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (ConditionalException.codec Common.text)
