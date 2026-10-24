{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MoveCounters where

import qualified Parun.Codec.MovedKinds as MovedKinds
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MoveCounters as MoveCounters
import qualified Parun.Types.MovedKinds as MovedKinds.Type
import qualified Parun.Types.Quantity as Quantity

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's MoveCounters arm.
--
-- `kinds` defaults to one kind the player picks and a count of one, so the
-- two-key form Agent's Toolkit writes stays the wire spelling of "move a
-- counter" with no kind named. `slot` defaults to Nothing for the same reason:
-- that is what "move a counter" with nothing looking back at it means, so a card
-- that says only that writes neither key.
--
-- Both sides are ObjectRefs, which the type's haddock explains, so the two are
-- spelled the same way on the wire and either may name a group.
codec :: Codec.Codec MoveCounters.MoveCounters
codec = Fields.object $ do
  from <- Fields.required "from" ObjectRef.codec MoveCounters.from
  kinds <- Fields.defaulted "kinds" (MovedKinds.Type.Chosen (Quantity.Literal 1)) MovedKinds.codec MoveCounters.kinds
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) MoveCounters.slot
  to <- Fields.required "to" ObjectRef.codec MoveCounters.to
  pure
    MoveCounters.MkMoveCounters
      { MoveCounters.from = from,
        MoveCounters.kinds = kinds,
        MoveCounters.slot = slot,
        MoveCounters.to = to
      }
