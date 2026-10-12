-- CR 702.158b's vocabulary: which of Pawl.Types.Designation's marks are the
-- sectors. Apart from Pawl.Engine.SpaceSculptor, which holds the rules, so that
-- Pawl.Engine.Filter can read it without importing the projection.
module Pawl.Engine.Sector where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Set as Set
import qualified Pawl.Types.Designation as Designation

-- | CR 702.158b: the three sector designations, in the order the rule names them.
sectors :: NonEmpty.NonEmpty Designation.Designation
sectors = Designation.AlphaSector NonEmpty.:| [Designation.BetaSector, Designation.GammaSector]

-- | CR 702.158b: is this designation a sector?
isSector :: Designation.Designation -> Bool
isSector designation = designation `elem` sectors

-- | The sector designations among these. CR 704.5u gives a permanent at most one.
sectorsIn :: Set.Set Designation.Designation -> Set.Set Designation.Designation
sectorsIn = Set.filter isSector
