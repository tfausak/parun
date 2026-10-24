module Parun.Codec.VentureMarkerEnteredSpec where

import qualified Parun.Codec.VentureMarkerEntered as VentureMarkerEntered
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RoomIndex as RoomIndex
import qualified Parun.Types.VentureMarkerEntered as VentureMarkerEntered

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.VentureMarkerEntered" $ do
  -- CR 309.4c. The dungeon's id is carried because a room index alone names
  -- nothing.
  Spec.it s "MkVentureMarkerEntered, every key" $
    Common.assertCodec
      s
      VentureMarkerEntered.codec
      ( VentureMarkerEntered.MkVentureMarkerEntered
          { VentureMarkerEntered.player = PlayerId.MkPlayerId 0,
            VentureMarkerEntered.dungeon = ObjectId.MkObjectId 1,
            VentureMarkerEntered.room = RoomIndex.topmost
          }
      )
      " {\"player\":0,\"dungeon\":1,\"room\":0} "
  Spec.it s "has a schema" $ Common.assertHasSchema s VentureMarkerEntered.codec
