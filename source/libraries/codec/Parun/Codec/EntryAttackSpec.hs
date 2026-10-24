module Parun.Codec.EntryAttackSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.EntryAttack as EntryAttack
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryAttack as EntryAttack
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryAttack" $ do
  Spec.it s "Chosen" $
    Common.assertCodec s EntryAttack.codec EntryAttack.Chosen " {\"type\":\"Chosen\"} "
  Spec.it s "SameAs" $
    Common.assertCodec
      s
      EntryAttack.codec
      (EntryAttack.SameAs (SlotName.MkSlotName (Text.pack "thatReturnedPermanent")))
      " {\"type\":\"SameAs\",\"value\":\"thatReturnedPermanent\"} "
  Spec.it s "UnderPlayer" $
    Common.assertCodec
      s
      EntryAttack.codec
      (EntryAttack.UnderPlayer (SlotName.MkSlotName (Text.pack "myriad opponent")))
      " {\"type\":\"UnderPlayer\",\"value\":\"myriad opponent\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntryAttack.codec
