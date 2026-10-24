{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Ballot where

import qualified Parun.Codec.BallotChoice as BallotChoice
import qualified Parun.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Ballot as Ballot

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Parun.Codec.Looked is.
codec :: Codec.Codec Ballot.Ballot
codec = Fields.object $ do
  voter <- Fields.required "voter" PlayerId.codec Ballot.voter
  choice <- Fields.required "choice" (BallotChoice.codec ObjectSnapshot.codec) Ballot.choice
  pure
    Ballot.MkBallot
      { Ballot.voter = voter,
        Ballot.choice = choice
      }
