module Parun.Codec.PutIntoZoneTriggerSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PutIntoZoneTrigger" $ do
  -- Serra Avatar: "put into a graveyard from anywhere".
  Spec.it s "writes only the destination for the defaults" $
    Common.assertCodec
      s
      PutIntoZoneTrigger.codec
      (PutIntoZoneTrigger.self Zone.Graveyard)
      " {\"to\":{\"type\":\"Graveyard\"}} "
  -- Narcomoeba: from the library.
  Spec.it s "round-trips an origin" $
    Common.assertCodec
      s
      PutIntoZoneTrigger.codec
      (PutIntoZoneTrigger.self Zone.Graveyard) {PutIntoZoneTrigger.from = Set.singleton Zone.Library}
      " {\"from\":[{\"type\":\"Library\"}],\"to\":{\"type\":\"Graveyard\"}} "
  -- CR 702.55a's haunt: during its resolution.
  Spec.it s "round-trips duringResolution" $
    Common.assertCodec
      s
      PutIntoZoneTrigger.codec
      (PutIntoZoneTrigger.self Zone.Graveyard) {PutIntoZoneTrigger.duringResolution = True}
      " {\"to\":{\"type\":\"Graveyard\"},\"duringResolution\":true} "
  -- Stonebinder's Familiar: cards, into exile, during your turn, once per batch.
  Spec.it s "round-trips a Matching card, a turn and a batch" $
    Common.assertCodec
      s
      PutIntoZoneTrigger.codec
      (PutIntoZoneTrigger.self Zone.Exile)
        { PutIntoZoneTrigger.card = ActingPermanent.Matching (Filter.Not Filter.IsToken),
          PutIntoZoneTrigger.scope = TurnScope.ControllersTurn,
          PutIntoZoneTrigger.batching = Batching.OneOrMore
        }
      " {\"card\":{\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}},\"to\":{\"type\":\"Exile\"},\"scope\":{\"type\":\"ControllersTurn\"},\"batching\":{\"type\":\"OneOrMore\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PutIntoZoneTrigger.codec
