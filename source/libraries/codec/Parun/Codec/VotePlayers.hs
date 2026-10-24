{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.VotePlayers where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.VotePlayers as VotePlayers

-- | A bare object keyed by the record's field names. The tag that picks it is
-- Parun.Codec.VoteChoices' Players arm.
codec :: Codec.Codec VotePlayers.VotePlayers
codec = Fields.object $ do
  another <- Fields.defaulted "another" False Common.boolean VotePlayers.another
  slot <- Fields.required "slot" SlotName.codec VotePlayers.slot
  pure
    VotePlayers.MkVotePlayers
      { VotePlayers.another = another,
        VotePlayers.slot = slot
      }
