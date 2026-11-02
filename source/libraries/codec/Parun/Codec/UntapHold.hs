module Parun.Codec.UntapHold where

import qualified Parun.Codec.CardType as CardType
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.UntapHold as UntapHold

codec :: Codec.Codec UntapHold.UntapHold
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Forbidden" UntapHold.Forbidden,
      Arm.nullary "Elective" UntapHold.Elective,
      Arm.payload "AtMost" Common.natural UntapHold.AtMost (\x -> case x of UntapHold.AtMost y -> Just y; _ -> Nothing),
      Arm.nullary "DuringOthersSteps" UntapHold.DuringOthersSteps,
      Arm.payload "OfChosenType" (Common.nonEmpty CardType.codec) UntapHold.OfChosenType (\x -> case x of UntapHold.OfChosenType y -> Just y; _ -> Nothing),
      Arm.nullary "Never" UntapHold.Never
    ]

tagOf :: UntapHold.UntapHold -> String
tagOf x = case x of
  UntapHold.Forbidden -> "Forbidden"
  UntapHold.Elective -> "Elective"
  UntapHold.AtMost {} -> "AtMost"
  UntapHold.DuringOthersSteps -> "DuringOthersSteps"
  UntapHold.OfChosenType {} -> "OfChosenType"
  UntapHold.Never -> "Never"
