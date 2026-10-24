module Parun.Codec.DurationEvent where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DurationEvent as DurationEvent

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
