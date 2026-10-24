module Parun.Codec.DrawnUnderSpec where

import qualified Parun.Codec.DrawnUnder as DrawnUnder
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DrawnUnder as DrawnUnder
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.RevealTiming as RevealTiming

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawnUnder" $ do
  Spec.it s "MkDrawnUnder" $
    Common.assertCodec
      s
      DrawnUnder.codec
      (DrawnUnder.MkDrawnUnder {DrawnUnder.under = ObjectId.MkObjectId 7, DrawnUnder.timing = RevealTiming.OnceCast})
      " {\"under\":7,\"timing\":{\"type\":\"OnceCast\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DrawnUnder.codec
