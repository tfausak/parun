module Parun.Codec.PlayerCountersSpec where

import qualified Parun.Codec.PlayerCounters as PlayerCounters
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerCounters as PlayerCounters
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerCounters" $ do
  -- GainPlayerCounters' payload. All three keys are required.
  Spec.it s "MkPlayerCounters, all three keys" $
    Common.assertCodec
      s
      PlayerCounters.codec
      ( PlayerCounters.MkPlayerCounters
          { PlayerCounters.player = PlayerRef.Relative PlayerRelation.You,
            PlayerCounters.kind = PlayerCounterKind.Rad,
            PlayerCounters.quantity = Quantity.Literal 2
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"kind\":{\"type\":\"Rad\"},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerCounters.codec
