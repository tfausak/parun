module Parun.Codec.AttackTrigger where

import qualified Parun.Codec.AttackedTrigger as AttackedTrigger
import qualified Parun.Codec.AttackerTrigger as AttackerTrigger
import qualified Parun.Codec.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackTrigger as AttackTrigger

codec :: Codec.Codec AttackTrigger.AttackTrigger
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Attacker" AttackerTrigger.codec AttackTrigger.Attacker (\x -> case x of AttackTrigger.Attacker y -> Just y; _ -> Nothing),
      Arm.payload "Attacked" AttackedTrigger.codec AttackTrigger.Attacked (\x -> case x of AttackTrigger.Attacked y -> Just y; _ -> Nothing),
      Arm.payload "Declaration" DeclarationTrigger.codec AttackTrigger.Declaration (\x -> case x of AttackTrigger.Declaration y -> Just y; _ -> Nothing),
      Arm.payload "Unblocked" (Filter.codec Keyword.codec) AttackTrigger.Unblocked (\x -> case x of AttackTrigger.Unblocked y -> Just y; _ -> Nothing)
    ]

tagOf :: AttackTrigger.AttackTrigger -> String
tagOf x = case x of
  AttackTrigger.Attacker {} -> "Attacker"
  AttackTrigger.Attacked {} -> "Attacked"
  AttackTrigger.Declaration {} -> "Declaration"
  AttackTrigger.Unblocked {} -> "Unblocked"
