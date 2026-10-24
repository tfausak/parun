module Parun.Types.Arithmetic where

import qualified Data.Traversable as Traversable
import qualified Parun.Types.Halved as Halved
import qualified Parun.Types.Plus as Plus
import qualified Parun.Types.Times as Times

-- | CR 107.1's calculations over a number, parametric in it for
-- Parun.Types.Count's reason. Every structural walk over Parun.Types.Quantity
-- descends through 'traverse' below, so a new calculation is compile-forced
-- there once rather than skipped by a wildcard in each walk.
data Arithmetic quantity
  = -- | CR 208.2: composition, so a printed 1+* needs no constructor of its own.
    Plus (Plus.Plus quantity)
  | -- | CR 107.1a: half the inner quantity, rounded the way the card prints
    -- (Parun.Types.Rounding).
    Halved (Halved.Halved quantity)
  | -- | CR 107.1: the payload's factor times the inner quantity, which is the
    -- "N for each" a card prints; see Parun.Types.Times.
    Times (Times.Times quantity)
  | -- | The negation of the inner quantity -- the minus a card prints in front
    -- of a value, as in "-X/-X". CR 107.1b: a game value may go negative; a
    -- count reader saturates at 0.
    Negate quantity
  deriving (Eq, Ord, Show)

instance Functor Arithmetic where
  fmap = Traversable.fmapDefault

instance Foldable Arithmetic where
  foldMap = Traversable.foldMapDefault

instance Traversable Arithmetic where
  traverse f arithmetic = case arithmetic of
    Plus (Plus.MkPlus left right) -> fmap Plus (Plus.MkPlus <$> f left <*> f right)
    Halved (Halved.MkHalved rounding inner) -> fmap (Halved . Halved.MkHalved rounding) (f inner)
    Times (Times.MkTimes factor inner) -> fmap (Times . Times.MkTimes factor) (f inner)
    Negate inner -> fmap Negate (f inner)
