module Parun.Types.Operand where

import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.SlotName as SlotName

-- | What a Parun.Types.Measures comparison compares the candidate's measure
-- against. Literal and Own need nothing beyond the candidate; every other arm is
-- answered off Parun.Engine.Filter.Context, so where it may be written is a
-- position question (Parun.FilterPositionLintSpec).
data Operand
  = -- | A printed number.
    Literal Integer
  | -- | CR 113.7: the source's measure (CR 702.134a's mentor).
    OfSource Measure.Measure
  | -- | CR 208.1: the candidate's own other measure.
    Own Measure.Measure
  | -- | CR 608.2c: a measure of the one object an earlier clause bound at a slot.
    OfBound BoundMeasure.BoundMeasure
  | -- | CR 608.2c: a number an earlier clause bound at a slot.
    AmountInSlot SlotName.SlotName
  | -- | CR 202.3 / 601.2c: the amount the enclosing target slot, conjure
    -- reference or combat restriction names (Parun.Types.TargetSlot's,
    -- Parun.Types.FromReference's and Parun.Types.AffectedUnless's @amount@).
    EnclosingAmount
  | -- | CR 608.2d: that measure of every other candidate the enclosing choice offers (Crackling Doom).
    OfEachOtherCandidate Measure.Measure
  deriving (Eq, Ord, Show)
