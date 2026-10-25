module Parun.Codec.ChoosePermanentsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ChoosePermanents as ChoosePermanents
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChoosePermanents as ChoosePermanents
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChoosePermanents" $ do
  Spec.it s "MkChoosePermanents, the resolving controller choosing elides the chooser" $
    Common.assertCodec
      s
      ChoosePermanents.codec
      ( ChoosePermanents.MkChoosePermanents
          { ChoosePermanents.permanents = ChosenPermanents.MkChosenPermanents (Filter.HasCardType CardType.Creature) (PlayerRef.Relative PlayerRelation.You) (HowMany.UpTo Nothing) Zone.Battlefield,
            ChoosePermanents.slot = SlotName.MkSlotName (Text.pack "chosen"),
            ChoosePermanents.pileChooser = Nothing
          }
      )
      " {\"permanents\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"count\":{\"type\":\"UpTo\"}},\"slot\":\"chosen\"} "
  Spec.it s "MkChoosePermanents, another seat choosing up to two" $
    Common.assertCodec
      s
      ChoosePermanents.codec
      ( ChoosePermanents.MkChoosePermanents
          { ChoosePermanents.permanents = ChosenPermanents.MkChosenPermanents (Filter.HasCardType CardType.Creature) (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer"))) (HowMany.UpTo (Just (Quantity.Literal 2))) Zone.Battlefield,
            ChoosePermanents.slot = SlotName.MkSlotName (Text.pack "chosen"),
            ChoosePermanents.pileChooser = Nothing
          }
      )
      " {\"permanents\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"chooser\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"},\"count\":{\"type\":\"UpTo\",\"value\":{\"type\":\"Literal\",\"value\":2}}},\"slot\":\"chosen\"} "
  Spec.it s "MkChoosePermanents, a pile split whose piles a slot's seat chooses between" $
    Common.assertCodec
      s
      ChoosePermanents.codec
      ( ChoosePermanents.MkChoosePermanents
          { ChoosePermanents.permanents = ChosenPermanents.MkChosenPermanents (Filter.HasCardType CardType.Creature) (PlayerRef.Relative PlayerRelation.You) (HowMany.UpTo Nothing) Zone.Battlefield,
            ChoosePermanents.slot = SlotName.MkSlotName (Text.pack "chosen"),
            ChoosePermanents.pileChooser = Just (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "defender")))
          }
      )
      " {\"permanents\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"count\":{\"type\":\"UpTo\"}},\"slot\":\"chosen\",\"pileChooser\":{\"type\":\"InSlot\",\"value\":\"defender\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChoosePermanents.codec
