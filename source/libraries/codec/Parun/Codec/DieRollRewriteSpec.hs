module Parun.Codec.DieRollRewriteSpec where

import qualified Parun.Codec.DieRollRewrite as DieRollRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DieRollRewrite as DieRollRewrite

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DieRollRewrite" $ do
  -- CR 706.6: Pixie Guide.
  Spec.it s "ExtraIgnoringLowest" $
    Common.assertCodec
      s
      DieRollRewrite.codec
      DieRollRewrite.ExtraIgnoringLowest
      " {\"type\":\"ExtraIgnoringLowest\"} "
  -- CR 614.6: Pokey, the Scallywagg.
  Spec.it s "FlipCoinInstead" $
    Common.assertCodec
      s
      DieRollRewrite.codec
      DieRollRewrite.FlipCoinInstead
      " {\"type\":\"FlipCoinInstead\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DieRollRewrite.codec
