module Parun.Codec.ActivationRestriction where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.DuringPhase as DuringPhase
import qualified Parun.Codec.ManaSpecification as ManaSpecification
import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ActivationRestriction as ActivationRestriction

-- | Tagged rather than bare-nullary since CR 500.1's DuringPhase carries a
-- window, CR 102.1's DuringTurn a scope, CR 506.7a's BeforeStep a step and CR
-- 602.5's OnlyIf a condition; the other arms still render as bare tags.
--
-- There is no tag for "no rider": CR 602.2's default is the EMPTY LIST on the
-- ability, which Parun.Codec.ActivatedAbility writes by omitting the key.
codec :: Codec.Codec ActivationRestriction.ActivationRestriction
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "SorcerySpeed" ActivationRestriction.SorcerySpeed,
      Arm.payload "DuringPhase" DuringPhase.codec ActivationRestriction.DuringPhase (\x -> case x of ActivationRestriction.DuringPhase y -> Just y; _ -> Nothing),
      Arm.payload "DuringTurn" TurnScope.codec ActivationRestriction.DuringTurn (\x -> case x of ActivationRestriction.DuringTurn y -> Just y; _ -> Nothing),
      Arm.nullary "AttackedThisStep" ActivationRestriction.AttackedThisStep,
      Arm.nullary "AfterBlockersDeclared" ActivationRestriction.AfterBlockersDeclared,
      Arm.nullary "BeforeCombatDamage" ActivationRestriction.BeforeCombatDamage,
      Arm.payload "BeforeStep" Phase.codec ActivationRestriction.BeforeStep (\x -> case x of ActivationRestriction.BeforeStep y -> Just y; _ -> Nothing),
      Arm.payload "OnlyIf" Condition.codec ActivationRestriction.OnlyIf (\x -> case x of ActivationRestriction.OnlyIf y -> Just y; _ -> Nothing),
      Arm.nullary "OnlyOnce" ActivationRestriction.OnlyOnce,
      Arm.nullary "OnlyOnceEachTurn" ActivationRestriction.OnlyOnceEachTurn,
      Arm.nullary "DuringDieRoll" ActivationRestriction.DuringDieRoll,
      Arm.nullary "InstantSpeed" ActivationRestriction.InstantSpeed,
      Arm.payload "SpendOnly" ManaSpecification.codec ActivationRestriction.SpendOnly (\x -> case x of ActivationRestriction.SpendOnly y -> Just y; _ -> Nothing)
    ]

tagOf :: ActivationRestriction.ActivationRestriction -> String
tagOf x = case x of
  ActivationRestriction.SorcerySpeed {} -> "SorcerySpeed"
  ActivationRestriction.DuringPhase {} -> "DuringPhase"
  ActivationRestriction.DuringTurn {} -> "DuringTurn"
  ActivationRestriction.AttackedThisStep {} -> "AttackedThisStep"
  ActivationRestriction.AfterBlockersDeclared {} -> "AfterBlockersDeclared"
  ActivationRestriction.BeforeCombatDamage {} -> "BeforeCombatDamage"
  ActivationRestriction.BeforeStep {} -> "BeforeStep"
  ActivationRestriction.OnlyIf {} -> "OnlyIf"
  ActivationRestriction.OnlyOnce {} -> "OnlyOnce"
  ActivationRestriction.OnlyOnceEachTurn {} -> "OnlyOnceEachTurn"
  ActivationRestriction.DuringDieRoll {} -> "DuringDieRoll"
  ActivationRestriction.InstantSpeed {} -> "InstantSpeed"
  ActivationRestriction.SpendOnly {} -> "SpendOnly"
