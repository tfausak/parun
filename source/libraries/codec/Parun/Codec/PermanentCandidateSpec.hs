module Parun.Codec.PermanentCandidateSpec where

import qualified Parun.Codec.PermanentCandidate as PermanentCandidate
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InstanceOrdinal as InstanceOrdinal
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PermanentCandidate as PermanentCandidate
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementProvenance as ReplacementProvenance
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern
import qualified Parun.Types.ZoneChangeR as ZoneChangeR

-- Rest in Peace's rewrite, borrowed from Parun.Codec.ReplacementEffectSpec, since
-- what this module is about is the RECORD around the effect rather than the
-- effect itself.
effect :: ReplacementEffect.ReplacementEffect card ability a
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

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentCandidate" $ do
  Spec.it s "the first instance of an ability" $
    Common.assertCodec
      s
      PermanentCandidate.codec
      PermanentCandidate.MkPermanentCandidate
        { PermanentCandidate.source = ObjectId.MkObjectId 4,
          PermanentCandidate.provenance = ReplacementProvenance.Printed,
          PermanentCandidate.effect = effect,
          PermanentCandidate.ordinal = InstanceOrdinal.MkInstanceOrdinal 0
        }
      " {\"source\":4,\"provenance\":{\"type\":\"Printed\"},\"effect\":{\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"}},\"destination\":{\"type\":\"Exile\"}}},\"ordinal\":0} "
  -- CR 702.136b: the SECOND instance of an equal ability on one source is a
  -- different identity, and the ordinal is the only field that says so.
  Spec.it s "the second instance of the same ability" $
    Common.assertCodec
      s
      PermanentCandidate.codec
      PermanentCandidate.MkPermanentCandidate
        { PermanentCandidate.source = ObjectId.MkObjectId 4,
          PermanentCandidate.provenance = ReplacementProvenance.Minted,
          PermanentCandidate.effect = effect,
          PermanentCandidate.ordinal = InstanceOrdinal.MkInstanceOrdinal 1
        }
      " {\"source\":4,\"provenance\":{\"type\":\"Minted\"},\"effect\":{\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"}},\"destination\":{\"type\":\"Exile\"}}},\"ordinal\":1} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PermanentCandidate.codec
