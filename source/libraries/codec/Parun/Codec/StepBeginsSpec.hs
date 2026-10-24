module Parun.Codec.StepBeginsSpec where

import qualified Parun.Codec.StepBegins as StepBegins
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StepBegins" $ do
  -- CR 603.2's unscoped "at the beginning of the end step".
  Spec.it s "MkStepBegins, an unscoped end step" $
    Common.assertCodec
      s
      StepBegins.codec
      ( StepBegins.MkStepBegins
          { StepBegins.ordinal = Nothing,
            StepBegins.phase = Phase.Ending EndingStep.EndStep,
            StepBegins.scope = TurnScope.EachTurn
          }
      )
      " {\"phase\":{\"type\":\"Ending\",\"value\":{\"type\":\"EndStep\"}},\"scope\":{\"type\":\"EachTurn\"}} "
  -- CR 603.2a's "your upkeep". The scope is REQUIRED, not defaulted: "at the
  -- beginning of the upkeep" and "at the beginning of YOUR upkeep" are
  -- different cards, so there is no default an absent key could mean.
  Spec.it s "MkStepBegins, the controller's upkeep" $
    Common.assertCodec
      s
      StepBegins.codec
      ( StepBegins.MkStepBegins
          { StepBegins.ordinal = Nothing,
            StepBegins.phase = Phase.Beginning BeginningStep.Upkeep,
            StepBegins.scope = TurnScope.ControllersTurn
          }
      )
      " {\"phase\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}},\"scope\":{\"type\":\"ControllersTurn\"}} "
  -- CR 505.1b's ordinal, which Acrobatic Cheerleader's "your second main phase"
  -- carries and no card that names its phase does.
  Spec.it s "MkStepBegins, the controller's second main phase" $
    Common.assertCodec
      s
      StepBegins.codec
      ( StepBegins.MkStepBegins
          { StepBegins.ordinal = Just 2,
            StepBegins.phase = Phase.PostcombatMain,
            StepBegins.scope = TurnScope.ControllersTurn
          }
      )
      " {\"ordinal\":2,\"phase\":{\"type\":\"PostcombatMain\"},\"scope\":{\"type\":\"ControllersTurn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s StepBegins.codec
