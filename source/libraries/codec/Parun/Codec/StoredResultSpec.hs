module Parun.Codec.StoredResultSpec where

import qualified Parun.Codec.StoredResult as StoredResult
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.StoredResult as StoredResult

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StoredResult" $ do
  -- Distinct numbers, so a codec that swapped the fields would not round-trip.
  Spec.it s "MkStoredResult" $
    Common.assertCodec
      s
      StoredResult.codec
      StoredResult.MkStoredResult {StoredResult.sides = 6, StoredResult.value = 4}
      " {\"sides\":6,\"value\":4} "
  Spec.it s "has a schema" $ Common.assertHasSchema s StoredResult.codec
