module Parun.Codec.SelfCountersRemovedSpec where

import qualified Parun.Codec.SelfCountersRemoved as SelfCountersRemoved
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.SelfCountersRemoved as SelfCountersRemoved

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SelfCountersRemoved" $ do
  Spec.it s "MkSelfCountersRemoved" $
    Common.assertCodec
      s
      SelfCountersRemoved.codec
      (SelfCountersRemoved.MkSelfCountersRemoved {SelfCountersRemoved.kind = CounterKind.Loyalty})
      " {\"kind\":{\"type\":\"Loyalty\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SelfCountersRemoved.codec
