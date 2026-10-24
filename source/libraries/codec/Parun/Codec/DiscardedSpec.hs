module Parun.Codec.DiscardedSpec where

import qualified Parun.Codec.Discarded as Discarded
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DiscardCause as DiscardCause
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.MadnessCost as MadnessCost
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Discarded" $ do
  -- CR 702.29a's cycle, which is the case the cause field exists for: one act
  -- that must answer both "was a card discarded?" and "was it cycled?".
  Spec.it s "MkDiscarded, a cycle" $
    Common.assertCodec
      s
      Discarded.codec
      ( Discarded.MkDiscarded
          { Discarded.player = PlayerId.MkPlayerId 0,
            Discarded.card = ObjectId.MkObjectId 7,
            Discarded.cause = DiscardCause.ToPayCyclingCost,
            Discarded.madness = Nothing,
            Discarded.causedBy = Nothing
          }
      )
      " {\"player\":0,\"card\":7,\"cause\":{\"type\":\"ToPayCyclingCost\"},\"madness\":null} "
  -- CR 702.35a's "exiled this way", the field's other value: an ordinary discard
  -- that rule 702.35a's own replacement redirected into exile.
  Spec.it s "MkDiscarded, a madness exile" $
    Common.assertCodec
      s
      Discarded.codec
      ( Discarded.MkDiscarded
          { Discarded.player = PlayerId.MkPlayerId 1,
            Discarded.card = ObjectId.MkObjectId 5,
            Discarded.cause = DiscardCause.Ordinary,
            Discarded.madness = Just MadnessCost.OwnManaCost,
            Discarded.causedBy = Nothing
          }
      )
      " {\"player\":1,\"card\":5,\"cause\":{\"type\":\"Ordinary\"},\"madness\":{\"type\":\"OwnManaCost\"}} "
  -- CR 609.1's cause: a discard an opponent's effect made, the one shape the
  -- defaulted key appears in.
  Spec.it s "MkDiscarded, CR 609.1's discard an effect made" $
    Common.assertCodec
      s
      Discarded.codec
      ( Discarded.MkDiscarded
          { Discarded.player = PlayerId.MkPlayerId 0,
            Discarded.card = ObjectId.MkObjectId 4,
            Discarded.cause = DiscardCause.ByEffect,
            Discarded.madness = Nothing,
            Discarded.causedBy = Just (PlayerId.MkPlayerId 1)
          }
      )
      " {\"player\":0,\"card\":4,\"cause\":{\"type\":\"ByEffect\"},\"madness\":null,\"causedBy\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Discarded.codec
