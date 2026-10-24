module Parun.Codec.RevealCause where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RevealCause as RevealCause

codec :: Codec.Codec RevealCause.RevealCause
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Ordinary" RevealCause.Ordinary,
      Arm.payload "ForMiracle" (Cost.codec Keyword.codec) RevealCause.ForMiracle (\x -> case x of RevealCause.ForMiracle y -> Just y; _ -> Nothing),
      Arm.payload "AsDrawnUnder" ObjectId.codec RevealCause.AsDrawnUnder (\x -> case x of RevealCause.AsDrawnUnder y -> Just y; _ -> Nothing),
      Arm.nullary "LeavingFaceDown" RevealCause.LeavingFaceDown,
      Arm.nullary "LeavingFaceDownComponent" RevealCause.LeavingFaceDownComponent,
      Arm.nullary "FaceDownSpell" RevealCause.FaceDownSpell
    ]

tagOf :: RevealCause.RevealCause -> String
tagOf x = case x of
  RevealCause.Ordinary {} -> "Ordinary"
  RevealCause.ForMiracle {} -> "ForMiracle"
  RevealCause.AsDrawnUnder {} -> "AsDrawnUnder"
  RevealCause.LeavingFaceDown {} -> "LeavingFaceDown"
  RevealCause.LeavingFaceDownComponent {} -> "LeavingFaceDownComponent"
  RevealCause.FaceDownSpell {} -> "FaceDownSpell"
