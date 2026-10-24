module Parun.Codec.CounterRSpec where

import qualified Parun.Codec.CounterR as CounterR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPattern as CounterPattern
import qualified Parun.Types.CounterR as CounterR
import qualified Parun.Types.CounterSubject as CounterSubject
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterR" $ do
  -- CR 614.16: Hardened Scales adds one more +1/+1 counter.
  Spec.it s "MkCounterR" $
    Common.assertCodec
      s
      CounterR.codec
      ( CounterR.MkCounterR
          { CounterR.matching =
              CounterPattern.MkCounterPattern
                { CounterPattern.whichKind = Just CounterKind.PlusOnePlusOne,
                  CounterPattern.subject = CounterSubject.ByAnything,
                  CounterPattern.whose = ControllerRelation.Related PlayerRelation.You,
                  CounterPattern.onWhat = Filter.HasCardType CardType.Creature,
                  CounterPattern.onWho = Nothing
                },
            CounterR.scaling = Scaling.AddMore 1
          }
      )
      " {\"matching\":{\"whichKind\":{\"type\":\"PlusOnePlusOne\"},\"subject\":{\"type\":\"ByAnything\"},\"whose\":{\"type\":\"You\"},\"onWhat\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"scaling\":{\"type\":\"AddMore\",\"value\":1}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterR.codec
