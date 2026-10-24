{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Replace where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ReplacementEffect as ReplacementEffect
import qualified Parun.Codec.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Codec.Uses as Uses
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Replace as Replace

-- | A bare object keyed by the record's field names. The positional payload this
-- replaces wrote the unconditional case as an explicit null in the fourth slot;
-- 'Fields.defaulted' elides it instead, which is the posture every other
-- optional rider in the DSL already takes.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.DamageR gives.
codec ::
  (Typeable.Typeable card, Eq card, Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec card ->
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (Replace.Replace card ability effect)
codec cardCodec abilityCodec effectCodec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec Replace.duration
  uses <- Fields.required "uses" Uses.codec Replace.uses
  origin <- Fields.required "origin" ReplacementOrigin.codec Replace.origin
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) Replace.condition
  effect <- Fields.required "effect" (ReplacementEffect.codec cardCodec abilityCodec effectCodec) Replace.effect
  pure
    Replace.MkReplace
      { Replace.duration = duration,
        Replace.uses = uses,
        Replace.origin = origin,
        Replace.condition = condition,
        Replace.effect = effect
      }
