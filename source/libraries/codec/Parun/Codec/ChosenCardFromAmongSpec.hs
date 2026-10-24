module Parun.Codec.ChosenCardFromAmongSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChosenCardFromAmong" $ do
  -- Commune with the Gods' "a creature or enchantment card from among them": the
  -- slot names the group an earlier clause bound, and the Filter narrows what may
  -- be picked out of it.
  Spec.it s "MkChosenCardFromAmong, the two required keys" $
    Common.assertCodec
      s
      ChosenCardFromAmong.codec
      ( ChosenCardFromAmong.MkChosenCardFromAmong
          { ChosenCardFromAmong.slot = SlotName.MkSlotName (Text.pack "revealed"),
            ChosenCardFromAmong.filter = Filter.HasCardType CardType.Creature,
            ChosenCardFromAmong.count = HowMany.one,
            ChosenCardFromAmong.chooser = PlayerRef.Relative PlayerRelation.You
          }
      )
      " {\"slot\":\"revealed\",\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Uncovered Clues' "up to two" and Animal Magnetism's opponent: the two keys
  -- the defaults above leave off the wire entirely.
  Spec.it s "MkChosenCardFromAmong, all four keys" $
    Common.assertCodec
      s
      ChosenCardFromAmong.codec
      ( ChosenCardFromAmong.MkChosenCardFromAmong
          { ChosenCardFromAmong.slot = SlotName.MkSlotName (Text.pack "revealed"),
            ChosenCardFromAmong.filter = Filter.HasCardType CardType.Creature,
            ChosenCardFromAmong.count = HowMany.UpTo (Just (Quantity.Literal 2)),
            ChosenCardFromAmong.chooser = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "opponent"))
          }
      )
      " {\"slot\":\"revealed\",\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"count\":{\"type\":\"UpTo\",\"value\":{\"type\":\"Literal\",\"value\":2}},\"chooser\":{\"type\":\"InSlot\",\"value\":\"opponent\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChosenCardFromAmong.codec
