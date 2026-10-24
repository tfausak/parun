module Parun.Codec.AttachBoundSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AttachBound as AttachBound
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachBound as AttachBound
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachBound" $ do
  -- CR 701.3a: the bound object moves to the targeted destination, so the two
  -- slot names are not interchangeable and both keys are required.
  Spec.it s "MkAttachBound, both keys" $
    Common.assertCodec
      s
      AttachBound.codec
      ( AttachBound.MkAttachBound
          { AttachBound.subject = SlotName.MkSlotName (Text.pack "became"),
            AttachBound.destination = SlotName.MkSlotName (Text.pack "target")
          }
      )
      " {\"subject\":\"became\",\"destination\":\"target\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachBound.codec
