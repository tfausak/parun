module Parun.Codec.DrawSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Draw as Draw
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Draw" $ do
  -- A draw nothing looks back at omits the slot key; one that does writes it.
  Spec.it s "MkDraw, no slot: the key is omitted" $
    Common.assertCodec
      s
      Draw.codec
      (Draw.MkDraw (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 2) Nothing)
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "MkDraw, CR 121.1's drawn card remembered: the key is written" $
    Common.assertCodec
      s
      Draw.codec
      ( Draw.MkDraw
          (PlayerRef.Relative PlayerRelation.You)
          (Quantity.Literal 1)
          (Just (SlotName.MkSlotName (Text.pack "drawn")))
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":1},\"slot\":\"drawn\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Draw.codec
