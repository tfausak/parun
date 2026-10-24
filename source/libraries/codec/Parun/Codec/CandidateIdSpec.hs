module Parun.Codec.CandidateIdSpec where

import qualified Parun.Codec.CandidateId as CandidateId
import qualified Parun.Codec.PermanentCandidateSpec as PermanentCandidateSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CandidateId as CandidateId
import qualified Parun.Types.FloatingCandidate as FloatingCandidate
import qualified Parun.Types.InstanceOrdinal as InstanceOrdinal
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PermanentCandidate as PermanentCandidate
import qualified Parun.Types.ReplacementProvenance as ReplacementProvenance
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CandidateId" $ do
  Spec.it s "OfPermanent" $
    Common.assertCodec
      s
      CandidateId.codec
      ( CandidateId.OfPermanent
          PermanentCandidate.MkPermanentCandidate
            { PermanentCandidate.source = ObjectId.MkObjectId 4,
              PermanentCandidate.provenance = ReplacementProvenance.Printed,
              PermanentCandidate.effect = PermanentCandidateSpec.effect,
              PermanentCandidate.ordinal = InstanceOrdinal.MkInstanceOrdinal 0
            }
      )
      " {\"type\":\"OfPermanent\",\"value\":{\"source\":4,\"provenance\":{\"type\":\"Printed\"},\"effect\":{\"type\":\"ZoneChangeR\",\"value\":{\"matching\":{\"whenDestination\":{\"type\":\"Graveyard\"}},\"destination\":{\"type\":\"Exile\"}}},\"ordinal\":0}} "
  Spec.it s "OfFloating" $
    Common.assertCodec
      s
      CandidateId.codec
      ( CandidateId.OfFloating
          FloatingCandidate.MkFloatingCandidate
            { FloatingCandidate.source = ObjectId.MkObjectId 3,
              FloatingCandidate.timestamp = Timestamp.MkTimestamp 8
            }
      )
      " {\"type\":\"OfFloating\",\"value\":{\"source\":3,\"timestamp\":8}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CandidateId.codec
