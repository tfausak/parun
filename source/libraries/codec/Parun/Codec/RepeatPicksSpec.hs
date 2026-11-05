module Parun.Codec.RepeatPicksSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.RepeatPicks as RepeatPicks
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RepeatPicks as RepeatPicks

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RepeatPicks" $ do
  Spec.it s "MkRepeatPicks, nothing picked or refused" $
    Common.assertCodec
      s
      RepeatPicks.codec
      (RepeatPicks.MkRepeatPicks {RepeatPicks.picked = Map.empty, RepeatPicks.refused = Map.empty})
      " {} "

  Spec.it s "MkRepeatPicks, a pick and a refusal" $
    Common.assertCodec
      s
      RepeatPicks.codec
      ( RepeatPicks.MkRepeatPicks
          { RepeatPicks.picked = Map.singleton (PlayerId.MkPlayerId 1) (Set.singleton (ObjectId.MkObjectId 7)),
            RepeatPicks.refused = Map.singleton (PlayerId.MkPlayerId 0) (Set.singleton (ObjectId.MkObjectId 7))
          }
      )
      " {\"picked\":{\"1\":[7]},\"refused\":{\"0\":[7]}} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s RepeatPicks.codec
