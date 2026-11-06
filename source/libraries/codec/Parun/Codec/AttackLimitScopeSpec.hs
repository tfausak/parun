module Parun.Codec.AttackLimitScopeSpec where

import qualified Parun.Codec.AttackLimitScope as AttackLimitScope
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackLimitScope as AttackLimitScope
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackLimitScope" $ do
  Spec.it s "Players" $
    Common.assertCodec
      s
      AttackLimitScope.codec
      (AttackLimitScope.Players (PlayerScope.Related PlayerRelation.You))
      " {\"type\":\"Players\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "Source" $
    Common.assertCodec
      s
      AttackLimitScope.codec
      AttackLimitScope.Source
      " {\"type\":\"Source\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackLimitScope.codec
