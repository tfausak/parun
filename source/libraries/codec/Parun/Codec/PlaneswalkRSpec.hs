module Parun.Codec.PlaneswalkRSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.PlaneswalkR as PlaneswalkR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.PlaneswalkCause as PlaneswalkCause
import qualified Parun.Types.PlaneswalkR as PlaneswalkR
import qualified Parun.Types.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlaneswalkR" $ do
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
