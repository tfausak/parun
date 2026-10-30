module Parun.Codec.Counterability where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Counterability as Counterability

codec :: Codec.Codec Counterability.Counterability
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Counterable" Counterability.Counterable,
      Arm.optionalPayload "CantBeCountered" Condition.codec Counterability.CantBeCountered (\x -> case x of Counterability.CantBeCountered y -> Just y; _ -> Nothing)
    ]

tagOf :: Counterability.Counterability -> String
tagOf x = case x of
  Counterability.Counterable -> "Counterable"
  Counterability.CantBeCountered {} -> "CantBeCountered"
