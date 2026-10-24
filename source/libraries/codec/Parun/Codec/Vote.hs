{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Vote where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.VoteChoices as VoteChoices
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Vote as Vote

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Vote arm.
codec :: Codec.Codec Vote.Vote
codec = Fields.object $ do
  starter <- Fields.required "starter" PlayerRef.codec Vote.starter
  choices <- Fields.required "choices" VoteChoices.codec Vote.choices
  secret <- Fields.defaulted "secret" False Common.boolean Vote.secret
  pure
    Vote.MkVote
      { Vote.starter = starter,
        Vote.choices = choices,
        Vote.secret = secret
      }
