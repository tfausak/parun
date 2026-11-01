module Parun.Codec.AnchorSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Anchor as Anchor
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Anchor" $ do
  Spec.it s "Bound" $
    Common.assertCodec
      s
      codec
      (Anchor.Bound (SlotName.MkSlotName (Text.pack "thatDepartedPermanent")))
      " {\"type\":\"Bound\",\"value\":\"thatDepartedPermanent\"} "
  Spec.it s "Evaluated" $
    Common.assertCodec
      s
      codec
      Anchor.Evaluated
      " {\"type\":\"Evaluated\"} "
  Spec.it s "Source" $
    Common.assertCodec
      s
      codec
      Anchor.Source
      " {\"type\":\"Source\"} "
  Spec.it s "AnyPermanent" $
    Common.assertCodec
      s
      codec
      (Anchor.AnyPermanent (Filter.Type.HasCardType CardType.Creature))
      " {\"type\":\"AnyPermanent\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "

codec :: Codec.Codec (Anchor.Anchor (Filter.Type.Filter Keyword.Type.Keyword))
codec = Anchor.codec (Filter.codec Keyword.codec)
