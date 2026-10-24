module Parun.Codec.EventShape where

import qualified Parun.Codec.CardArrivedIn as CardArrivedIn
import qualified Parun.Codec.MovedBetween as MovedBetween
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EventShape as EventShape

-- | Every arm is tagged, and each payload's own codec says what its value looks
-- like: CardArrivedIn's is an object rather than the bare Zone it once was,
-- since the shape now carries an origin exclusion beside the destination.
codec :: Codec.Codec EventShape.EventShape
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "MovedBetween" MovedBetween.codec EventShape.MovedBetween (\x -> case x of EventShape.MovedBetween y -> Just y; _ -> Nothing),
      Arm.payload "MovedFrom" Zone.codec EventShape.MovedFrom (\x -> case x of EventShape.MovedFrom y -> Just y; _ -> Nothing),
      Arm.payload "CardArrivedIn" CardArrivedIn.codec EventShape.CardArrivedIn (\x -> case x of EventShape.CardArrivedIn y -> Just y; _ -> Nothing),
      Arm.nullary "SpellCast" EventShape.SpellCast,
      Arm.nullary "SpellCastThisGame" EventShape.SpellCastThisGame
    ]

tagOf :: EventShape.EventShape -> String
tagOf x = case x of
  EventShape.MovedBetween {} -> "MovedBetween"
  EventShape.MovedFrom {} -> "MovedFrom"
  EventShape.CardArrivedIn {} -> "CardArrivedIn"
  EventShape.SpellCast {} -> "SpellCast"
  EventShape.SpellCastThisGame {} -> "SpellCastThisGame"
