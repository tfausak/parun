module Parun.Codec.UntilPaidSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.UntilPaid as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.UntilPaid as UntilPaid

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.UntilPaid" $ do
  let one = Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []
  Spec.it s "MkUntilPaid, the default payer elided" $
    Common.assertCodec
      s
      Codec.codec
      (UntilPaid.MkUntilPaid (PlayerRef.Relative PlayerRelation.You) one)
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}} "
  Spec.it s "MkUntilPaid, a payer named by slot" $
    Common.assertCodec
      s
      Codec.codec
      (UntilPaid.MkUntilPaid (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer"))) one)
      " {\"payer\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"},\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Codec.codec
