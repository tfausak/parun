{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Ballot where

import qualified Pawl.Codec.BallotChoice as BallotChoice
import qualified Pawl.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Ballot as Ballot

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Pawl.Codec.Looked is.
codec :: Codec.Codec Ballot.Ballot
codec = Fields.object $ do
  voter <- Fields.required "voter" PlayerId.codec Ballot.voter
  choice <- Fields.required "choice" (BallotChoice.codec ObjectSnapshot.codec) Ballot.choice
  pure
    Ballot.MkBallot
      { Ballot.voter = voter,
        Ballot.choice = choice
      }
