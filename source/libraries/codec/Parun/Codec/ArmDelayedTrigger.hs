{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ArmDelayedTrigger where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Onset as Onset
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.Onset as Onset

-- | A bare object keyed by the record's field names, with both halves of the
-- envelope defaulted, so a one-shot arming writes only its @name@.
--
-- The positional payload this replaces was THREE shapes told apart by LENGTH --
-- a bare name, a name-and-duration pair, and a name-onset-duration triple --
-- because an onset and a duration are both tagged objects and JSON type could
-- not separate them. Two independently elided keys say the same thing without
-- the arity puzzle: a stated duration alone and a stated onset alone are each
-- just the one key.
--
-- The carried `ability` is elided the same way, so an arm naming its card's
-- declaration writes nothing more than it did.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (ArmDelayedTrigger.ArmDelayedTrigger ability)
codec abilityCodec = Fields.object $ do
  name <- Fields.required "name" AbilityName.codec ArmDelayedTrigger.name
  onset <- Fields.defaulted "onset" Onset.Immediately Onset.codec ArmDelayedTrigger.onset
  duration <- Fields.defaulted "duration" Nothing (Common.maybe Duration.codec) ArmDelayedTrigger.duration
  ability <- Fields.defaulted "ability" Nothing (Common.maybe abilityCodec) ArmDelayedTrigger.ability
  pure
    ArmDelayedTrigger.MkArmDelayedTrigger
      { ArmDelayedTrigger.name = name,
        ArmDelayedTrigger.onset = onset,
        ArmDelayedTrigger.duration = duration,
        ArmDelayedTrigger.ability = ability
      }
