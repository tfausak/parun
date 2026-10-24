module Parun.Codec.TopOfLibrarySpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.TopOfLibrary as TopOfLibrary
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TopOfLibrary as TopOfLibrary

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TopOfLibrary" $ do
  -- CR 401.2's ordered pile read from its head (CR 121.1). Act on Impulse's
  -- literal three.
  Spec.it s "MkTopOfLibrary, both keys" $
    Common.assertCodec
      s
      TopOfLibrary.codec
      ( TopOfLibrary.MkTopOfLibrary
          { TopOfLibrary.player = PlayerRef.Relative PlayerRelation.You,
            TopOfLibrary.count = Quantity.Literal 3
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"count\":{\"type\":\"Literal\",\"value\":3}} "
  -- CR 601.2b's announced X, which is what the depth being a full Quantity buys:
  -- Commune with Lava's "exile the top X cards of your library".
  Spec.it s "MkTopOfLibrary carries the announced X Commune with Lava needs" $
    Common.assertCodec
      s
      TopOfLibrary.codec
      ( TopOfLibrary.MkTopOfLibrary
          { TopOfLibrary.player = PlayerRef.Relative PlayerRelation.You,
            TopOfLibrary.count = Quantity.InSlot (SlotName.MkSlotName (Text.pack "X"))
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"count\":{\"type\":\"InSlot\",\"value\":\"X\"}} "
  -- The bare number was the depth's whole spelling before the widening, so a card
  -- file written against it is a decode failure rather than a silent literal.
  Spec.it s "a bare number is rejected as a depth" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"count\":3} ") >>= Codec.decode TopOfLibrary.codec))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s TopOfLibrary.codec
