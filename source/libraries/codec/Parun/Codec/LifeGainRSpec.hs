module Parun.Codec.LifeGainRSpec where

import qualified Parun.Codec.LifeGainR as LifeGainR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.LifeGainR as LifeGainR
import qualified Parun.Types.LifeGainRewrite as LifeGainRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeGainR" $ do
  -- CR 614.1a / 119.10: Boon Reflection.
  Spec.it s "MkLifeGainR" $
    Common.assertCodec
      s
      LifeGainR.codec
      ( LifeGainR.MkLifeGainR
          (ControllerRelation.Related PlayerRelation.You)
          (LifeGainRewrite.Scaled (Scaling.Multiply 2))
      )
      " {\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeGainR.codec
