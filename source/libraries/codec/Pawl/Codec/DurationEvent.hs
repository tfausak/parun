module Pawl.Codec.DurationEvent where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.DurationEvent as DurationEvent

codec :: Codec.Codec DurationEvent.DurationEvent
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "SourceTurnedFaceDown" DurationEvent.SourceTurnedFaceDown,
      Arm.payload "SpellCast" (Filter.codec Keyword.codec) DurationEvent.SpellCast (\x -> case x of DurationEvent.SpellCast y -> Just y; _ -> Nothing),
      Arm.nullary "Planeswalked" DurationEvent.Planeswalked
    ]

tagOf :: DurationEvent.DurationEvent -> String
tagOf x = case x of
  DurationEvent.SourceTurnedFaceDown {} -> "SourceTurnedFaceDown"
  DurationEvent.SpellCast {} -> "SpellCast"
  DurationEvent.Planeswalked {} -> "Planeswalked"
