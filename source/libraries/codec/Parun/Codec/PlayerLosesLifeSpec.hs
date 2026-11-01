module Parun.Codec.PlayerLosesLifeSpec where

import qualified Parun.Codec.PlayerLosesLife as PlayerLosesLife
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerLosesLife as PlayerLosesLife
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerLosesLife" $ do
  -- Vengeful Warchief.
  Spec.it s "FirstTimeEachTurn writes both keys" $
    Common.assertCodec
      s
      PlayerLosesLife.codec
      (PlayerLosesLife.MkPlayerLosesLife PlayerRelation.You TriggerFrequency.FirstTimeEachTurn)
      " {\"player\":{\"type\":\"You\"},\"frequency\":{\"type\":\"FirstTimeEachTurn\"}} "
  -- Exquisite Blood: every loss, so no key.
  Spec.it s "EveryTime writes no frequency key" $
    Common.assertCodec
      s
      PlayerLosesLife.codec
      (PlayerLosesLife.MkPlayerLosesLife PlayerRelation.Opponent TriggerFrequency.EveryTime)
      " {\"player\":{\"type\":\"Opponent\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerLosesLife.codec
