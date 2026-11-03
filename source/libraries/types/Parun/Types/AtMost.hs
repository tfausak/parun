module Parun.Types.AtMost where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Traversable as Traversable

-- | The payload of Parun.Types.Quantity's AtMost arm: a value and the limits it
-- may not exceed -- Drain Life's "life equal to the damage dealt, but not more
-- life than the player's life total ..., the planeswalker's loyalty ..., or the
-- creature's toughness".
--
-- PARAMETRIC in the quantity for Parun.Types.Plus's reason.
--
-- A NonEmpty of limits rather than nested pairs, because the printed list is
-- one sentence and each limit is read alone: a limit naming nothing that exists
-- (a planeswalker's loyalty when the target is a player) imposes nothing, which
-- a nested lesser-of could not say without answering for the missing side.
data AtMost quantity = MkAtMost
  { quantity :: quantity,
    limits :: NonEmpty.NonEmpty quantity
  }
  deriving (Eq, Ord, Show)

instance Functor AtMost where
  fmap = Traversable.fmapDefault

instance Foldable AtMost where
  foldMap = Traversable.foldMapDefault

instance Traversable AtMost where
  traverse f (MkAtMost inner caps) = MkAtMost <$> f inner <*> traverse f caps
