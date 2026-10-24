module Pawl.Codec.EntryControllerSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.EntryController as EntryController
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.EntryController as EntryController
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.EntryController" $ do
  Spec.it s "Instructed" $
    Common.assertCodec
      s
      EntryController.codec
      (EntryController.Instructed (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"Instructed\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "Owner" $
    Common.assertCodec s EntryController.codec EntryController.Owner " {\"type\":\"Owner\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntryController.codec
