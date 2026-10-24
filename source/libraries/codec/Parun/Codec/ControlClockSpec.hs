module Parun.Codec.ControlClockSpec where

import qualified Parun.Codec.ControlClock as ControlClock
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlClock as ControlClock

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlClock" $ do
  Spec.it s "Gained" $
    Common.assertCodec
      s
      ControlClock.codec
      ControlClock.Gained
      " {\"type\":\"Gained\"} "
  Spec.it s "SinceLastUpkeep" $
    Common.assertCodec
      s
      ControlClock.codec
      ControlClock.SinceLastUpkeep
      " {\"type\":\"SinceLastUpkeep\"} "
  -- Parun.Codec.DamageDirectionSpec's reason: Arm.enum derives the arm list from
  -- the type, so this is what would catch a constructor the derivation missed.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ControlClock.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ControlClock.codec
