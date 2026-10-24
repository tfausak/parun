module Parun.Codec.CounterChangeSpec where

import qualified Parun.Codec.CounterChange as CounterChange
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterChange as CounterChange
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterChange" $ do
  -- CR 714.2b's threshold crossing: a Saga going from one lore counter to three
  -- crosses two at once, which neither count alone can say. BEFORE and AFTER are
  -- both a Natural and deliberately differ here -- a symmetric fixture would
  -- round-trip a codec that swapped them.
  Spec.it s "MkCounterChange, every key" $
    Common.assertCodec
      s
      CounterChange.codec
      ( CounterChange.MkCounterChange
          { CounterChange.object = ObjectId.MkObjectId 1,
            CounterChange.kind = CounterKind.Lore,
            CounterChange.before = 1,
            CounterChange.after = 3
          }
      )
      " {\"object\":1,\"kind\":{\"type\":\"Lore\"},\"before\":1,\"after\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterChange.codec
