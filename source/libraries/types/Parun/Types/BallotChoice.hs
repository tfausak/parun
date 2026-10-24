module Parun.Types.BallotChoice where

import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SlotName as SlotName

-- | One of a vote's listed choices (CR 701.38b), its object as @o@: an
-- ObjectId where Prompt.ChooseVote offers it, an ObjectSnapshot where a
-- Parun.Types.Ballot records it, so a ballot still names one that has since left.
data BallotChoice o
  = -- | An object (CR 701.38b).
    ForObject o
  | -- | A word with no rules meaning (CR 701.38b).
    ForWord SlotName.SlotName
  | -- | A player (CR 701.38b).
    ForPlayer PlayerId.PlayerId
  deriving (Eq, Ord, Show)

instance Functor BallotChoice where
  fmap f choice = case choice of
    ForObject o -> ForObject (f o)
    ForWord word -> ForWord word
    ForPlayer pid -> ForPlayer pid

instance Foldable BallotChoice where
  foldr f z choice = case choice of
    ForObject o -> f o z
    ForWord _ -> z
    ForPlayer _ -> z

instance Traversable BallotChoice where
  traverse f choice = case choice of
    ForObject o -> fmap ForObject (f o)
    ForWord word -> pure (ForWord word)
    ForPlayer pid -> pure (ForPlayer pid)
