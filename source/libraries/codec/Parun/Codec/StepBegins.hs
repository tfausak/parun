{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StepBegins where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StepBegins as StepBegins

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Phase and scope are required: an unscoped
-- trigger is a different card, not a defaulted one. CR 505.1b's @ordinal@ is
-- defaulted to absent, which is what every card that names its phase rather than
-- counting main phases says.
codec :: Codec.Codec StepBegins.StepBegins
codec = Fields.object $ do
  ordinal <- Fields.defaulted "ordinal" Nothing (Common.maybe Common.natural) StepBegins.ordinal
  phase <- Fields.required "phase" Phase.codec StepBegins.phase
  scope <- Fields.required "scope" TurnScope.codec StepBegins.scope
  pure StepBegins.MkStepBegins {StepBegins.ordinal = ordinal, StepBegins.phase = phase, StepBegins.scope = scope}
