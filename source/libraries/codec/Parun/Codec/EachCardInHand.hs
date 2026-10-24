{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EachCardInHand where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ZoneScope as ZoneScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EachCardInHand as EachCardInHand

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.ObjectRef's EachCardInHand arm.
--
-- @filter@ is omitted when absent, where Parun.Codec.EachCardInGraveyard's is
-- required: the whole hand is the commoner of the two readings -- Amnesia's
-- reveal takes it -- so the shorter spelling is the unfiltered one.
codec :: Codec.Codec EachCardInHand.EachCardInHand
codec = Fields.object $ do
  hands <- Fields.required "hands" ZoneScope.codec EachCardInHand.hands
  filter_ <- Fields.defaulted "filter" Nothing (Common.maybe (Filter.codec Keyword.codec)) EachCardInHand.filter
  pure
    EachCardInHand.MkEachCardInHand
      { EachCardInHand.hands = hands,
        EachCardInHand.filter = filter_
      }
