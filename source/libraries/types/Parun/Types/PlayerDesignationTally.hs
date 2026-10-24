module Parun.Types.PlayerDesignationTally where

import qualified Parun.Types.PlayerDesignation as PlayerDesignation
import qualified Parun.Types.PlayerRef as PlayerRef

-- | The payload of Parun.Types.Quantity's HasPlayerDesignation arm: whether a
-- player has one of CR 702.131c's and CR 702.195b's marks.
--
-- Parun.Types.PlayerCounterTally's shape and for its reason -- the arm needs both
-- a player reference and which mark, and it is a LEAF holding no Quantity, so
-- nothing here can close a cycle with Quantity.
data PlayerDesignationTally = MkPlayerDesignationTally
  { player :: PlayerRef.PlayerRef,
    designation :: PlayerDesignation.PlayerDesignation
  }
  deriving (Eq, Ord, Show)
