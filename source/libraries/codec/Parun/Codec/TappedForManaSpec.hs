module Parun.Codec.TappedForManaSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.TappedForMana as TappedForMana
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TappedForMana as TappedForMana

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TappedForMana" $ do
  Spec.it s "MkTappedForMana, one type" $
    Common.assertCodec
      s
      TappedForMana.codec
      (TappedForMana.MkTappedForMana {TappedForMana.permanent = ObjectId.MkObjectId 9, TappedForMana.mana = Set.singleton (ManaType.Colored Color.Green), TappedForMana.player = PlayerId.MkPlayerId 1})
      " {\"mana\":[{\"type\":\"Colored\",\"value\":{\"type\":\"Green\"}}],\"permanent\":9,\"player\":1} "
  -- Two types off one activation, which is what a permanent adding "{B}{G}"
  -- writes and what CR 106.12a's narrowing then reads either of.
  Spec.it s "MkTappedForMana, two types" $
    Common.assertCodec
      s
      TappedForMana.codec
      (TappedForMana.MkTappedForMana {TappedForMana.permanent = ObjectId.MkObjectId 4, TappedForMana.mana = Set.fromList [ManaType.Colored Color.Black, ManaType.Colorless], TappedForMana.player = PlayerId.MkPlayerId 2})
      " {\"mana\":[{\"type\":\"Colored\",\"value\":{\"type\":\"Black\"}},{\"type\":\"Colorless\"}],\"permanent\":4,\"player\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TappedForMana.codec
