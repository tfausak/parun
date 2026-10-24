module Parun.Codec.PlayerCounterTallySpec where

import qualified Parun.Codec.PlayerCounterTally as PlayerCounterTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerCounterTally" $ do
  -- CR 122: how many counters of a kind a player already has -- a LEAF, so
  -- nothing here is a Quantity.
  Spec.it s "MkPlayerCounterTally" $
    Common.assertCodec
      s
      PlayerCounterTally.codec
      ( PlayerCounterTally.MkPlayerCounterTally
          { PlayerCounterTally.player = PlayerRef.Relative PlayerRelation.AnyPlayer,
            PlayerCounterTally.kind = PlayerCounterKind.Energy
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"kind\":{\"type\":\"Energy\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerCounterTally.codec
