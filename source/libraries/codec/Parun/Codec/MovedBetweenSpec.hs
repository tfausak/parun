module Parun.Codec.MovedBetweenSpec where

import qualified Parun.Codec.MovedBetween as MovedBetween
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.MovedBetween as MovedBetween
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MovedBetween" $ do
  -- BOTH keys are a Zone, so the fixture names them differently on purpose:
  -- only an asymmetric case catches a codec that matched the move backwards.
  Spec.it s "MkMovedBetween, both keys" $
    Common.assertCodec
      s
      MovedBetween.codec
      (MovedBetween.MkMovedBetween {MovedBetween.from = Zone.Battlefield, MovedBetween.to = Zone.Graveyard})
      " {\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s MovedBetween.codec
