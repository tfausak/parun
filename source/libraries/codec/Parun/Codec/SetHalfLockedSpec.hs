module Parun.Codec.SetHalfLockedSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.SetHalfLocked as SetHalfLocked
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.SetHalfLocked as SetHalfLocked
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SetHalfLocked" $ do
  -- CR 709.5g: lock a half of the slot's permanent.
  Spec.it s "MkSetHalfLocked, the lock setting" $
    Common.assertCodec
      s
      SetHalfLocked.codec
      ( SetHalfLocked.MkSetHalfLocked
          { SetHalfLocked.every = False,
            SetHalfLocked.locked = True,
            SetHalfLocked.slot = SlotName.MkSlotName (Text.pack "target")
          }
      )
      " {\"every\":false,\"locked\":true,\"slot\":\"target\"} "
  -- CR 709.5f: and unlock every locked one. Both settings of both keys, since
  -- the wire tells them apart by one key each and a card that wrote the wrong one
  -- reads as the other rule, or as the other quantity.
  Spec.it s "MkSetHalfLocked, the unlock setting" $
    Common.assertCodec
      s
      SetHalfLocked.codec
      ( SetHalfLocked.MkSetHalfLocked
          { SetHalfLocked.every = True,
            SetHalfLocked.locked = False,
            SetHalfLocked.slot = SlotName.MkSlotName (Text.pack "self")
          }
      )
      " {\"every\":true,\"locked\":false,\"slot\":\"self\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SetHalfLocked.codec
