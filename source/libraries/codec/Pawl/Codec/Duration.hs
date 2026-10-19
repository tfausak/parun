module Pawl.Codec.Duration where

import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.Codec.Cost as Cost
import qualified Pawl.Codec.DurationEvent as DurationEvent
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.Phase as Phase
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.Duration as Duration

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec Duration.Duration
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "UntilEndOfTurn" Duration.UntilEndOfTurn,
      Arm.nullary "Indefinite" Duration.Indefinite,
      Arm.nullary "Perpetual" Duration.Perpetual,
      Arm.nullary "UntilYourNextTurn" Duration.UntilYourNextTurn,
      Arm.payload "UntilYourNextStep" Phase.codec Duration.UntilYourNextStep (\x -> case x of Duration.UntilYourNextStep y -> Just y; _ -> Nothing),
      Arm.nullary "UntilEndOfYourNextTurn" Duration.UntilEndOfYourNextTurn,
      Arm.payload "UntilEndOfNextTurnOf" PlayerRef.codec Duration.UntilEndOfNextTurnOf (\x -> case x of Duration.UntilEndOfNextTurnOf y -> Just y; _ -> Nothing),
      Arm.payload "DuringNextTurnOf" PlayerRef.codec Duration.DuringNextTurnOf (\x -> case x of Duration.DuringNextTurnOf y -> Just y; _ -> Nothing),
      Arm.nullary "DuringYourNextTurn" Duration.DuringYourNextTurn,
      Arm.nullary "DuringThatExtraTurn" Duration.DuringThatExtraTurn,
      Arm.payload "ForAsLongAs" Condition.codec Duration.ForAsLongAs (\x -> case x of Duration.ForAsLongAs y -> Just y; _ -> Nothing),
      Arm.nullary "UntilEndOfCombat" Duration.UntilEndOfCombat,
      Arm.nullary "UntilEndOfCombatOnYourNextTurn" Duration.UntilEndOfCombatOnYourNextTurn,
      Arm.payload "UntilPaid" (Cost.codec Keyword.codec) Duration.UntilPaid (\x -> case x of Duration.UntilPaid y -> Just y; _ -> Nothing),
      Arm.nullary "UntilUsed" Duration.UntilUsed,
      Arm.payload "UntilEvent" DurationEvent.codec Duration.UntilEvent (\x -> case x of Duration.UntilEvent y -> Just y; _ -> Nothing)
    ]

tagOf :: Duration.Duration -> String
tagOf x = case x of
  Duration.UntilEndOfTurn {} -> "UntilEndOfTurn"
  Duration.Indefinite {} -> "Indefinite"
  Duration.Perpetual {} -> "Perpetual"
  Duration.UntilYourNextTurn {} -> "UntilYourNextTurn"
  Duration.UntilYourNextStep {} -> "UntilYourNextStep"
  Duration.UntilEndOfYourNextTurn {} -> "UntilEndOfYourNextTurn"
  Duration.UntilEndOfNextTurnOf {} -> "UntilEndOfNextTurnOf"
  Duration.DuringNextTurnOf {} -> "DuringNextTurnOf"
  Duration.DuringYourNextTurn {} -> "DuringYourNextTurn"
  Duration.DuringThatExtraTurn {} -> "DuringThatExtraTurn"
  Duration.ForAsLongAs {} -> "ForAsLongAs"
  Duration.UntilEndOfCombat {} -> "UntilEndOfCombat"
  Duration.UntilEndOfCombatOnYourNextTurn {} -> "UntilEndOfCombatOnYourNextTurn"
  Duration.UntilPaid {} -> "UntilPaid"
  Duration.UntilUsed {} -> "UntilUsed"
  Duration.UntilEvent {} -> "UntilEvent"
