{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StaticAbility where

import qualified Data.Set as Set
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AbilityName as AbilityNameCodec
import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Modification as Modification
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StaticAbility as StaticAbility

-- | CR 613.6: the parts of one ability's effect travel together, so the wire
-- format is one affected set and an ARRAY of modifications -- never one entry
-- per layer.
--
-- The CR 604.2 "as long as" gate is OPTIONAL, and absent means unconditional:
-- every card written before it existed encodes byte-for-byte as it did. The CR
-- 604.2 override beside it -- "if this leaves the battlefield, this effect
-- continues until end of turn" -- is optional for the same reason, and absent
-- means the effect ends with its permanent.
--
-- CR 113.6b's zone clause is optional and defaults to EMPTY, which is the
-- ability stating no zone at all: every card written before the field existed
-- encodes byte-for-byte as it did. CR 613.1f's name is optional too.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
--
-- Takes the granted-ability codec rather than building it, for the reason
-- Parun.Types.StaticAbility is parametric: Parun.Codec.GrantedAbility calls this.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (StaticAbility.StaticAbility ability)
codec abilityCodec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec StaticAbility.affected
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) StaticAbility.condition
  functionsFrom <- Fields.defaulted "functionsFrom" Set.empty (Common.set Zone.codec) StaticAbility.functionsFrom
  lingers <- Fields.defaulted "lingers" Nothing (Common.maybe Duration.codec) StaticAbility.lingers
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityNameCodec.codec) StaticAbility.name
  modifications <- Fields.required "modifications" (Common.nonEmpty (Modification.codec abilityCodec)) StaticAbility.modifications
  pure
    StaticAbility.MkStaticAbility
      { StaticAbility.affected = affected,
        StaticAbility.condition = condition,
        StaticAbility.functionsFrom = functionsFrom,
        StaticAbility.lingers = lingers,
        StaticAbility.name = name,
        StaticAbility.modifications = modifications
      }
