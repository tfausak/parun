{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.VotesReceived where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.VotesReceived as VotesReceived

-- | A bare object keyed by the record's field names. The tag that picks it is
-- Parun.Codec.Quantity's VotesReceived arm.
codec :: Codec.Codec VotesReceived.VotesReceived
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec VotesReceived.slot
  player <- Fields.required "player" PlayerRef.codec VotesReceived.player
  pure VotesReceived.MkVotesReceived {VotesReceived.slot = slot, VotesReceived.player = player}
