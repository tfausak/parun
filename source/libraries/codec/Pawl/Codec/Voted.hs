{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Voted where

import qualified Pawl.Codec.Ballot as Ballot
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Voted as Voted

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Pawl.Codec.Looked is.
codec :: Codec.Codec Voted.Voted
codec = Fields.object $ do
  ballot <- Fields.required "ballot" Ballot.codec Voted.ballot
  audience <- Fields.required "audience" (Common.set PlayerId.codec) Voted.audience
  pure
    Voted.MkVoted
      { Voted.ballot = ballot,
        Voted.audience = audience
      }
