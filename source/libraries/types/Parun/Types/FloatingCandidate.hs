module Parun.Types.FloatingCandidate where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 614.5's identity for a FLOATING replacement: (source, timestamp).
-- GameState's timestamp counter is monotone, so two Fogs are two instances even
-- from one source object. Parun.Types.CandidateId carries the rule.
--
-- A record rather than a pair, so the two cannot be swapped at a construction
-- site and so the arm has the one payload a codec needs.
data FloatingCandidate = MkFloatingCandidate
  { source :: ObjectId.ObjectId,
    timestamp :: Timestamp.Timestamp
  }
  deriving (Eq, Ord, Show)
