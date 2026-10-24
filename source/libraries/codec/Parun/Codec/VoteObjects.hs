{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.VoteObjects where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.VoteObjects as VoteObjects

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.VoteChoices' Objects arm.
codec :: Codec.Codec VoteObjects.VoteObjects
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) VoteObjects.filter
  slot <- Fields.required "slot" SlotName.codec VoteObjects.slot
  pure
    VoteObjects.MkVoteObjects
      { VoteObjects.filter = filter_,
        VoteObjects.slot = slot
      }
