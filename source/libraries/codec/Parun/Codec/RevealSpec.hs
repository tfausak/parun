module Parun.Codec.RevealSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Reveal as Reveal
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCardInHand as RandomCardInHand
import qualified Parun.Types.Reveal as Reveal
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Reveal" $ do
  -- CR 701.20a on its own, which is every printing but Wild Evocation: the slot
  -- key is absent rather than null.
  Spec.it s "MkReveal, slot elided" $
    Common.assertCodec
      s
      Reveal.codec
      ( Reveal.MkReveal
          { Reveal.ref = ObjectRef.RandomCardInHand (RandomCardInHand.MkRandomCardInHand (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer"))) (Filter.And []) (Quantity.Literal 1)),
            Reveal.slot = Nothing
          }
      )
      " {\"ref\":{\"type\":\"RandomCardInHand\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"}}}} "
  -- Wild Evocation's reveal, whose later clauses name what it showed.
  Spec.it s "MkReveal, slot written" $
    Common.assertCodec
      s
      Reveal.codec
      ( Reveal.MkReveal
          { Reveal.ref = ObjectRef.RandomCardInHand (RandomCardInHand.MkRandomCardInHand (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer"))) (Filter.And []) (Quantity.Literal 1)),
            Reveal.slot = Just (SlotName.MkSlotName (Text.pack "revealed"))
          }
      )
      " {\"ref\":{\"type\":\"RandomCardInHand\",\"value\":{\"player\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"}}},\"slot\":\"revealed\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Reveal.codec
