module Parun.Codec.RevealCauseSpec where

import qualified Parun.Codec.RevealCause as RevealCause
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.RevealCause as RevealCause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RevealCause" $ do
  Spec.it s "Ordinary" $
    Common.assertCodec
      s
      RevealCause.codec
      RevealCause.Ordinary
      " {\"type\":\"Ordinary\"} "
  Spec.it s "ForMiracle" $
    Common.assertCodec
      s
      RevealCause.codec
      (RevealCause.ForMiracle (Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = []}))
      " {\"type\":\"ForMiracle\",\"value\":{\"mana\":[]}} "
  Spec.it s "AsDrawnUnder" $
    Common.assertCodec
      s
      RevealCause.codec
      (RevealCause.AsDrawnUnder (ObjectId.MkObjectId 7))
      " {\"type\":\"AsDrawnUnder\",\"value\":7} "
  Spec.it s "LeavingFaceDown" $
    Common.assertCodec
      s
      RevealCause.codec
      RevealCause.LeavingFaceDown
      " {\"type\":\"LeavingFaceDown\"} "
  Spec.it s "LeavingFaceDownComponent" $
    Common.assertCodec
      s
      RevealCause.codec
      RevealCause.LeavingFaceDownComponent
      " {\"type\":\"LeavingFaceDownComponent\"} "
  Spec.it s "FaceDownSpell" $
    Common.assertCodec
      s
      RevealCause.codec
      RevealCause.FaceDownSpell
      " {\"type\":\"FaceDownSpell\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s RevealCause.codec
