module Pawl.Codec.UntapHold where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.UntapHold as UntapHold

codec :: Codec.Codec UntapHold.UntapHold
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Forbidden" UntapHold.Forbidden,
      Arm.nullary "Elective" UntapHold.Elective,
      Arm.payload "AtMost" Common.natural UntapHold.AtMost (\x -> case x of UntapHold.AtMost y -> Just y; _ -> Nothing)
    ]

tagOf :: UntapHold.UntapHold -> String
tagOf x = case x of
  UntapHold.Forbidden -> "Forbidden"
  UntapHold.Elective -> "Elective"
  UntapHold.AtMost {} -> "AtMost"
