module Parun.Codec.EachCardInGraveyardSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.EachCardInGraveyard as EachCardInGraveyard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.EachCardInGraveyard as EachCardInGraveyard
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.ZoneScope as ZoneScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EachCardInGraveyard" $ do
  -- CR 404.1, Gaea's Blessing's shape.
  Spec.it s "MkEachCardInGraveyard, both keys" $
    Common.assertCodec
      s
      EachCardInGraveyard.codec
      ( EachCardInGraveyard.MkEachCardInGraveyard
          { EachCardInGraveyard.graveyards = ZoneScope.Scoped (PlayerScope.Related PlayerRelation.You),
            EachCardInGraveyard.filter = Filter.HasCardType CardType.Creature
          }
      )
      " {\"graveyards\":{\"type\":\"Scoped\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- The arm the PlayerScope this field used to hold could not say: Angel of
  -- Finality's "target player's graveyard"; see #1310.
  Spec.it s "MkEachCardInGraveyard, a slot-named graveyard" $
    Common.assertCodec
      s
      EachCardInGraveyard.codec
      ( EachCardInGraveyard.MkEachCardInGraveyard
          { EachCardInGraveyard.graveyards = ZoneScope.InSlot (SlotName.MkSlotName (Text.pack "player")),
            EachCardInGraveyard.filter = Filter.HasCardType CardType.Creature
          }
      )
      " {\"graveyards\":{\"type\":\"InSlot\",\"value\":\"player\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EachCardInGraveyard.codec
