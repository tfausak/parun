module Parun.Codec.LeavesZoneTriggerSpec where

import qualified Parun.Codec.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LeavesZoneTrigger" $ do
  -- Oglor, Devoted Assistant's grant: "when this card leaves your graveyard".
  Spec.it s "writes only the zone left for the defaults" $
    Common.assertCodec
      s
      LeavesZoneTrigger.codec
      (LeavesZoneTrigger.self Zone.Graveyard)
      " {\"from\":\"Graveyard\"} "
  -- Kishla Skimmer: whose graveyard the card left, and whose turn it has to be.
  Spec.it s "round-trips a Matching card, a pile and a turn" $
    Common.assertCodec
      s
      LeavesZoneTrigger.codec
      (LeavesZoneTrigger.self Zone.Graveyard)
        { LeavesZoneTrigger.card = ActingPermanent.Matching (Filter.Not Filter.IsToken),
          LeavesZoneTrigger.whose = Just PlayerRelation.You,
          LeavesZoneTrigger.scope = TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.You)
        }
      " {\"card\":{\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}},\"from\":\"Graveyard\",\"whose\":\"You\",\"scope\":{\"type\":\"PlayersTurn\",\"value\":{\"type\":\"Relative\",\"value\":\"You\"}}} "
  -- Rakshasa Vizier: a destination, once per batch.
  Spec.it s "round-trips a destination and a batch" $
    Common.assertCodec
      s
      LeavesZoneTrigger.codec
      (LeavesZoneTrigger.self Zone.Graveyard)
        { LeavesZoneTrigger.to = Just Zone.Exile,
          LeavesZoneTrigger.batching = Batching.OneOrMore
        }
      " {\"from\":\"Graveyard\",\"to\":\"Exile\",\"batching\":\"OneOrMore\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LeavesZoneTrigger.codec
