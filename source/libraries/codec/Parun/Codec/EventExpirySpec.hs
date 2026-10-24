module Parun.Codec.EventExpirySpec where

import qualified Parun.Codec.EventExpiry as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.EventExpiry as EventExpiry
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EventExpiry" $ do
  -- CR 611.2a's event and CR 109.5's baked seat. Runtime-only, as
  -- Parun.Codec.PaidExpiry is.
  Spec.it s "MkEventExpiry, both keys" $
    Common.assertCodec
      s
      Codec.codec
      ( EventExpiry.MkEventExpiry
          { EventExpiry.controller = PlayerId.MkPlayerId 1,
            EventExpiry.event = DurationEvent.SourceTurnedFaceDown
          }
      )
      " {\"controller\":1,\"event\":{\"type\":\"SourceTurnedFaceDown\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Codec.codec
