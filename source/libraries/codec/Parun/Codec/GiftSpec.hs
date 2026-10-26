module Parun.Codec.GiftSpec where

import qualified Parun.Codec.Gift as Gift
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Gift as Gift
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Gift" $ do
  Spec.it s "Card" $
    Common.assertCodec
      s
      Gift.codec
      Gift.Card
      " {\"type\":\"Card\"} "
  Spec.it s "Food" $
    Common.assertCodec
      s
      Gift.codec
      Gift.Food
      " {\"type\":\"Food\"} "
  -- A type other than the printed Fish, so a codec that dropped the payload for
  -- the CR 702.174f default cannot pass.
  Spec.it s "TappedFish carries its creature type" $
    Common.assertCodec
      s
      Gift.codec
      (Gift.TappedFish Subtype.Elf)
      " {\"type\":\"TappedFish\",\"value\":{\"type\":\"Elf\"}} "
  Spec.it s "Octopus carries its creature type" $
    Common.assertCodec
      s
      Gift.codec
      (Gift.Octopus Subtype.Octopus)
      " {\"type\":\"Octopus\",\"value\":{\"type\":\"Octopus\"}} "
  Spec.it s "Treasure" $
    Common.assertCodec
      s
      Gift.codec
      Gift.Treasure
      " {\"type\":\"Treasure\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Gift.codec
