{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackRequirement where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.RequiredDefender as RequiredDefender
import qualified Parun.Codec.RequirementArity as RequirementArity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackRequirement as AttackRequirement
import qualified Parun.Types.RequirementArity as RequirementArity

-- | "object", "while" and "arity" are all ordinary defaulted fields, omitted
-- when the card narrows neither axis and means CR 508.1d's own counting -- one
-- requirement per creature the subject names. "while" is spelled exactly as
-- Parun.Codec.BlockPermission spells the same CR 604.2 clause and as
-- Parun.Codec.CombatRestriction spells its opposite, "unless".
--
-- The key is "subject" and not "attacker": CR 508.1d's requirement names the
-- creatures REQUIRED to attack, where CR 509.1c's names the attacker to be
-- blocked. Same shape, opposite axis (Parun.Types.AttackRequirement).
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec AttackRequirement.AttackRequirement
codec = Fields.object $ do
  subject <- Fields.required "subject" Affected.codec AttackRequirement.subject
  object <- Fields.defaulted "object" Nothing (Common.maybe RequiredDefender.codec) AttackRequirement.object
  while <- Fields.defaulted "while" Nothing (Common.maybe Condition.codec) AttackRequirement.while
  arity <- Fields.defaulted "arity" RequirementArity.EachSubject RequirementArity.codec AttackRequirement.arity
  pure
    AttackRequirement.MkAttackRequirement
      { AttackRequirement.subject = subject,
        AttackRequirement.object = object,
        AttackRequirement.while = while,
        AttackRequirement.arity = arity
      }
