{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RequireBlock where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.RequirementArity as RequirementArity
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RequireBlock as RequireBlock
import qualified Parun.Types.RequirementArity as RequirementArity

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's RequireBlock arm. An absent "attacker" names
-- none and an absent "arity" is EachSubject, Parun.Codec.BlockRequirement's
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
