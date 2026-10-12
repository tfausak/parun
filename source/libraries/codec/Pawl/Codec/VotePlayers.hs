{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.VotePlayers where

import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.VotePlayers as VotePlayers

-- | A bare object keyed by the record's field names. The tag that picks it is
-- Pawl.Codec.VoteChoices' Players arm.
codec :: Codec.Codec VotePlayers.VotePlayers
codec = Fields.object $ do
  another <- Fields.defaulted "another" False Common.boolean VotePlayers.another
  slot <- Fields.required "slot" SlotName.codec VotePlayers.slot
  pure
    VotePlayers.MkVotePlayers
      { VotePlayers.another = another,
        VotePlayers.slot = slot
      }
