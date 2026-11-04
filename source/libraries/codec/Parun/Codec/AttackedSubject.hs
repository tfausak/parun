module Parun.Codec.AttackedSubject where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackedSubject as AttackedSubject

codec :: Codec.Codec AttackedSubject.AttackedSubject
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Related" PlayerRelation.codec AttackedSubject.Related (\x -> case x of AttackedSubject.Related y -> Just y; _ -> Nothing),
      Arm.nullary "Enchanted" AttackedSubject.Enchanted,
      Arm.nullary "Source" AttackedSubject.Source
    ]

tagOf :: AttackedSubject.AttackedSubject -> String
tagOf x = case x of
  AttackedSubject.Related {} -> "Related"
  AttackedSubject.Enchanted -> "Enchanted"
  AttackedSubject.Source -> "Source"
