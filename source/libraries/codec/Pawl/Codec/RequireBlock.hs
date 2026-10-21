{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.RequireBlock where

import qualified Pawl.Codec.Duration as Duration
import qualified Pawl.Codec.ObjectRef as ObjectRef
import qualified Pawl.Codec.RequirementArity as RequirementArity
import qualified Pawl.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.RequireBlock as RequireBlock
import qualified Pawl.Types.RequirementArity as RequirementArity

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.Effect's RequireBlock arm. An absent "attacker" names
-- none and an absent "arity" is EachSubject, Pawl.Codec.BlockRequirement's
-- defaults.
codec :: Codec.Codec RequireBlock.RequireBlock
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec RequireBlock.duration
  blocker <- Fields.required "blocker" (RestrictedCreatures.codec ObjectRef.codec) RequireBlock.blocker
  attacker <- Fields.defaulted "attacker" Nothing (Common.maybe (RestrictedCreatures.codec ObjectRef.codec)) RequireBlock.attacker
  arity <- Fields.defaulted "arity" RequirementArity.EachSubject RequirementArity.codec RequireBlock.arity
  pure
    RequireBlock.MkRequireBlock
      { RequireBlock.duration = duration,
        RequireBlock.blocker = blocker,
        RequireBlock.attacker = attacker,
        RequireBlock.arity = arity
      }
