module Parun.Codec.MentoredSpec where

import qualified Parun.Codec.Mentored as Mentored
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Mentored as Mentored
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Mentored" $ do
  -- CR 702.134a. BOTH keys are an ObjectId, so the fixture names them
  -- differently on purpose: only an asymmetric case catches a codec that
  -- credited the wrong creature.
  Spec.it s "MkMentored, both keys" $
    Common.assertCodec
      s
      Mentored.codec
      ( Mentored.MkMentored
          { Mentored.mentor = ObjectId.MkObjectId 1,
            Mentored.mentored = ObjectId.MkObjectId 2
          }
      )
      " {\"mentor\":1,\"mentored\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Mentored.codec
