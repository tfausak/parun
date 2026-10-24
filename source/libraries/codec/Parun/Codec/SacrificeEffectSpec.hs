module Parun.Codec.SacrificeEffectSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.SacrificeEffect as SacrificeEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SacrificeEffect" $ do
  -- CR 701.21a's ordinary form, which every card in the pool but Golgothian
  -- Sylex and City in a Bottle prints: the sacrificer is the default, so no key
  -- is written.
  Spec.it s "the effect's controller writes no sacrificer" $
    Common.assertCodec
      s
      SacrificeEffect.codec
      SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")), SacrificeEffect.sacrificer = Sacrificer.EffectController, SacrificeEffect.sacrificed = Nothing}
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 701.54c's form, which is what makes the field more than a constant.
  Spec.it s "the permanent's controller is written" $
    Common.assertCodec
      s
      SacrificeEffect.codec
      SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "thatBlocker")), SacrificeEffect.sacrificer = Sacrificer.PermanentController, SacrificeEffect.sacrificed = Nothing}
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"thatBlocker\"},\"sacrificer\":{\"type\":\"PermanentController\"}} "
  -- Golgothian Sylex's form: the sweep a bare SlotName could not express, with
  -- the other sacrificer beside it.
  Spec.it s "a filtered sweep round-trips" $
    Common.assertCodec
      s
      SacrificeEffect.codec
      SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.EachMatching (Filter.Not Filter.IsToken), SacrificeEffect.sacrificer = Sacrificer.PermanentController, SacrificeEffect.sacrificed = Nothing}
      " {\"ref\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}},\"sacrificer\":{\"type\":\"PermanentController\"}} "
  -- God-Eternal Bontu's form: a chosen set, and the count of what went.
  Spec.it s "the sacrificed count's slot is written" $
    Common.assertCodec
      s
      SacrificeEffect.codec
      SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")), SacrificeEffect.sacrificer = Sacrificer.EffectController, SacrificeEffect.sacrificed = Just (SlotName.MkSlotName (Text.pack "sacrificed"))}
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"},\"sacrificed\":\"sacrificed\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SacrificeEffect.codec
