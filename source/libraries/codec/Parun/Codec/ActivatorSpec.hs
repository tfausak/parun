module Parun.Codec.ActivatorSpec where

import qualified Parun.Codec.Activator as Activator
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Activator" $ do
  Spec.it s "the default" $
    Common.assertCodec
      s
      Activator.codec
      (Activator.Related PlayerRelation.You)
      " {\"type\":\"You\"} "
  Spec.it s "AnyPlayer" $
    Common.assertCodec
      s
      Activator.codec
      (Activator.Related PlayerRelation.AnyPlayer)
      " {\"type\":\"AnyPlayer\"} "
  Spec.it s "Opponent" $
    Common.assertCodec
      s
      Activator.codec
      (Activator.Related PlayerRelation.Opponent)
      " {\"type\":\"Opponent\"} "
  Spec.it s "Owner" $
    Common.assertCodec
      s
      Activator.codec
      Activator.Owner
      " {\"type\":\"Owner\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Activator.codec
