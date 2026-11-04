module Parun.Codec.BlockPairSpec where

import qualified Parun.Codec.BlockPair as BlockPair
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BlockPair as BlockPair
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockPair" $ do
  -- Two different Filters, so a codec that crossed the keys would not round-trip.
  Spec.it s "MkBlockPair" $
    Common.assertCodec
      s
      BlockPair.codec
      (BlockPair.MkBlockPair {BlockPair.blocker = Filter.IsRingBearer, BlockPair.attacker = Filter.IsSource})
      " {\"blocker\":{\"type\":\"IsRingBearer\"},\"attacker\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockPair.codec
