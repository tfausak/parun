module Parun.Codec.PreventionRiderSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.PreventionRider as PreventionRider
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PreventionRider" $ do
  -- CR 615.5: the rider's program plus the environment it must resolve in. The
  -- snapshotted target map is what makes "that creature" nameable turns later,
  -- so it is on the wire rather than re-derived -- CR 400.7 has replaced the
  -- installing spell by then.
  Spec.it s "a rider, its snapshotted targets, and who performs it" $
    Common.assertCodec
      s
      PreventionRider.codec
      PreventionRider.MkPreventionRider
        { PreventionRider.effects = Seq.fromList [Effect.Proliferate],
          PreventionRider.targets =
            Map.singleton
              (SlotName.MkSlotName (Text.pack "target"))
              (Set.singleton (Recipient.ToCreature (ObjectId.MkObjectId 4))),
          PreventionRider.controller = PlayerId.MkPlayerId 1,
          PreventionRider.source = ObjectId.MkObjectId 9
        }
      " {\"effects\":[{\"type\":\"Proliferate\"}],\"targets\":{\"target\":[{\"type\":\"ToCreature\",\"value\":4}]},\"controller\":1,\"source\":9} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PreventionRider.codec
