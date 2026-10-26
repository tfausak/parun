{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecomesTapState where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecomesTapState as BecomesTapState

-- | A bare object keyed by the record's field names. Both keys are required.
codec :: Codec.Codec BecomesTapState.BecomesTapState
codec = Fields.object $ do
  status <- Fields.required "status" TapState.codec BecomesTapState.status
  actor <- Fields.required "actor" ActingPermanent.codec BecomesTapState.actor
  pure BecomesTapState.MkBecomesTapState {BecomesTapState.status = status, BecomesTapState.actor = actor}
