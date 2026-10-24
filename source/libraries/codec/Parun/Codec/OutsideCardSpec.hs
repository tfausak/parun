module Parun.Codec.OutsideCardSpec where

import qualified Parun.Codec.OutsideCard as OutsideCard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.OutsideCard as OutsideCard
import qualified Parun.Types.PrintingId as PrintingId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OutsideCard" $ do
  Spec.it s "InPool" $
    Common.assertCodec
      s
      OutsideCard.codec
      (OutsideCard.InPool (PrintingId.MkPrintingId 3))
      " {\"type\":\"InPool\",\"value\":3} "
  Spec.it s "InAnotherGame" $
    Common.assertCodec
      s
      OutsideCard.codec
      (OutsideCard.InAnotherGame (ObjectId.MkObjectId 7))
      " {\"type\":\"InAnotherGame\",\"value\":7} "
  Spec.it s "has a schema" $ Common.assertHasSchema s OutsideCard.codec
