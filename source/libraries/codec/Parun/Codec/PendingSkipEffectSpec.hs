module Parun.Codec.PendingSkipEffectSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Parun.Codec.PendingSkipEffect as PendingSkipEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.PendingSkipEffect as PendingSkipEffect
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PendingSkipEffect" $ do
  -- CR 614.10b / 732.3: the queued action and the turns to come as it was queued.
  Spec.it s "a queued skip action and the turn position it was queued at" $
    Common.assertCodec
      s
      PendingSkipEffect.codec
      PendingSkipEffect.MkPendingSkipEffect
        { PendingSkipEffect.pending =
            PendingReplacementEffect.MkPendingReplacementEffect
              { PendingReplacementEffect.effects = Seq.fromList [Effect.Proliferate],
                PendingReplacementEffect.targets = Map.empty,
                PendingReplacementEffect.controller = PlayerId.MkPlayerId 1,
                PendingReplacementEffect.source = ObjectId.MkObjectId 3
              },
          PendingSkipEffect.extraTurns = [],
          PendingSkipEffect.turnMarkers = []
        }
      " {\"pending\":{\"effects\":[{\"type\":\"Proliferate\"}],\"targets\":{},\"controller\":1,\"source\":3}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PendingSkipEffect.codec
