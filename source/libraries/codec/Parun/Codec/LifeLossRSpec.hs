module Parun.Codec.LifeLossRSpec where

import qualified Parun.Codec.LifeLossR as LifeLossR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.LifeLossR as LifeLossR
import qualified Parun.Types.LifeLossRewrite as LifeLossRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeLossR" $ do
  -- CR 614.1a / 120.4c: Worship.
  Spec.it s "MkLifeLossR" $
    Common.assertCodec
      s
      LifeLossR.codec
      ( LifeLossR.MkLifeLossR
          LifeLossPattern.MkLifeLossPattern
            { LifeLossPattern.whose = ControllerRelation.Related PlayerRelation.You,
              LifeLossPattern.whichCause = Just LifeLossCause.ByDamage
            }
          (LifeLossRewrite.LeaveAtLeast 1)
      )
      " {\"matching\":{\"whose\":{\"type\":\"You\"},\"whichCause\":{\"type\":\"ByDamage\"}},\"rewrite\":{\"type\":\"LeaveAtLeast\",\"value\":1}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeLossR.codec
