{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Counter where

import qualified Parun.Codec.CounterDestination as CounterDestination
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Counter as Counter

-- | Destroy's shape, for Destroy's reason: the bound slot is ELIDED when
-- absent, so a card that says nothing about counting its sweep writes only the
-- @ref@ key. What was a bare slot string is now that key's @InSlot@ (#1507).
codec :: Codec.Codec Counter.Counter
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec Counter.ref
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Counter.slot
  sources <- Fields.defaulted "sources" Nothing (Common.maybe SlotName.codec) Counter.sources
  instead <- Fields.defaulted "instead" Nothing (Common.maybe CounterDestination.codec) Counter.instead
  pure
    Counter.MkCounter
      { Counter.ref = ref,
        Counter.slot = slot,
        Counter.sources = sources,
        Counter.instead = instead
      }
