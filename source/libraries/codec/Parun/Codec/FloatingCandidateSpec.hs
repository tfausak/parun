module Parun.Codec.FloatingCandidateSpec where

import qualified Parun.Codec.FloatingCandidate as FloatingCandidate
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.FloatingCandidate as FloatingCandidate
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FloatingCandidate" $ do
  -- The two fields are DISTINCT here, so an encoder that swapped them could not
  -- pass: both are naturals, and equal ones would round trip either way.
  Spec.it s "a floating identity" $
    Common.assertCodec
      s
      FloatingCandidate.codec
      FloatingCandidate.MkFloatingCandidate
        { FloatingCandidate.source = ObjectId.MkObjectId 3,
          FloatingCandidate.timestamp = Timestamp.MkTimestamp 8
        }
      " {\"source\":3,\"timestamp\":8} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s FloatingCandidate.codec
