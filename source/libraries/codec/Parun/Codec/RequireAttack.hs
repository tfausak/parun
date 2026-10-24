{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RequireAttack where

import qualified Parun.Codec.AttackTargetRef as AttackTargetRef
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RequireAttack as RequireAttack

-- | A bare object keyed by the record's field names, Parun.Codec.RequireBlock's
-- shape on the other side of the combat phase. The tag that picks it is written
-- by Parun.Codec.Effect's RequireAttack arm. An absent "defender" names none.
codec :: Codec.Codec RequireAttack.RequireAttack
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec RequireAttack.duration
  attacker <- Fields.required "attacker" (RestrictedCreatures.codec ObjectRef.codec) RequireAttack.attacker
  defender <- Fields.defaulted "defender" Nothing (Common.maybe AttackTargetRef.codec) RequireAttack.defender
  pure
    RequireAttack.MkRequireAttack
      { RequireAttack.duration = duration,
        RequireAttack.attacker = attacker,
        RequireAttack.defender = defender
      }
