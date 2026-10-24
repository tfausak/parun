module Parun.Codec.SlotCountSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.SlotCount as SlotCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Devotion as Devotion
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.TargetCount as TargetCount

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SlotCount" $ do
  Spec.it s "a printed range" $
    Common.assertCodec
      s
      SlotCount.codec
      (SlotCount.Printed (TargetCount.upTo 2))
      " {\"type\":\"Printed\",\"value\":{\"least\":0,\"most\":2}} "
  -- CR 601.2c's variable number of targets, Rot-Curse Rakshasa's "each of X
  -- target creatures".
  Spec.it s "the announced X" $
    Common.assertCodec
      s
      SlotCount.codec
      SlotCount.AnnouncedX
      " {\"type\":\"AnnouncedX\"} "
  -- Pest Infestation's "up to X target artifacts and/or enchantments".
  Spec.it s "up to the announced X" $
    Common.assertCodec
      s
      SlotCount.codec
      SlotCount.UpToAnnouncedX
      " {\"type\":\"UpToAnnouncedX\"} "
  -- Mogis's Marauder's "up to X target creatures ... where X is your devotion to
  -- black".
  Spec.it s "up to a computed number" $
    Common.assertCodec
      s
      SlotCount.codec
      (SlotCount.UpToComputed (Quantity.Devotion (Devotion.MkDevotion (PlayerRef.Relative PlayerRelation.You) (Set.singleton Color.Black))))
      " {\"type\":\"UpToComputed\",\"value\":{\"type\":\"Devotion\",\"value\":{\"colors\":[{\"type\":\"Black\"}],\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s SlotCount.codec
