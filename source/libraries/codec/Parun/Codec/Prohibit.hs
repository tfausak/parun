{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Prohibit where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Prohibition as Prohibition
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Prohibit as Prohibit

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Prohibit arm.
codec :: Codec.Codec Prohibit.Prohibit
codec = Fields.object $ do
  what <- Fields.required "what" Prohibition.codec Prohibit.what
  duration <- Fields.required "duration" Duration.codec Prohibit.duration
  affected <- Fields.required "affected" (RestrictedCreatures.codec ObjectRef.codec) Prohibit.affected
  pure
    Prohibit.MkProhibit
      { Prohibit.what = what,
        Prohibit.duration = duration,
        Prohibit.affected = affected
      }
