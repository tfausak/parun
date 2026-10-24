module Parun.Codec.CardLeavesZoneSpec where

import qualified Parun.Codec.CardLeavesZone as CardLeavesZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardLeavesZone as CardLeavesZone
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardLeavesZone" $ do
  -- Kishla Skimmer's payload: whose graveyard the card left, and whose turn it
  -- has to be.
  Spec.it s "MkCardLeavesZone, no destination" $
    Common.assertCodec
      s
      CardLeavesZone.codec
      ( CardLeavesZone.MkCardLeavesZone
          { CardLeavesZone.filter = Filter.Not Filter.IsToken,
            CardLeavesZone.scope = TurnScope.ControllersTurn,
            CardLeavesZone.from = Zone.Graveyard,
            CardLeavesZone.to = Nothing,
            CardLeavesZone.whose = Just PlayerRelation.You
          }
      )
      " {\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"ControllersTurn\"},\"from\":{\"type\":\"Graveyard\"},\"whose\":{\"type\":\"You\"}} "
  -- A destination, and no `whose`: "a card leaves a graveyard" names no pile's
  -- player, so the key is left out.
  Spec.it s "MkCardLeavesZone, with a destination" $
    Common.assertCodec
      s
      CardLeavesZone.codec
      ( CardLeavesZone.MkCardLeavesZone
          { CardLeavesZone.filter = Filter.Not Filter.IsToken,
            CardLeavesZone.scope = TurnScope.EachTurn,
            CardLeavesZone.from = Zone.Graveyard,
            CardLeavesZone.to = Just Zone.Exile,
            CardLeavesZone.whose = Nothing
          }
      )
      " {\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"EachTurn\"},\"from\":{\"type\":\"Graveyard\"},\"to\":{\"type\":\"Exile\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CardLeavesZone.codec
