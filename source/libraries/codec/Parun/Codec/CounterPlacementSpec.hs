module Parun.Codec.CounterPlacementSpec where

import qualified Parun.Codec.CounterPlacement as CounterPlacement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPlacement as CounterPlacement
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterPlacement" $ do
  -- CR 603.2c's batch placement: a counter kind and the permanents it counts on,
  -- which is what "one or more -1/-1 counters are put on one or more creatures"
  -- names.
  Spec.it s "MkCounterPlacement, both keys" $
    Common.assertCodec
      s
      CounterPlacement.codec
      ( CounterPlacement.MkCounterPlacement
          { CounterPlacement.kind = CounterKind.MinusOneMinusOne,
            CounterPlacement.permanents = Filter.HasCardType CardType.Creature,
            CounterPlacement.putter = PlayerRelation.AnyPlayer
          }
      )
      " {\"kind\":{\"type\":\"MinusOneMinusOne\"},\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- "Whenever you put": the relation narrows, so it writes its key.
  Spec.it s "MkCounterPlacement, a putter" $
    Common.assertCodec
      s
      CounterPlacement.codec
      ( CounterPlacement.MkCounterPlacement
          { CounterPlacement.kind = CounterKind.PlusOnePlusOne,
            CounterPlacement.permanents = Filter.IsSource,
            CounterPlacement.putter = PlayerRelation.You
          }
      )
      " {\"kind\":{\"type\":\"PlusOnePlusOne\"},\"permanents\":{\"type\":\"IsSource\"},\"putter\":{\"type\":\"You\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterPlacement.codec
