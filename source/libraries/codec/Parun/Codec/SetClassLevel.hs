{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SetClassLevel where

import qualified Parun.Codec.ClassLevel as ClassLevel
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SetClassLevel as SetClassLevel

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's SetClassLevel arm.
codec :: Codec.Codec SetClassLevel.SetClassLevel
codec = Fields.object $ do
  level <- Fields.required "level" ClassLevel.codec SetClassLevel.level
  slot <- Fields.required "slot" SlotName.codec SetClassLevel.slot
  pure
    SetClassLevel.MkSetClassLevel
      { SetClassLevel.level = level,
        SetClassLevel.slot = slot
      }
