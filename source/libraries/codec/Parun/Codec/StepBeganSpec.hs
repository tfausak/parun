module Parun.Codec.StepBeganSpec where

import qualified Parun.Codec.StepBegan as StepBegan
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.StepBegan as StepBegan

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StepBegan" $ do
  -- CR 500.1.
  Spec.it s "MkStepBegan, both keys" $
    Common.assertCodec
      s
      StepBegan.codec
      ( StepBegan.MkStepBegan
          { StepBegan.phase = Phase.Beginning BeginningStep.Upkeep,
            StepBegan.player = PlayerId.MkPlayerId 1
          }
      )
      " {\"phase\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}},\"player\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s StepBegan.codec
