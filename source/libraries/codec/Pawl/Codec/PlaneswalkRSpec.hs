module Pawl.Codec.PlaneswalkRSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.PlaneswalkR as PlaneswalkR
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ControllerRelation as ControllerRelation
import qualified Pawl.Types.PlaneswalkCause as PlaneswalkCause
import qualified Pawl.Types.PlaneswalkR as PlaneswalkR
import qualified Pawl.Types.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Pawl.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlaneswalkR" $ do
  -- Susan Foreman's shape: any cause, so the key is elided.
  Spec.it s "any cause" $
    Common.assertCodec
      s
      (PlaneswalkR.codec Common.natural)
      (PlaneswalkR.MkPlaneswalkR (ControllerRelation.Related PlayerRelation.You) Nothing PlaneswalkRewrite.ArrangeTopTwo)
      " {\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"ArrangeTopTwo\"}} "
  -- Fixed Point in Time's shape, with a natural standing in for the effect.
  Spec.it s "a planar die cause" $
    Common.assertCodec
      s
      (PlaneswalkR.codec Common.natural)
      (PlaneswalkR.MkPlaneswalkR (ControllerRelation.Related PlayerRelation.AnyPlayer) (Just PlaneswalkCause.PlanarDie) (PlaneswalkRewrite.RunEffects (Seq.fromList [7])))
      " {\"whose\":{\"type\":\"AnyPlayer\"},\"cause\":{\"type\":\"PlanarDie\"},\"rewrite\":{\"type\":\"RunEffects\",\"value\":[7]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (PlaneswalkR.codec Common.natural)
