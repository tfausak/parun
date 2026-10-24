module Parun.Codec.Expiry where

import qualified Parun.Codec.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Codec.AfterTurn as AfterTurn
import qualified Parun.Codec.EventExpiry as EventExpiry
import qualified Parun.Codec.PaidExpiry as PaidExpiry
import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.StepBegan as StepBegan
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.While as While
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Expiry as Expiry

-- | CR 611.2: the STORED duration, which never appears in card JSON -- a card
-- carries a Duration and Parun.Engine.Expiry.arm turns it into this. The one
-- thing that serialises an Expiry is a DelayedTrigger, since CR 603.7b lets a
-- delayed ability state one.
codec :: Codec.Codec Expiry.Expiry
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AtCleanup" Expiry.AtCleanup,
      Arm.nullary "Never" Expiry.Never,
      Arm.nullary "Perpetual" Expiry.Perpetual,
      Arm.payload "While" While.codec Expiry.While (\x -> case x of Expiry.While y -> Just y; _ -> Nothing),
      Arm.payload "AtTurnOf" PlayerId.codec Expiry.AtTurnOf (\x -> case x of Expiry.AtTurnOf y -> Just y; _ -> Nothing),
      Arm.payload "AtStepOf" StepBegan.codec Expiry.AtStepOf (\x -> case x of Expiry.AtStepOf y -> Just y; _ -> Nothing),
      Arm.payload "AtEndOfTurnOf" AfterTurn.codec Expiry.AtEndOfTurnOf (\x -> case x of Expiry.AtEndOfTurnOf y -> Just y; _ -> Nothing),
      Arm.payload "DuringTurnOf" AfterTurn.codec Expiry.DuringTurnOf (\x -> case x of Expiry.DuringTurnOf y -> Just y; _ -> Nothing),
      Arm.payload "DuringUntapStepOf" PlayerId.codec Expiry.DuringUntapStepOf (\x -> case x of Expiry.DuringUntapStepOf y -> Just y; _ -> Nothing),
      Arm.payload "DuringTurnOfControllerOf" AfterObjectTurn.codec Expiry.DuringTurnOfControllerOf (\x -> case x of Expiry.DuringTurnOfControllerOf y -> Just y; _ -> Nothing),
      Arm.payload "DuringExtraTurn" Timestamp.codec Expiry.DuringExtraTurn (\x -> case x of Expiry.DuringExtraTurn y -> Just y; _ -> Nothing),
      Arm.payload "AtEndOf" PhaseSelector.codec Expiry.AtEndOf (\x -> case x of Expiry.AtEndOf y -> Just y; _ -> Nothing),
      Arm.payload "AtEndOfCombatOn" AfterTurn.codec Expiry.AtEndOfCombatOn (\x -> case x of Expiry.AtEndOfCombatOn y -> Just y; _ -> Nothing),
      Arm.payload "WhenPaid" PaidExpiry.codec Expiry.WhenPaid (\x -> case x of Expiry.WhenPaid y -> Just y; _ -> Nothing),
      Arm.nullary "WhenUsed" Expiry.WhenUsed,
      Arm.payload "OnEvent" EventExpiry.codec Expiry.OnEvent (\x -> case x of Expiry.OnEvent y -> Just y; _ -> Nothing)
    ]

tagOf :: Expiry.Expiry -> String
tagOf x = case x of
  Expiry.AtCleanup {} -> "AtCleanup"
  Expiry.Never {} -> "Never"
  Expiry.Perpetual {} -> "Perpetual"
  Expiry.While {} -> "While"
  Expiry.AtTurnOf {} -> "AtTurnOf"
  Expiry.AtStepOf {} -> "AtStepOf"
  Expiry.AtEndOfTurnOf {} -> "AtEndOfTurnOf"
  Expiry.DuringTurnOf {} -> "DuringTurnOf"
  Expiry.DuringUntapStepOf {} -> "DuringUntapStepOf"
  Expiry.DuringTurnOfControllerOf {} -> "DuringTurnOfControllerOf"
  Expiry.DuringExtraTurn {} -> "DuringExtraTurn"
  Expiry.AtEndOf {} -> "AtEndOf"
  Expiry.AtEndOfCombatOn {} -> "AtEndOfCombatOn"
  Expiry.WhenPaid {} -> "WhenPaid"
  Expiry.WhenUsed {} -> "WhenUsed"
  Expiry.OnEvent {} -> "OnEvent"
