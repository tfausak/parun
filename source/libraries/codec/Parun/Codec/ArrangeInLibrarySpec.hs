module Parun.Codec.ArrangeInLibrarySpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ArrangeInLibrary" $ do
  -- Ponder's "then put them back in any order".
  Spec.it s "MkArrangeInLibrary" $
    Common.assertCodec
      s
      ArrangeInLibrary.codec
      (ArrangeInLibrary.MkArrangeInLibrary (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "looked"))) (PlayerRef.Relative PlayerRelation.You))
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"looked\"}} "
  -- Tahngarth's Glare's "that player ... puts them back in any order".
  Spec.it s "MkArrangeInLibrary, a named chooser" $
    Common.assertCodec
      s
      ArrangeInLibrary.codec
      (ArrangeInLibrary.MkArrangeInLibrary (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "looked"))) (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"chooser\":{\"type\":\"InSlot\",\"value\":\"target\"},\"ref\":{\"type\":\"InSlot\",\"value\":\"looked\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ArrangeInLibrary.codec
