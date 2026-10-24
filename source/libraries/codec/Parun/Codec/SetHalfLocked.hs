{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SetHalfLocked where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SetHalfLocked as SetHalfLocked

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's SetHalfLocked arm.
codec :: Codec.Codec SetHalfLocked.SetHalfLocked
codec = Fields.object $ do
  every <- Fields.required "every" Common.boolean SetHalfLocked.every
  locked <- Fields.required "locked" Common.boolean SetHalfLocked.locked
  slot <- Fields.required "slot" SlotName.codec SetHalfLocked.slot
  pure
    SetHalfLocked.MkSetHalfLocked
      { SetHalfLocked.every = every,
        SetHalfLocked.locked = locked,
        SetHalfLocked.slot = slot
      }
