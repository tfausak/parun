module Parun.Codec.AttackPermissionSpec where

import qualified Parun.Codec.AttackPermission as AttackPermission
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttackPermission as AttackPermission
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackPermission" $ do
  -- Prison Barricade's kicked grant (CR 702.3b): "This creature".
  Spec.it s "MkAttackPermission" $
    Common.assertCodec
      s
      AttackPermission.codec
      (AttackPermission.MkAttackPermission (Affected.Matching Filter.IsSource) Nothing)
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "MkAttackPermission with while" $
    Common.assertCodec
      s
      AttackPermission.codec
      ( AttackPermission.MkAttackPermission
          (Affected.Matching Filter.IsSource)
          (Just (Condition.Compares (Compares.MkCompares (Quantity.IsMonarch (PlayerRef.Relative PlayerRelation.You)) Comparison.AtLeast (Quantity.Literal 1))))
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"while\":{\"type\":\"Compares\",\"value\":{\"comparison\":{\"type\":\"AtLeast\"},\"measured\":{\"type\":\"IsMonarch\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackPermission.codec
