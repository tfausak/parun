module Parun.Codec.AttackPermissionSpec where

import qualified Parun.Codec.AttackPermission as AttackPermission
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttackPermission as AttackPermission
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackPermission" $ do
  -- Prison Barricade's kicked grant (CR 702.3b): "This creature".
  Spec.it s "MkAttackPermission" $
    Common.assertCodec
      s
      AttackPermission.codec
      (AttackPermission.MkAttackPermission (Affected.Matching Filter.IsSource))
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackPermission.codec
