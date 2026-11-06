module Parun.Codec.CounterMotionSpec where

import qualified Parun.Codec.CounterMotion as CounterMotion
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterMotion as CounterMotion
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterMotion" $ do
  -- Exemplar of Light's "whenever you put".
  Spec.it s "Put" $
    Common.assertCodec
      s
      CounterMotion.codec
      (CounterMotion.Put PlayerRelation.You)
      " {\"type\":\"Put\",\"value\":\"You\"} "
  Spec.it s "Removed" $
    Common.assertCodec
      s
      CounterMotion.codec
      CounterMotion.Removed
      " {\"type\":\"Removed\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterMotion.codec
