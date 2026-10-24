module Parun.Codec.PendingReplacementEffectSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PendingReplacementEffect" $ do
  -- CR 614.1a: the program, plus the environment snapshotted when the rewrite
  -- applied. The slot map is what makes "that creature" nameable at the drain,
  -- so it is on the wire beside the effects.
  Spec.it s "a queued damage-replacement effect and the environment it runs in" $
    Common.assertCodec
      s
      PendingReplacementEffect.codec
      PendingReplacementEffect.MkPendingReplacementEffect
        { PendingReplacementEffect.effects = Seq.fromList [Effect.Proliferate],
          PendingReplacementEffect.targets = Map.singleton (SlotName.MkSlotName (Text.pack "creature")) (Set.singleton (Recipient.ToObject (ObjectId.MkObjectId 5))),
          PendingReplacementEffect.controller = PlayerId.MkPlayerId 1,
          PendingReplacementEffect.source = ObjectId.MkObjectId 3
        }
      " {\"effects\":[{\"type\":\"Proliferate\"}],\"targets\":{\"creature\":[{\"type\":\"ToObject\",\"value\":5}]},\"controller\":1,\"source\":3} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PendingReplacementEffect.codec
