-- | SplitMix64 (Steele, Lea and Flood 2014; Vigna's splitmix64.c), the
-- generator chance and the random bot draw from. Fast, small, and not
-- cryptographically secure. Saved games record outcomes, never a seed, so
-- nothing outside a running game depends on which generator this is.
module Pawl.Play.SplitMix where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bits as Bits
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Word as Word
import Numeric.Natural (Natural)
import qualified Pawl.Extra.Int as Int
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.Extra.Word64 as Word64
import qualified Pawl.Types.SplitMix as SplitMix

-- | The next 64 bits.
next :: (Monad m) => State.StateT SplitMix.SplitMix m Word.Word64
next = State.state $ \(SplitMix.MkSplitMix state) ->
  let advanced = state + 0x9e3779b97f4a7c15
      mixed = mix 31 (mix 27 (mix 30 advanced * 0xbf58476d1ce4e5b9) * 0x94d049bb133111eb)
   in (mixed, SplitMix.MkSplitMix advanced)
  where
    mix n z = Bits.xor z (Bits.shiftR z n)

-- | Uniform from least to greatest, both included; least when they cross. A
-- range wider than 2^64 is drawn from its first 2^64 values.
between :: (Monad m) => Natural -> Natural -> State.StateT SplitMix.SplitMix m Natural
between least greatest
  | greatest <= least = pure least
  | otherwise =
      fmap ((+ least) . Word64.toNatural) $
        maybe next below (Natural.toWord64 (greatest - least + 1))

-- | Uniform below a size of at least one. A draw under 2^64 mod the size would
-- favour the low remainders, so it is drawn again.
below :: (Monad m) => Word.Word64 -> State.StateT SplitMix.SplitMix m Word.Word64
below size = do
  x <- next
  if x < negate size `mod` size then below size else pure (x `mod` size)

-- | One of the options, each equally likely.
pick :: (Monad m) => NonEmpty.NonEmpty a -> State.StateT SplitMix.SplitMix m a
pick options = do
  i <- between 0 (Natural.length options - 1)
  pure (Maybe.fromMaybe (NonEmpty.head options) (Maybe.listToMaybe (List.genericDrop i (NonEmpty.toList options))))

-- | Every order equally likely: Fisher and Yates, swapping each position from
-- the last down with one at or below it.
shuffle :: (Monad m) => [a] -> State.StateT SplitMix.SplitMix m [a]
shuffle xs = fmap Foldable.toList (go (Seq.length items - 1) items)
  where
    items = Seq.fromList xs
    go i acc
      | i < 1 = pure acc
      | otherwise = do
          j <- fmap Natural.toIntSaturating (between 0 (Int.toNaturalSaturating i))
          go (i - 1) (swap i j acc)
    swap i j acc = Maybe.fromMaybe acc $ do
      a <- Seq.lookup i acc
      b <- Seq.lookup j acc
      pure (Seq.update i b (Seq.update j a acc))
