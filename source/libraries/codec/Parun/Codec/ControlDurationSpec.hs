module Parun.Codec.ControlDurationSpec where

import qualified Parun.Codec.ControlDuration as ControlDuration
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlDuration" $ do
  Spec.it s "UntilTurnEnds" $
    Common.assertCodec
      s
      ControlDuration.codec
      ControlDuration.UntilTurnEnds
      " {\"type\":\"UntilTurnEnds\"} "
  Spec.it s "UntilResolutionEnds" $
    Common.assertCodec
      s
      ControlDuration.codec
      ControlDuration.UntilResolutionEnds
      " {\"type\":\"UntilResolutionEnds\"} "
  Spec.it s "WhileResolving" $
    Common.assertCodec
      s
      ControlDuration.codec
      (ControlDuration.WhileResolving (ObjectId.MkObjectId 7))
      " {\"type\":\"WhileResolving\",\"value\":7} "
  Spec.it s "WhileSearching" $
    Common.assertCodec
      s
      ControlDuration.codec
      ControlDuration.WhileSearching
      " {\"type\":\"WhileSearching\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ControlDuration.codec
