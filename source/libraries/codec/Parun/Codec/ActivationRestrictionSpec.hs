module Parun.Codec.ActivationRestrictionSpec where

import qualified Parun.Codec.ActivationRestriction as ActivationRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.DuringPhase as DuringPhase
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActivationRestriction" $ do
  Spec.it s "SorcerySpeed" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.SorcerySpeed
      " {\"type\":\"SorcerySpeed\"} "
  -- A stepped window (CR 511.1) beside a phase one (CR 500.1):
  -- Parun.Types.PhaseSelector spans both, so the arm has to carry both.
  Spec.it s "DuringPhase, Desert's end-of-combat rider" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ( ActivationRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.Step (Phase.Combat CombatStep.EndOfCombat),
              DuringPhase.scope = TurnScope.EachTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"Step\",\"value\":{\"type\":\"Combat\",\"value\":{\"type\":\"EndOfCombat\"}}},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- The arm's second axis: the SAME window under each scope, so a codec that
  -- dropped the scope would collapse this and the previous case into one.
  Spec.it s "DuringPhase, Llanowar Augur's controller's-turn upkeep" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ( ActivationRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep),
              DuringPhase.scope = TurnScope.ControllersTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}}},\"scope\":{\"type\":\"ControllersTurn\"}}} "
  -- The PhaseSelector's stepless arm: a phase that HAS steps, named whole.
  Spec.it s "DuringPhase, Jade Statue's combat-phase rider" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ( ActivationRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.CombatPhase,
              DuringPhase.scope = TurnScope.EachTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"CombatPhase\"},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- CR 102.1 with no window beside it, which is the arm DuringPhase above cannot
  -- reach: Lavinia, Foil to Conspiracy's "Activate only during an opponent's
  -- turn". Rendered payload-tagged, so a decoder cannot confuse it with the
  -- windowed arm.
  Spec.it s "DuringTurn, Lavinia's opponent's-turn rider" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      (ActivationRestriction.DuringTurn TurnScope.OpponentsTurn)
      " {\"type\":\"DuringTurn\",\"value\":{\"type\":\"OpponentsTurn\"}} "
  -- CR 602.5's second clause, and the arm that made this type a list: Kongming's
  -- Contraptions prints it beside the DuringPhase above.
  Spec.it s "AttackedThisStep" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.AttackedThisStep
      " {\"type\":\"AttackedThisStep\"} "
  -- Trap Runner's "activate only during combat after blockers are declared"
  -- (CR 506.7b through CR 506.7g).
  Spec.it s "AfterBlockersDeclared" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.AfterBlockersDeclared
      " {\"type\":\"AfterBlockersDeclared\"} "
  -- Save Point's "activate only during combat before combat damage has been
  -- dealt" (CR 506.7 through CR 506.7g).
  Spec.it s "BeforeCombatDamage" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.BeforeCombatDamage
      " {\"type\":\"BeforeCombatDamage\"} "
  -- Capricious Sorcerer's "before attackers are declared" (CR 506.7a).
  Spec.it s "BeforeStep" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      (ActivationRestriction.BeforeStep (Phase.Combat CombatStep.DeclareAttackers))
      " {\"type\":\"BeforeStep\",\"value\":{\"type\":\"Combat\",\"value\":{\"type\":\"DeclareAttackers\"}}} "
  -- CR 602.5 over a fact about the board rather than a window: Barbarian Ring's
  -- "Activate only if there are seven or more cards in your graveyard".
  Spec.it s "OnlyIf, Barbarian Ring's threshold rider" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ( ActivationRestriction.OnlyIf
          ( Condition.Compares
              Compares.MkCompares
                { Compares.measured =
                    Quantity.Count
                      Count.MkCount
                        { Count.aggregation = Aggregation.Members,
                          Count.filter = Filter.And [],
                          Count.scope = Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You))
                        },
                  Compares.comparison = Comparison.AtLeast,
                  Compares.threshold = Quantity.Literal 7
                }
          )
      )
      " {\"type\":\"OnlyIf\",\"value\":{\"type\":\"Compares\",\"value\":{\"comparison\":{\"type\":\"AtLeast\"},\"measured\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[]},\"scope\":{\"type\":\"InZone\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"zone\":{\"type\":\"Graveyard\"}}}}},\"threshold\":{\"type\":\"Literal\",\"value\":7}}}} "
  -- CR 602.5b's counted rider, which CR 702.177a's exhaust rewrites into:
  -- Greenbelt Guardian's "Activate only once".
  Spec.it s "OnlyOnce" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.OnlyOnce
      " {\"type\":\"OnlyOnce\"} "
  -- CR 602.5b's own example, the same rider timed per turn: Locust Swarm's
  -- "Activate only once each turn".
  Spec.it s "OnlyOnceEachTurn" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.OnlyOnceEachTurn
      " {\"type\":\"OnlyOnceEachTurn\"} "
  -- Goblin Bookie's "Activate only any time it makes sense".
  Spec.it s "DuringDieRoll" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.DuringDieRoll
      " {\"type\":\"DuringDieRoll\"} "
  -- Rhystic Cave's "Activate only as an instant".
  Spec.it s "InstantSpeed" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      ActivationRestriction.InstantSpeed
      " {\"type\":\"InstantSpeed\"} "
  Spec.it s "SpendOnly" $
    Common.assertCodec
      s
      ActivationRestriction.codec
      (ActivationRestriction.SpendOnly ManaSpecification.ChosenColor)
      " {\"type\":\"SpendOnly\",\"value\":{\"type\":\"ChosenColor\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ActivationRestriction.codec
