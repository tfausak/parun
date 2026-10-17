module Pawl.Play.SplitMixSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Word as Word
import qualified Pawl.Play.SplitMix as SplitMix
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.SplitMix as SplitMix.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Play.SplitMix" $ do
  Spec.describe s "next" $ do
    Spec.it s "matches the reference outputs from seed 0" $ do
      Spec.assertEq s (from 0 (Monad.replicateM 3 SplitMix.next)) [0xe220a8397b1dcdaf, 0x6e789e6aa1b965f4, 0x06c45d188009454f]

    Spec.it s "matches the reference outputs from seed 1234567" $ do
      Spec.assertEq s (from 1234567 (Monad.replicateM 5 SplitMix.next)) [6457827717110365317, 3203168211198807973, 9817491932198370423, 4593380528125082431, 16408922859458223821]

  Spec.describe s "between" $ do
    Spec.it s "draws again rather than favour a low remainder" $ do
      -- Seed 3's first draw is below (2^64 - n) mod n, so it is rejected and
      -- the answer is the second draw's remainder.
      Spec.assertEq s (from 3 (SplitMix.between 0 9223372036854775808)) 3694763184872335752

    Spec.it s "stays within its bounds" $ do
      let drawn = from 0 (Monad.replicateM 200 (SplitMix.between 3 5))
      Spec.assertEq s (Set.toList (Set.fromList drawn)) [3, 4, 5]

    Spec.it s "answers its one value when the bounds meet" $ do
      Spec.assertEq s (from 0 (SplitMix.between 7 7)) 7

  Spec.describe s "pick" $ do
    Spec.it s "reaches every option" $ do
      let picked = from 0 (Monad.replicateM 100 (SplitMix.pick ('a' NonEmpty.:| "bc")))
      Spec.assertEq s (Set.toList (Set.fromList picked)) "abc"

  Spec.describe s "shuffle" $ do
    Spec.it s "is a permutation" $ do
      let shuffled = from 0 (SplitMix.shuffle [1 .. 20 :: Int])
      Spec.assertEq s (List.sort shuffled) [1 .. 20]
      Spec.assertBool s (shuffled /= [1 .. 20]) "moved"

    Spec.it s "reaches every order of three about equally often" $ do
      let orders = from 0 (Monad.replicateM 6000 (SplitMix.shuffle "abc"))
          counts = Map.fromListWith (+) (fmap (\o -> (o, 1 :: Int)) orders)
      Spec.assertEq s (Map.size counts) 6
      Spec.assertBool s (all (\n -> n > 900 && n < 1100) counts) ("even: " <> show counts)

    Spec.it s "depends on the seed" $ do
      Spec.assertBool s (from 0 (SplitMix.shuffle [1 .. 20 :: Int]) /= from 1 (SplitMix.shuffle [1 .. 20])) "differs"

from :: Word.Word64 -> State.State SplitMix.Type.SplitMix a -> a
from seed action = State.evalState action (SplitMix.Type.MkSplitMix seed)
