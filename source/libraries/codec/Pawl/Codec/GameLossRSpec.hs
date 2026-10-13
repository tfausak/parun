module Pawl.Codec.GameLossRSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.GameLossR as GameLossR
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ControllerRelation as ControllerRelation
import qualified Pawl.Types.GameLossR as GameLossR
import qualified Pawl.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.GameLossR" $ do
  -- CR 614.1a / 104.3: Lich's Mirror's shape, with a natural standing in for
  -- the effect.
  Spec.it s "MkGameLossR" $
    Common.assertCodec
      s
      (GameLossR.codec Common.natural)
      (GameLossR.MkGameLossR (ControllerRelation.Related PlayerRelation.You) (Seq.fromList [7]))
      " {\"whose\":{\"type\":\"You\"},\"instead\":[7]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (GameLossR.codec Common.natural)
