module Parun.Codec.DelayedTriggerSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Parun.Codec.DelayedTrigger as DelayedTrigger
import qualified Parun.Codec.FaceSpec as FaceSpec
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Binding as Binding
import qualified Parun.Types.DelayedTrigger as DelayedTrigger
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.TurnWindow as TurnWindow

-- | MkDelayedTrigger at CR 603.7a/603.7b's default (an unrestricted window and
-- no expiry), plus the case each of those two fields takes when the card does
-- restrict it.
entry :: DelayedTrigger.DelayedTrigger
entry =
  DelayedTrigger.MkDelayedTrigger
    { DelayedTrigger.ability = FaceSpec.minimalTriggeredAbility,
      DelayedTrigger.source = ObjectId.MkObjectId 4,
      DelayedTrigger.controller = PlayerId.MkPlayerId 0,
      DelayedTrigger.bindings = Map.singleton (SlotName.MkSlotName (Text.pack "token")) (Binding.empty {Binding.amount = Just 9}),
      DelayedTrigger.window = TurnWindow.AnyTurn,
      DelayedTrigger.expiry = Nothing,
      DelayedTrigger.createdAt = Timestamp.MkTimestamp 7
    }

entryJson :: String
entryJson =
  "{\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0,"
    <> "\"bindings\":{\"token\":{\"amount\":9}},"
    <> "\"window\":{\"type\":\"AnyTurn\"},\"createdAt\":7}"

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DelayedTrigger" $ do
  Spec.it s "MkDelayedTrigger, CR 603.7a/603.7b's default (armed with no onset gate, no stated duration)" $
    Common.assertJsonCodec s (Codec.encode DelayedTrigger.codec) (Codec.decode DelayedTrigger.codec) entry entryJson
  -- CR 603.7b: a stated duration as the game remembers it
  -- (Parun.Engine.Expiry.arm's output, not the printed Duration).
  Spec.it s "MkDelayedTrigger, a stated expiry (CR 603.7b)" $
    Common.assertCodec
      s
      DelayedTrigger.codec
      entry {DelayedTrigger.expiry = Just Expiry.AtCleanup}
      ( "{\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0,"
          <> "\"bindings\":{\"token\":{\"amount\":9}},"
          <> "\"window\":{\"type\":\"AnyTurn\"},\"expiry\":{\"type\":\"AtCleanup\"},\"createdAt\":7}"
      )
  -- CR 603.7a: an onset gate. Parun.Codec.TurnWindowSpec covers the other arms.
  Spec.it s "MkDelayedTrigger, an onset gate (CR 603.7a)" $
    Common.assertCodec
      s
      DelayedTrigger.codec
      entry {DelayedTrigger.window = TurnWindow.NextTurnOf (PlayerId.MkPlayerId 2)}
      ( "{\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0,"
          <> "\"bindings\":{\"token\":{\"amount\":9}},"
          <> "\"window\":{\"type\":\"NextTurnOf\",\"value\":2},\"createdAt\":7}"
      )
  -- 'bindings' at its default and no stated 'expiry'. 'window' stays a required
  -- key regardless: CR 603.7a's "no restriction" is one of TurnWindow's arms,
  -- not the absence of one.
  Spec.it s "an all-default value omits every optional key" $
    Common.assertCodec
      s
      DelayedTrigger.codec
      DelayedTrigger.MkDelayedTrigger
        { DelayedTrigger.ability = FaceSpec.minimalTriggeredAbility,
          DelayedTrigger.source = ObjectId.MkObjectId 4,
          DelayedTrigger.controller = PlayerId.MkPlayerId 0,
          DelayedTrigger.bindings = Map.empty,
          DelayedTrigger.window = TurnWindow.AnyTurn,
          DelayedTrigger.expiry = Nothing,
          DelayedTrigger.createdAt = Timestamp.MkTimestamp 7
        }
      "{\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0,\"window\":{\"type\":\"AnyTurn\"},\"createdAt\":7}"
