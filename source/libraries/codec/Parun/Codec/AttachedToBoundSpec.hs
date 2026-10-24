module Parun.Codec.AttachedToBoundSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AttachedToBound as AttachedToBound
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachedToBound as AttachedToBound
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachedToBound" $ do
  -- CR 303.4b: the host is a slot and the attachments a Filter, both required.
  Spec.it s "MkAttachedToBound, both keys" $
    Common.assertCodec
      s
      AttachedToBound.codec
      ( AttachedToBound.MkAttachedToBound
          { AttachedToBound.slot = SlotName.MkSlotName (Text.pack "target"),
            AttachedToBound.filter = Filter.HasSubtype Subtype.Equipment
          }
      )
      " {\"slot\":\"target\",\"filter\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Equipment\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachedToBound.codec
