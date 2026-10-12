module Pawl.Codec.SelfCountersRemovedSpec where

import qualified Pawl.Codec.SelfCountersRemoved as SelfCountersRemoved
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.SelfCountersRemoved as SelfCountersRemoved

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.SelfCountersRemoved" $ do
  Spec.it s "MkSelfCountersRemoved" $
    Common.assertCodec
      s
      SelfCountersRemoved.codec
      (SelfCountersRemoved.MkSelfCountersRemoved {SelfCountersRemoved.kind = CounterKind.Loyalty})
      " {\"kind\":{\"type\":\"Loyalty\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SelfCountersRemoved.codec
