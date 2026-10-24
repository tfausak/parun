{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ForbidBeingBlocked where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ForbidBeingBlocked as ForbidBeingBlocked

-- | A bare object keyed by the record's field names, Parun.Codec.Prohibit's
-- shape. The tag that picks it is written by Parun.Codec.Effect's
-- ForbidBeingBlocked arm.
codec :: Codec.Codec ForbidBeingBlocked.ForbidBeingBlocked
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec ForbidBeingBlocked.duration
  affected <- Fields.required "affected" (Filter.codec Keyword.codec) ForbidBeingBlocked.affected
  blockers <- Fields.required "blockers" (Filter.codec Keyword.codec) ForbidBeingBlocked.blockers
  pure
    ForbidBeingBlocked.MkForbidBeingBlocked
      { ForbidBeingBlocked.duration = duration,
        ForbidBeingBlocked.affected = affected,
        ForbidBeingBlocked.blockers = blockers
      }
