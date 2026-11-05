{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecomesTapState where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Batching as Batching.Type
import qualified Parun.Types.BecomesTapState as BecomesTapState

-- | A bare object keyed by the record's field names. The status and the actor
-- are required; EachOccurrence writes no key.
codec :: Codec.Codec BecomesTapState.BecomesTapState
codec = Fields.object $ do
  status <- Fields.required "status" TapState.codec BecomesTapState.status
  actor <- Fields.required "actor" ActingPermanent.codec BecomesTapState.actor
  batching <- Fields.defaulted "batching" Batching.Type.EachOccurrence Batching.codec BecomesTapState.batching
  pure BecomesTapState.MkBecomesTapState {BecomesTapState.status = status, BecomesTapState.actor = actor, BecomesTapState.batching = batching}
