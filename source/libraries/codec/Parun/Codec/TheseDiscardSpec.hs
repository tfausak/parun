module Parun.Codec.TheseDiscardSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.TheseDiscard as TheseDiscard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TheseDiscard as TheseDiscard

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TheseDiscard" $ do
  Spec.it s "MkTheseDiscard, no bound slot" $
    Common.assertCodec
      s
      TheseDiscard.codec
      ( TheseDiscard.MkTheseDiscard
          { TheseDiscard.cards = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "revealed")),
            TheseDiscard.discarded = Nothing
          }
      )
      " {\"cards\":{\"type\":\"InSlot\",\"value\":\"revealed\"}} "
  Spec.it s "MkTheseDiscard, with the discarded slot" $
    Common.assertCodec
      s
      TheseDiscard.codec
      ( TheseDiscard.MkTheseDiscard
          { TheseDiscard.cards = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "revealed")),
            TheseDiscard.discarded = Just (SlotName.MkSlotName (Text.pack "discarded"))
          }
      )
      " {\"cards\":{\"type\":\"InSlot\",\"value\":\"revealed\"},\"discarded\":\"discarded\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TheseDiscard.codec
