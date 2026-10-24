module Parun.Codec.DieRollRSpec where

import qualified Parun.Codec.DieRollR as DieRollR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DieRollR as DieRollR
import qualified Parun.Types.DieRollRewrite as DieRollRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DieRollR" $ do
  -- CR 706.6: Pixie Guide.
  Spec.it s "MkDieRollR" $
    Common.assertCodec
      s
      DieRollR.codec
      (DieRollR.MkDieRollR (ControllerRelation.Related PlayerRelation.You) DieRollRewrite.ExtraIgnoringLowest)
      " {\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"ExtraIgnoringLowest\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DieRollR.codec
