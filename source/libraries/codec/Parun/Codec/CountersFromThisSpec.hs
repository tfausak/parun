module Parun.Codec.CountersFromThisSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CountersFromThis as CountersFromThis
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterName as CounterName
import qualified Parun.Types.CountersFromThis as CountersFromThis
import qualified Parun.Types.Keyword as Keyword

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (CountersFromThis.CountersFromThis Keyword.Keyword)
codec = CountersFromThis.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CountersFromThis" $ do
  -- Hickory Woodlot's one depletion counter.
  Spec.it s "MkCountersFromThis" $
    Common.assertCodec
      s
      codec
      ( CountersFromThis.MkCountersFromThis
          { CountersFromThis.kind = CounterKind.Named (CounterName.UnsafeMkCounterName (Text.pack "depletion")),
            CountersFromThis.count = 1
          }
      )
      " {\"count\":1,\"kind\":{\"type\":\"Named\",\"value\":\"depletion\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
