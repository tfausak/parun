{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Mill where

import qualified Parun.Codec.MillTally as MillTally
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Mill as Mill

-- | The tally and the slot are each ELIDED when absent, as Destroy's bound slot
-- is.
codec :: Codec.Codec Mill.Mill
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec Mill.player
  quantity <- Fields.required "quantity" Quantity.codec Mill.quantity
  tally <- Fields.defaulted "tally" Nothing (Common.maybe MillTally.codec) Mill.tally
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Mill.slot
  pure
    Mill.MkMill
      { Mill.player = player,
        Mill.quantity = quantity,
        Mill.tally = tally,
        Mill.slot = slot
      }
