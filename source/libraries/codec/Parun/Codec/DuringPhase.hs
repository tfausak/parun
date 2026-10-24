{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DuringPhase where

import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DuringPhase as DuringPhase

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be.
--
-- The window is a PhaseSelector, so a rider naming a step nests it inside that
-- type's own `Step` tag. The codec does not also accept the older bare-phase
-- spelling: two spellings of one window is the thing Parun.Types.PhaseSelector
-- exists to prevent.
codec :: Codec.Codec DuringPhase.DuringPhase
codec = Fields.object $ do
  window <- Fields.required "window" PhaseSelector.codec DuringPhase.window
  scope <- Fields.required "scope" TurnScope.codec DuringPhase.scope
  pure DuringPhase.MkDuringPhase {DuringPhase.window = window, DuringPhase.scope = scope}
