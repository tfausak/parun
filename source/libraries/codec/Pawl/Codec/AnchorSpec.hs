module Pawl.Codec.AnchorSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.Anchor as Anchor
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Anchor as Anchor
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Anchor" $ do
  Spec.it s "Bound" $
    Common.assertCodec
      s
      Anchor.codec
      (Anchor.Bound (SlotName.MkSlotName (Text.pack "thatDepartedPermanent")))
      " {\"type\":\"Bound\",\"value\":\"thatDepartedPermanent\"} "
  Spec.it s "Evaluated" $
    Common.assertCodec
      s
      Anchor.codec
      Anchor.Evaluated
      " {\"type\":\"Evaluated\"} "
