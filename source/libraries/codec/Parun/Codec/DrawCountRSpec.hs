module Parun.Codec.DrawCountRSpec where

import qualified Parun.Codec.DrawCountR as DrawCountR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DrawCountR as DrawCountR
import qualified Parun.Types.DrawCountRewrite as DrawCountRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawCountR" $ do
  -- CR 121.2a: Alms Collector.
  Spec.it s "MkDrawCountR" $
    Common.assertCodec
      s
      DrawCountR.codec
      (DrawCountR.MkDrawCountR (ControllerRelation.Related PlayerRelation.Opponent) 2 DrawCountRewrite.EachDrawOne)
      " {\"whose\":{\"type\":\"Opponent\"},\"atLeast\":2,\"rewrite\":{\"type\":\"EachDrawOne\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DrawCountR.codec
