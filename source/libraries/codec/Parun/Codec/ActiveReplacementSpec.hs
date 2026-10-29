module Parun.Codec.ActiveReplacementSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.ActiveReplacement as ActiveReplacement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SourceChoices as SourceChoices
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern
import qualified Parun.Types.ZoneChangeR as ZoneChangeR

-- | Rest in Peace's rewrite, borrowed from Parun.Codec.ReplacementEffectSpec: the
-- payload is not what this module has to prove, so the same value serves both
-- cases below.
effect :: ReplacementEffect.ReplacementEffect card ability (Effect.Effect card ability)
effect =
  ReplacementEffect.ZoneChangeR
    ( ZoneChangeR.MkZoneChangeR
        ZoneChangePattern.MkZoneChangePattern
          { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
            ZoneChangePattern.whatObject = Filter.And [],
            ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
            ZoneChangePattern.whenDiscarded = Nothing,
            ZoneChangePattern.causedBy = Nothing,
            ZoneChangePattern.duringResolution = False
          }
        Zone.Exile
        False
        False
        LibraryPosition.defaultValue
        False
    )

effectJson :: String
effectJson = "{\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"}},\"destination\":{\"type\":\"Exile\"}}}"

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveReplacement" $ do
  -- CR 614.3: the row most installers write -- no printed clause, no CR 615.5
  -- rider, and no CR 603.7c slot snapshot. `origin` is Other, which is CR
  -- 614.15's "other replacement effects".
  Spec.it s "a bare floating row" $
    Common.assertCodec
      s
      ActiveReplacement.codec
      ActiveReplacement.MkActiveReplacement
        { ActiveReplacement.effect = effect,
          ActiveReplacement.source = ObjectId.MkObjectId 1,
          ActiveReplacement.controller = PlayerId.MkPlayerId 2,
          ActiveReplacement.timestamp = Timestamp.MkTimestamp 3,
          ActiveReplacement.expiry = Expiry.AtCleanup,
          ActiveReplacement.uses = Uses.Unlimited,
          ActiveReplacement.origin = ReplacementOrigin.Other,
          ActiveReplacement.condition = Nothing,
          ActiveReplacement.rider = Nothing,
          ActiveReplacement.slots = Map.empty,
          ActiveReplacement.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.empty, SourceChoices.subtype = Nothing}
        }
      ( " {\"effect\":"
          <> effectJson
          <> ",\"source\":1,\"controller\":2,\"timestamp\":3,\"expiry\":{\"type\":\"AtCleanup\"}"
          <> ",\"uses\":{\"type\":\"Unlimited\"},\"origin\":{\"type\":\"Other\"}"
          <> ",\"condition\":null,\"rider\":null,\"slots\":{},\"choices\":{}} "
      )
  -- Every optional axis at once, each away from the case above: CR 614.1's
  -- printed "if", CR 615.5's rider, CR 614.3's used-up count, CR 614.15's
  -- self-replacement, CR 603.7c's snapshot, and CR 608.2h's baked choices. The snapshot's value is a SET of
  -- two ids, so an encoder writing only one is caught.
  Spec.it s "a row carrying a clause, a rider and a slot snapshot" $
    Common.assertCodec
      s
      ActiveReplacement.codec
      ActiveReplacement.MkActiveReplacement
        { ActiveReplacement.effect = effect,
          ActiveReplacement.source = ObjectId.MkObjectId 4,
          ActiveReplacement.controller = PlayerId.MkPlayerId 5,
          ActiveReplacement.timestamp = Timestamp.MkTimestamp 6,
          ActiveReplacement.expiry = Expiry.Never,
          ActiveReplacement.uses = Uses.Once,
          ActiveReplacement.origin = ReplacementOrigin.SelfReplacement,
          ActiveReplacement.condition =
            Just (Condition.Compares (Compares.MkCompares (Quantity.Measure Measure.Power) Comparison.AtLeast (Quantity.Literal 7))),
          ActiveReplacement.rider =
            Just
              PreventionRider.MkPreventionRider
                { PreventionRider.effects = Seq.fromList [Effect.Proliferate],
                  PreventionRider.targets = Map.empty,
                  PreventionRider.controller = PlayerId.MkPlayerId 5,
                  PreventionRider.source = ObjectId.MkObjectId 4
                },
          ActiveReplacement.slots =
            Map.singleton
              (SlotName.MkSlotName (Text.pack "that spell"))
              (Set.fromList [ObjectId.MkObjectId 8, ObjectId.MkObjectId 9]),
          ActiveReplacement.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.singleton Color.White, SourceChoices.subtype = Nothing}
        }
      ( " {\"effect\":"
          <> effectJson
          <> ",\"source\":4,\"controller\":5,\"timestamp\":6,\"expiry\":{\"type\":\"Never\"}"
          <> ",\"uses\":{\"type\":\"Once\"},\"origin\":{\"type\":\"SelfReplacement\"}"
          <> ",\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":7}}}"
          <> ",\"rider\":{\"effects\":[{\"type\":\"Proliferate\"}],\"targets\":{},\"controller\":5,\"source\":4}"
          <> ",\"slots\":{\"that spell\":[8,9]},\"choices\":{\"colors\":[{\"type\":\"White\"}]}} "
      )
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveReplacement.codec
