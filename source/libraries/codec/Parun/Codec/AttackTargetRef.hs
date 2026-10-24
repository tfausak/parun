module Parun.Codec.AttackTargetRef where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackTargetRef as AttackTargetRef

-- | Reached from card data through Parun.Codec.RequireAttack's `defender` key.
codec :: Codec.Codec AttackTargetRef.AttackTargetRef
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Players" PlayerRef.codec AttackTargetRef.Players (\x -> case x of AttackTargetRef.Players y -> Just y; _ -> Nothing),
      Arm.payload "Permanents" ObjectRef.codec AttackTargetRef.Permanents (\x -> case x of AttackTargetRef.Permanents y -> Just y; _ -> Nothing)
    ]

tagOf :: AttackTargetRef.AttackTargetRef -> String
tagOf x = case x of
  AttackTargetRef.Players {} -> "Players"
  AttackTargetRef.Permanents {} -> "Permanents"
