module Parun.Codec.CastingRestrictionSpec where

import qualified Parun.Codec.CastingRestriction as CastingRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastingRestriction as CastingRestriction
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.DuringPhase as DuringPhase
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastingRestriction" $ do
  -- Rally the Troops' "only during the declare attackers step" (CR 500.1), cast
  -- by the DEFENDING player, so its scope is every turn.
  Spec.it s "DuringPhase, Rally the Troops' declare attackers step on any turn" $
    Common.assertCodec
      s
      CastingRestriction.codec
      ( CastingRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.Step (Phase.Combat CombatStep.DeclareAttackers),
              DuringPhase.scope = TurnScope.EachTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"Step\",\"value\":{\"type\":\"Combat\",\"value\":{\"type\":\"DeclareAttackers\"}}},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- Necrologia's "only during your end step" (CR 512.1, CR 109.5): a different
  -- window AND a different scope, so neither key is defaulted past.
  Spec.it s "DuringPhase, Necrologia's own end step" $
    Common.assertCodec
      s
      CastingRestriction.codec
      ( CastingRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.Step (Phase.Ending EndingStep.EndStep),
              DuringPhase.scope = TurnScope.ControllersTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"Step\",\"value\":{\"type\":\"Ending\",\"value\":{\"type\":\"EndStep\"}}},\"scope\":{\"type\":\"ControllersTurn\"}}} "
  -- The third scope, and a whole-phase window: no card prints it on a CAST yet,
  -- so this is the codec's own coverage of the axis the arm gained.
  Spec.it s "DuringPhase, a whole-phase window on an opponent's turn" $
    Common.assertCodec
      s
      CastingRestriction.codec
      ( CastingRestriction.DuringPhase
          DuringPhase.MkDuringPhase
            { DuringPhase.window = PhaseSelector.CombatPhase,
              DuringPhase.scope = TurnScope.OpponentsTurn
            }
      )
      " {\"type\":\"DuringPhase\",\"value\":{\"window\":{\"type\":\"CombatPhase\"},\"scope\":{\"type\":\"OpponentsTurn\"}}} "
  -- Siren's Call's "during an opponent's turn" (CR 102.1).
  Spec.it s "DuringTurn" $
    Common.assertCodec
      s
      CastingRestriction.codec
      (CastingRestriction.DuringTurn TurnScope.OpponentsTurn)
      " {\"type\":\"DuringTurn\",\"value\":{\"type\":\"OpponentsTurn\"}} "
  -- Serra Avenger's "your first, second, or third turns of the game" (CR 500.7).
  Spec.it s "NotDuringFirstTurns" $
    Common.assertCodec
      s
      CastingRestriction.codec
      (CastingRestriction.NotDuringFirstTurns 3)
      " {\"type\":\"NotDuringFirstTurns\",\"value\":3} "
  Spec.it s "AttackedThisStep" $
    Common.assertCodec
      s
      CastingRestriction.codec
      CastingRestriction.AttackedThisStep
      " {\"type\":\"AttackedThisStep\"} "
  -- Curtain of Light's "only during combat after blockers are declared"
  -- (CR 506.7b).
  Spec.it s "AfterBlockersDeclared" $
    Common.assertCodec
      s
      CastingRestriction.codec
      CastingRestriction.AfterBlockersDeclared
      " {\"type\":\"AfterBlockersDeclared\"} "
  -- Blood Frenzy's "only before the combat damage step" (CR 506.7a, 506.7d).
  Spec.it s "BeforeStep" $
    Common.assertCodec
      s
      CastingRestriction.codec
      (CastingRestriction.BeforeStep (Phase.Combat CombatStep.CombatDamage))
      " {\"type\":\"BeforeStep\",\"value\":{\"type\":\"Combat\",\"value\":{\"type\":\"CombatDamage\"}}} "
  -- Consume Spirit's "Spend only black mana on X" (CR 601.2h).
  Spec.it s "SpendOnlyOnX" $
    Common.assertCodec
      s
      CastingRestriction.codec
      (CastingRestriction.SpendOnlyOnX Color.Black)
      " {\"type\":\"SpendOnlyOnX\",\"value\":{\"type\":\"Black\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CastingRestriction.codec
