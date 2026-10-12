{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.VotesReceived where

import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.VotesReceived as VotesReceived

-- | A bare object keyed by the record's field names. The tag that picks it is
-- Pawl.Codec.Quantity's VotesReceived arm.
codec :: Codec.Codec VotesReceived.VotesReceived
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec VotesReceived.slot
  player <- Fields.required "player" PlayerRef.codec VotesReceived.player
  pure VotesReceived.MkVotesReceived {VotesReceived.slot = slot, VotesReceived.player = player}
