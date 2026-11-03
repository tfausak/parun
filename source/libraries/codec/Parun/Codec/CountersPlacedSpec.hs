module Parun.Codec.CountersPlacedSpec where

import qualified Parun.Codec.CountersPlaced as CountersPlaced
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CountersPlaced" $ do
  -- The counts differ, so a codec swapping them would not round-trip.
  Spec.it s "MkCountersPlaced, every key" $
    Common.assertCodec
      s
      CountersPlaced.codec
      ( CountersPlaced.MkCountersPlaced
          { CountersPlaced.putter = PlayerId.MkPlayerId 2,
            CountersPlaced.object = ObjectId.MkObjectId 1,
            CountersPlaced.kind = CounterKind.Lore,
            CountersPlaced.before = 1,
            CountersPlaced.after = 3
          }
      )
      " {\"putter\":2,\"object\":1,\"kind\":{\"type\":\"Lore\"},\"before\":1,\"after\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CountersPlaced.codec
