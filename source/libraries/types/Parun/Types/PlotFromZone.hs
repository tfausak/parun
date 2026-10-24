module Parun.Types.PlotFromZone where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.PlayerEffect's PlotFrom arm: whose copy of which
-- zone CR 702.170f lets plot function in, and which cards in it are covered.
--
-- A library reference means its TOP CARD, Parun.Engine.Cast.pileCandidates'
-- narrowing for Parun.Types.CastFromZone one type over.
data PlotFromZone = MkPlotFromZone
  { from :: InZone.InZone,
    matching :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
