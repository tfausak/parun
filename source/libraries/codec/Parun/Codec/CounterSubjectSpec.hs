module Parun.Codec.CounterSubjectSpec where

import qualified Parun.Codec.CounterSubject as CounterSubject
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.CounterSubject as CounterSubject
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterSubject" $ do
  Spec.it s "ByEffect (Doubling Season)" $
    Common.assertCodec
      s
      CounterSubject.codec
      CounterSubject.ByEffect
      " {\"type\":\"ByEffect\"} "
  Spec.it s "ByPlayer (Vorinclex, Monstrous Raider)" $
    Common.assertCodec
      s
      CounterSubject.codec
      (CounterSubject.ByPlayer (ControllerRelation.Related PlayerRelation.Opponent))
      " {\"type\":\"ByPlayer\",\"value\":{\"type\":\"Opponent\"}} "
  Spec.it s "ByAnything (Hardened Scales)" $
    Common.assertCodec
      s
      CounterSubject.codec
      CounterSubject.ByAnything
      " {\"type\":\"ByAnything\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CounterSubject.codec
