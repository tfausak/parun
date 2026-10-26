module Parun.Codec.ZoneScopeSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ZoneScope as ZoneScope
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.ZoneScope as ZoneScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ZoneScope" $ do
  Spec.it s "Scoped" $
    Common.assertCodec
      s
      ZoneScope.codec
      (ZoneScope.Scoped (PlayerScope.Related PlayerRelation.You))
      " {\"type\":\"Scoped\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "InSlot" $
    Common.assertCodec
      s
      ZoneScope.codec
      (ZoneScope.InSlot (SlotName.MkSlotName (Text.pack "player")))
      " {\"type\":\"InSlot\",\"value\":\"player\"} "
  Spec.it s "ControllerOfBound" $
    Common.assertCodec
      s
      ZoneScope.codec
      (ZoneScope.ControllerOfBound (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"ControllerOfBound\",\"value\":\"target\"} "
  -- Runtime-only for Filter.HeldByPlayer's reason, and round-tripped for
  -- its reason: the codec is total.
  Spec.it s "BoundPlayer" $
    Common.assertCodec
      s
      ZoneScope.codec
      (ZoneScope.BoundPlayer (PlayerId.MkPlayerId 2))
      " {\"type\":\"BoundPlayer\",\"value\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ZoneScope.codec
