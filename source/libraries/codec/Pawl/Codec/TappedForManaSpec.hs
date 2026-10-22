module Pawl.Codec.TappedForManaSpec where

import qualified Data.Set as Set
import qualified Pawl.Codec.TappedForMana as TappedForMana
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.TappedForMana as TappedForMana

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TappedForMana" $ do
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
