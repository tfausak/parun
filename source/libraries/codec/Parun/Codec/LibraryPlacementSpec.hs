module Parun.Codec.LibraryPlacementSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.LibraryPlacement as LibraryPlacement
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ArrangedArrival as ArrangedArrival
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LibraryPlacement" $ do
  -- A stated end writes its own tag around the position's, rather than the
  -- position's alone.
  Spec.it s "Stated Top" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.Stated LibraryPosition.Top)
      " {\"type\":\"Stated\",\"value\":{\"type\":\"Top\"}} "
  Spec.it s "Stated Bottom" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.Stated LibraryPosition.Bottom)
      " {\"type\":\"Stated\",\"value\":{\"type\":\"Bottom\"}} "
  -- Agonizing Memories' "on top of that player's library in any order".
  Spec.it s "ArrangedBy Top" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.ArrangedBy (ArrangedArrival.MkArrangedArrival LibraryPosition.Top (PlayerRef.Relative PlayerRelation.You)))
      " {\"type\":\"ArrangedBy\",\"value\":{\"position\":{\"type\":\"Top\"}}} "
  Spec.it s "ArrangedBy Top, a named chooser" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.ArrangedBy (ArrangedArrival.MkArrangedArrival LibraryPosition.Top (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")))))
      " {\"type\":\"ArrangedBy\",\"value\":{\"chooser\":{\"type\":\"InSlot\",\"value\":\"target\"},\"position\":{\"type\":\"Top\"}}} "
  Spec.it s "OwnerChooses" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      LibraryPlacement.OwnerChooses
      " {\"type\":\"OwnerChooses\"} "
  -- A random order states its end the same way Stated does: the arm says who
  -- orders the batch, and the position it carries says where the batch lands.
  Spec.it s "RandomOrder Bottom" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.RandomOrder LibraryPosition.Bottom)
      " {\"type\":\"RandomOrder\",\"value\":{\"type\":\"Bottom\"}} "
  Spec.it s "Beneath" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.Beneath (Quantity.Literal 1))
      " {\"type\":\"Beneath\",\"value\":{\"type\":\"Literal\",\"value\":1}} "
  Spec.it s "BeneathOrBottom" $
    Common.assertCodec
      s
      LibraryPlacement.codec
      (LibraryPlacement.BeneathOrBottom (Quantity.Literal 1))
      " {\"type\":\"BeneathOrBottom\",\"value\":{\"type\":\"Literal\",\"value\":1}} "
  -- A bare position is no longer a placement, which is what keeps the schema's
  -- oneOf honest. It no longer has to tell a placement from a zone --- moveTail
  -- is gone (#1305) and the placement is a named key.
  Spec.it s "rejects a bare position" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " {\"type\":\"Top\"} ") >>= Codec.decode LibraryPlacement.codec))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s LibraryPlacement.codec
