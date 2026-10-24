module Parun.Codec.LifeLossPatternSpec where

import qualified Parun.Codec.LifeLossPattern as LifeLossPattern
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeLossPattern" $ do
  -- Worship: "your life total", "damage that would reduce" it.
  Spec.it s "MkLifeLossPattern" $
    Common.assertCodec
      s
      LifeLossPattern.codec
      LifeLossPattern.MkLifeLossPattern
        { LifeLossPattern.whose = ControllerRelation.Related PlayerRelation.You,
          LifeLossPattern.whichCause = Just LifeLossCause.ByDamage
        }
      " {\"whose\":{\"type\":\"You\"},\"whichCause\":{\"type\":\"ByDamage\"}} "
  -- CR 109.5: Related AnyPlayer is what a pattern that says nothing about the controller
  -- means, and Nothing what one that says nothing about the cause does, so both
  -- keys are omitted.
  Spec.it s "an all-default value omits every optional key" $
    Common.assertCodec
      s
      LifeLossPattern.codec
      LifeLossPattern.MkLifeLossPattern
        { LifeLossPattern.whose = ControllerRelation.Related PlayerRelation.AnyPlayer,
          LifeLossPattern.whichCause = Nothing
        }
      " {} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeLossPattern.codec
