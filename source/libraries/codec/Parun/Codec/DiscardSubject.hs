module Parun.Codec.DiscardSubject where

import qualified Parun.Codec.PlayerActsOn as PlayerActsOn
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DiscardSubject as DiscardSubject

codec :: Codec.Codec DiscardSubject.DiscardSubject
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Self" DiscardSubject.Self,
      Arm.payload "Discarder" PlayerActsOn.codec DiscardSubject.Discarder (\x -> case x of DiscardSubject.Discarder y -> Just y; _ -> Nothing)
    ]

tagOf :: DiscardSubject.DiscardSubject -> String
tagOf x = case x of
  DiscardSubject.Self {} -> "Self"
  DiscardSubject.Discarder {} -> "Discarder"
