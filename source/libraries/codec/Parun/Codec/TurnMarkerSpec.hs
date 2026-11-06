module Parun.Codec.TurnMarkerSpec where

import qualified Parun.Codec.TurnMarker as TurnMarker
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TurnMarker as TurnMarker

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnMarker" $ do
  -- CR 807.4b / 807.4e: the second marker, its turn under way, designated for
  -- removal once.
  Spec.it s "a marker under way and designated for removal" $
    Common.assertCodec
      s
      TurnMarker.codec
      TurnMarker.MkTurnMarker
        { TurnMarker.number = 2,
          TurnMarker.holder = PlayerId.MkPlayerId 4,
          TurnMarker.underWay = True,
          TurnMarker.owesTurn = False,
          TurnMarker.removals = 1
        }
      " {\"number\":2,\"holder\":4,\"underWay\":true,\"owesTurn\":false,\"removals\":1} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnMarker.codec
