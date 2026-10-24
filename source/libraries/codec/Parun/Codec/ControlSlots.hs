{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ControlSlots where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControlSlots as ControlSlots

codec :: Codec.Codec ControlSlots.ControlSlots
codec = Fields.object $ do
  first <- Fields.required "first" SlotName.codec ControlSlots.first
  second <- Fields.required "second" SlotName.codec ControlSlots.second
  pure
    ControlSlots.MkControlSlots
      { ControlSlots.first = first,
        ControlSlots.second = second
      }
