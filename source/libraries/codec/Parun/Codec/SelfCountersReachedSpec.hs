module Parun.Codec.SelfCountersReachedSpec where

import qualified Parun.Codec.SelfCountersReached as SelfCountersReached
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.SelfCountersReached as SelfCountersReached

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SelfCountersReached" $ do
  -- CR 714.2's chapter trigger: a lore counter count, which is what a Saga's
  -- third chapter watches for.
  Spec.it s "MkSelfCountersReached, both keys" $
    Common.assertCodec
      s
      SelfCountersReached.codec
      ( SelfCountersReached.MkSelfCountersReached
          { SelfCountersReached.kind = CounterKind.Lore,
            SelfCountersReached.amount = 3
          }
      )
      " {\"kind\":{\"type\":\"Lore\"},\"amount\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SelfCountersReached.codec
