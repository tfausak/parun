module Parun.Codec.AnchorSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Anchor as Anchor
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Anchor" $ do
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
  Spec.it s "Source" $
    Common.assertCodec
      s
      Anchor.codec
      Anchor.Source
      " {\"type\":\"Source\"} "
