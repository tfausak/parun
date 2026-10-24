module Parun.Codec.PlanarDieRolledSpec where

import qualified Parun.Codec.PlanarDieRolled as PlanarDieRolled
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlanarDieFace as PlanarDieFace
import qualified Parun.Types.PlanarDieRolled as PlanarDieRolled
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlanarDieRolled" $ do
  Spec.it s "keys the roller and the face" $
    Common.assertCodec
      s
      PlanarDieRolled.codec
      (PlanarDieRolled.MkPlanarDieRolled (PlayerId.MkPlayerId 1) PlanarDieFace.Planeswalker)
      " {\"roller\":1,\"face\":{\"type\":\"Planeswalker\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlanarDieRolled.codec
