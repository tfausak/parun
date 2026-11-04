{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StepOfControllerOf where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Phase as Phase
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StepOfControllerOf as StepOfControllerOf

-- | A bare object keyed by the record's field names, like Parun.Codec.StepBegan.
codec :: Codec.Codec StepOfControllerOf.StepOfControllerOf
codec = Fields.object $ do
  phase <- Fields.required "phase" Phase.codec StepOfControllerOf.phase
  object <- Fields.required "object" ObjectId.codec StepOfControllerOf.object
  pure StepOfControllerOf.MkStepOfControllerOf {StepOfControllerOf.phase = phase, StepOfControllerOf.object = object}
