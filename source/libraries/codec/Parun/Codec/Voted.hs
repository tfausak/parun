{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Voted where

import qualified Parun.Codec.Ballot as Ballot
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Voted as Voted

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Parun.Codec.Looked is.
codec :: Codec.Codec Voted.Voted
codec = Fields.object $ do
  ballot <- Fields.required "ballot" Ballot.codec Voted.ballot
  audience <- Fields.required "audience" (Common.set PlayerId.codec) Voted.audience
  pure
    Voted.MkVoted
      { Voted.ballot = ballot,
        Voted.audience = audience
      }
