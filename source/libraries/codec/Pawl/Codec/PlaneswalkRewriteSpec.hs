module Pawl.Codec.PlaneswalkRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.PlaneswalkRewrite as PlaneswalkRewrite

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlaneswalkRewrite" $ do
  -- Susan Foreman.
  Spec.it s "ArrangeTopTwo" $
    Common.assertCodec s (PlaneswalkRewrite.codec Common.natural) PlaneswalkRewrite.ArrangeTopTwo " {\"type\":\"ArrangeTopTwo\"} "
  -- Fixed Point in Time, with a natural standing in for the effect.
  Spec.it s "RunEffects" $
    Common.assertCodec s (PlaneswalkRewrite.codec Common.natural) (PlaneswalkRewrite.RunEffects (Seq.fromList [7])) " {\"type\":\"RunEffects\",\"value\":[7]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (PlaneswalkRewrite.codec Common.natural)
