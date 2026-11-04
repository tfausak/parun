module Parun.Codec.LeavingPermanent where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LeavingPermanent as LeavingPermanent

codec :: Codec.Codec LeavingPermanent.LeavingPermanent
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Self" LeavingPermanent.Self,
      Arm.payload "Matching" (Filter.codec Keyword.codec) LeavingPermanent.Matching (\x -> case x of LeavingPermanent.Matching y -> Just y; _ -> Nothing),
      Arm.nullary "Attached" LeavingPermanent.Attached,
      Arm.nullary "Haunted" LeavingPermanent.Haunted,
      Arm.payload "Bound" SlotName.codec LeavingPermanent.Bound (\x -> case x of LeavingPermanent.Bound y -> Just y; _ -> Nothing)
    ]

tagOf :: LeavingPermanent.LeavingPermanent -> String
tagOf x = case x of
  LeavingPermanent.Self {} -> "Self"
  LeavingPermanent.Matching {} -> "Matching"
  LeavingPermanent.Attached {} -> "Attached"
  LeavingPermanent.Haunted {} -> "Haunted"
  LeavingPermanent.Bound {} -> "Bound"
