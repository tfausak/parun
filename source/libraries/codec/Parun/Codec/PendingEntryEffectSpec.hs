module Parun.Codec.PendingEntryEffectSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.PendingEntryEffect as PendingEntryEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PendingEntryEffect as PendingEntryEffect
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PendingEntryEffect" $ do
  -- CR 614.1c: the program, plus the environment read at APPLICATION. The
  -- controller is not the permanent's owner and cannot be re-derived at drain
  -- time (CR 614.12), which is why it is on the wire beside the effects.
  Spec.it s "a queued entry effect and the environment it runs in" $
    Common.assertCodec
      s
      PendingEntryEffect.codec
      PendingEntryEffect.MkPendingEntryEffect
        { PendingEntryEffect.object = ObjectId.MkObjectId 3,
          PendingEntryEffect.controller = PlayerId.MkPlayerId 1,
          PendingEntryEffect.effects = Seq.fromList [Effect.Proliferate]
        }
      " {\"object\":3,\"controller\":1,\"effects\":[{\"type\":\"Proliferate\"}]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PendingEntryEffect.codec
