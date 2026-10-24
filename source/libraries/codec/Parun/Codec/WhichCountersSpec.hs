module Parun.Codec.WhichCountersSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.WhichCounters as WhichCounters
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.WhichCounters as WhichCounters

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (WhichCounters.WhichCounters Keyword.Keyword)
codec = WhichCounters.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.WhichCounters" $ do
  Spec.it s "OfKind" $
    Common.assertCodec
      s
      codec
      (WhichCounters.OfKind CounterKind.MinusOneMinusOne)
      " {\"type\":\"OfKind\",\"value\":{\"type\":\"MinusOneMinusOne\"}} "
  Spec.it s "OfAnyKind" $
    Common.assertCodec
      s
      codec
      WhichCounters.OfAnyKind
      " {\"type\":\"OfAnyKind\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
