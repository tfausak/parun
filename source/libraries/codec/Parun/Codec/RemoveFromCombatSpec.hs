module Parun.Codec.RemoveFromCombatSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.RemoveFromCombat as RemoveFromCombat
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RemoveFromCombat as RemoveFromCombat
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Unblocking as Unblocking

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RemoveFromCombat" $ do
  Spec.it s "omits a stay-blocked removal's unblocking" $
    Common.assertCodec
      s
      RemoveFromCombat.codec
      (RemoveFromCombat.MkRemoveFromCombat (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) Unblocking.StayBlocked)
      " {\"removed\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "SoleBlockedUnblocked" $
    Common.assertCodec
      s
      RemoveFromCombat.codec
      (RemoveFromCombat.MkRemoveFromCombat (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) Unblocking.SoleBlockedUnblocked)
      " {\"removed\":{\"type\":\"InSlot\",\"value\":\"target\"},\"unblocking\":\"SoleBlockedUnblocked\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RemoveFromCombat.codec
