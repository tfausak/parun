{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ControlPlayer where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControlPlayer as ControlPlayer

-- | An object keyed by the record's field names, with rule 723.7's restriction
-- elided when it is absent.
codec :: Codec.Codec ControlPlayer.ControlPlayer
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec ControlPlayer.slot
  manaFromLandsOnly <- Fields.defaulted "manaFromLandsOnly" False Common.boolean ControlPlayer.manaFromLandsOnly
  pure
    ControlPlayer.MkControlPlayer
      { ControlPlayer.slot = slot,
        ControlPlayer.manaFromLandsOnly = manaFromLandsOnly
      }
