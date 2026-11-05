module Parun.Codec.TargetedSubject where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TargetedSubject as TargetedSubject

codec :: Codec.Codec TargetedSubject.TargetedSubject
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Permanent" ActingPermanent.codec TargetedSubject.Permanent (\x -> case x of TargetedSubject.Permanent y -> Just y; _ -> Nothing),
      Arm.nullary "You" TargetedSubject.You,
      Arm.payload "YouOrPermanent" ActingPermanent.codec TargetedSubject.YouOrPermanent (\x -> case x of TargetedSubject.YouOrPermanent y -> Just y; _ -> Nothing)
    ]

tagOf :: TargetedSubject.TargetedSubject -> String
tagOf x = case x of
  TargetedSubject.Permanent {} -> "Permanent"
  TargetedSubject.You -> "You"
  TargetedSubject.YouOrPermanent {} -> "YouOrPermanent"
