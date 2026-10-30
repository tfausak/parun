module Parun.Codec.DrawRSpec where

import qualified Parun.Codec.DrawR as DrawR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DrawR as DrawR
import qualified Parun.Types.DrawRewrite as DrawRewrite
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawR" $ do
  -- CR 614.11 / 121.6: Words of Worship.
  Spec.it s "MkDrawR" $
    Common.assertCodec
      s
      DrawR.codec
      (DrawR.MkDrawR (ControllerRelation.Related PlayerRelation.You) False (DrawRewrite.GainLife 5))
      " {\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"GainLife\",\"value\":5}} "
  -- CR 504.1 / 614.1a: Alhammarret's Archive.
  Spec.it s "exceptFirstInDrawStep" $
    Common.assertCodec
      s
      DrawR.codec
      (DrawR.MkDrawR (ControllerRelation.Related PlayerRelation.You) True (DrawRewrite.DrawInstead 2))
      " {\"whose\":{\"type\":\"You\"},\"exceptFirstInDrawStep\":true,\"rewrite\":{\"type\":\"DrawInstead\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DrawR.codec
