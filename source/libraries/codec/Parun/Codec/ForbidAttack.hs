{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ForbidAttack where

import qualified Parun.Codec.AimedAt as AimedAt
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ForbidAttack as ForbidAttack

-- | A bare object keyed by the record's field names, Parun.Codec.Prohibit's
-- shape with "affected" tagged where that codec's "ref" is bare, and "aimedAt"
-- elided for the restriction on attacking at all. The tag that picks it is
-- written by Parun.Codec.Effect's ForbidAttack arm.
codec :: Codec.Codec ForbidAttack.ForbidAttack
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec ForbidAttack.duration
  affected <- Fields.required "affected" (RestrictedCreatures.codec ObjectRef.codec) ForbidAttack.affected
  aimedAt <- Fields.defaulted "aimedAt" Nothing (Common.maybe AimedAt.codec) ForbidAttack.aimedAt
  pure
    ForbidAttack.MkForbidAttack
      { ForbidAttack.duration = duration,
        ForbidAttack.affected = affected,
        ForbidAttack.aimedAt = aimedAt
      }
