module Parun.Codec.ExpirySpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Types.AfterTurn as AfterTurn
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.EventExpiry as EventExpiry
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PaidExpiry as PaidExpiry
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.While as While

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Expiry" $ do
  -- CR 514.2.
  Spec.it s "AtCleanup" $
    Common.assertCodec
      s
      Expiry.codec
      Expiry.AtCleanup
      " {\"type\":\"AtCleanup\"} "
  -- CR 611.2a: no sweep ends it.
  Spec.it s "Never" $
    Common.assertCodec
      s
      Expiry.codec
      Expiry.Never
      " {\"type\":\"Never\"} "
  -- Alchemy's "perpetually", stored. Distinct on the wire from Never above for
  -- the reason WhenPaid below is: Parun.Engine.Event.perpetuate finds the effects
  -- a zone change re-anchors by this arm, so the two cannot be collapsed.
  Spec.it s "Perpetual" $ do
    Common.assertCodec
      s
      Expiry.codec
      Expiry.Perpetual
      " {\"type\":\"Perpetual\"} "
    Spec.assertBool
      s
      (Codec.encode Expiry.codec Expiry.Perpetual /= Codec.encode Expiry.codec Expiry.Never)
      "perpetual and never encode differently"
  -- CR 611.2b, baked with the concrete PlayerId CR 109.5's "you" resolves to.
  Spec.it s "While carries its player and condition" $
    Common.assertCodec
      s
      Expiry.codec
      ( Expiry.While
          While.MkWhile
            { While.player = PlayerId.MkPlayerId 0,
              While.condition = Condition.Compares (Compares.MkCompares (Quantity.Literal 0) Comparison.Exactly (Quantity.Literal 0))
            }
      )
      " {\"type\":\"While\",\"value\":{\"player\":0,\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":0},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}}} "
  -- CR 611.2a, as a concrete player.
  Spec.it s "AtTurnOf carries its player" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.AtTurnOf (PlayerId.MkPlayerId 1))
      " {\"type\":\"AtTurnOf\",\"value\":1} "
  -- CR 611.2a: until that step of that player's turn next begins.
  Spec.it s "AtStepOf carries its step and player" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.AtStepOf (StepBegan.MkStepBegan (Phase.Beginning BeginningStep.Upkeep) (PlayerId.MkPlayerId 2)))
      " {\"type\":\"AtStepOf\",\"value\":{\"phase\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}},\"player\":2}} "
  -- CR 611.2a's other phrasing, which needs the turn as well as the player: the
  -- effect ends at the end of the first turn of theirs numbered above it.
  Spec.it s "AtEndOfTurnOf carries its player and turn" $
    Common.assertCodec
      s
      Expiry.codec
      ( Expiry.AtEndOfTurnOf
          AfterTurn.MkAfterTurn
            { AfterTurn.player = PlayerId.MkPlayerId 1,
              AfterTurn.turn = 3
            }
      )
      " {\"type\":\"AtEndOfTurnOf\",\"value\":{\"player\":1,\"turn\":3}} "
  -- CR 611.2a: the arm above's pair under an arm that also states a BEGINNING,
  -- so the wire format is the same pair under its own tag -- which is what a
  -- delayed trigger's stored duration has to survive.
  Spec.it s "DuringTurnOf carries its player and turn" $
    Common.assertCodec
      s
      Expiry.codec
      ( Expiry.DuringTurnOf
          AfterTurn.MkAfterTurn
            { AfterTurn.player = PlayerId.MkPlayerId 1,
              AfterTurn.turn = 3
            }
      )
      " {\"type\":\"DuringTurnOf\",\"value\":{\"player\":1,\"turn\":3}} "
  Spec.it s "DuringUntapStepOf carries its player" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.DuringUntapStepOf (PlayerId.MkPlayerId 2))
      " {\"type\":\"DuringUntapStepOf\",\"value\":2} "
  Spec.it s "DuringTurnOfControllerOf carries its object and turn" $
    Common.assertCodec
      s
      Expiry.codec
      ( Expiry.DuringTurnOfControllerOf
          AfterObjectTurn.MkAfterObjectTurn
            { AfterObjectTurn.object = ObjectId.MkObjectId 5,
              AfterObjectTurn.turn = 3
            }
      )
      " {\"type\":\"DuringTurnOfControllerOf\",\"value\":{\"object\":5,\"turn\":3}} "
  -- CR 500.7: the extra turn's creation stamp, the identity a later-created
  -- extra turn cannot share.
  Spec.it s "DuringExtraTurn carries its creation stamp" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.DuringExtraTurn (Timestamp.MkTimestamp 12))
      " {\"type\":\"DuringExtraTurn\",\"value\":12} "
  -- CR 500.5, carrying the PhaseSelector window. Both grains -- a stepless
  -- phase and a step -- because Parun.Engine.Expiry.dropAtEndOf tells them apart
  -- by EQUALITY, so a codec that collapsed them would let the end of a combat
  -- step end an effect stored against the whole combat phase.
  Spec.it s "AtEndOf carries its window" $ do
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.AtEndOf PhaseSelector.CombatPhase)
      " {\"type\":\"AtEndOf\",\"value\":{\"type\":\"CombatPhase\"}} "
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.AtEndOf (PhaseSelector.Step (Phase.Combat CombatStep.EndOfCombat)))
      " {\"type\":\"AtEndOf\",\"value\":{\"type\":\"Step\",\"value\":{\"type\":\"Combat\",\"value\":{\"type\":\"EndOfCombat\"}}}} "
    Spec.assertBool
      s
      (Codec.encode Expiry.codec (Expiry.AtEndOf PhaseSelector.CombatPhase) /= Codec.encode Expiry.codec (Expiry.AtEndOf (PhaseSelector.Step (Phase.Combat CombatStep.EndOfCombat))))
      "the phase and its own end-of-combat step encode differently"
  -- CR 500.5a / 611.2a: AtEndOfTurnOf's pair under its own tag.
  Spec.it s "AtEndOfCombatOn carries its player and turn" $
    Common.assertCodec
      s
      Expiry.codec
      ( Expiry.AtEndOfCombatOn
          AfterTurn.MkAfterTurn
            { AfterTurn.player = PlayerId.MkPlayerId 1,
              AfterTurn.turn = 3
            }
      )
      " {\"type\":\"AtEndOfCombatOn\",\"value\":{\"player\":1,\"turn\":3}} "
  -- CR 116.2c, carrying the price the offer quotes and the seat CR 109.5 gives
  -- it. Distinct from Never, which outlasts every window too:
  -- Parun.Engine.EndEffect finds the effects a payment ends by this arm, so the
  -- two cannot be collapsed.
  Spec.it s "WhenPaid carries the cost and the seat" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.WhenPaid (PaidExpiry.MkPaidExpiry (PlayerId.MkPlayerId 2) (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Blue)])) [])))
      " {\"type\":\"WhenPaid\",\"value\":{\"player\":2,\"cost\":{\"mana\":[{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Blue\"}}}]}}} "
  -- CR 611.2a: the one-shot Duration.UntilUsed arms into, distinct from
  -- AtCleanup, which it also honours.
  Spec.it s "WhenUsed" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.WhenUsed Nothing)
      " {\"type\":\"WhenUsed\"} "
  Spec.it s "WhenUsed, binding a slot" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.WhenUsed (Just (SlotName.MkSlotName (Text.pack "nextSpell"))))
      " {\"type\":\"WhenUsed\",\"value\":\"nextSpell\"} "
  -- CR 611.2a: what Duration.UntilEvent arms into.
  Spec.it s "OnEvent" $
    Common.assertCodec
      s
      Expiry.codec
      (Expiry.OnEvent (EventExpiry.MkEventExpiry (PlayerId.MkPlayerId 0) DurationEvent.SourceTurnedFaceDown))
      " {\"type\":\"OnEvent\",\"value\":{\"controller\":0,\"event\":{\"type\":\"SourceTurnedFaceDown\"}}} "
