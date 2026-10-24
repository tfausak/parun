module Parun.Codec.ControlMarginSpec where

import qualified Parun.Codec.ControlMargin as ControlMargin
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlMargin as ControlMargin

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlMargin" $ do
  Spec.it s "AtLeast" $
    Common.assertCodec s ControlMargin.codec (ControlMargin.AtLeast 1) " {\"type\":\"AtLeast\",\"value\":1} "
  Spec.it s "MoreThanYou" $
    Common.assertCodec s ControlMargin.codec (ControlMargin.MoreThanYou 2) " {\"type\":\"MoreThanYou\",\"value\":2} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ControlMargin.codec
