module Parun.Codec.Readiness where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Readiness as Readiness

-- | Ready as true, for a document people write by hand: @"ready": true@.
codec :: Codec.Codec Readiness.Readiness
codec =
  Common.boolean
    { Codec.encode = \x -> Codec.encode Common.boolean (x == Readiness.Ready),
      Codec.decode = \value -> do
        b <- Codec.decode Common.boolean value
        pure (if b then Readiness.Ready else Readiness.Sick)
    }
