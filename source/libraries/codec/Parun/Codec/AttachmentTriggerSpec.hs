module Parun.Codec.AttachmentTriggerSpec where

import qualified Parun.Codec.AttachmentTrigger as AttachmentTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachDirection as AttachDirection
import qualified Parun.Types.AttachmentEnd as AttachmentEnd
import qualified Parun.Types.AttachmentTrigger as AttachmentTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachmentTrigger" $ do
  -- Bramble Elemental's "whenever an Aura becomes attached to this creature".
  Spec.it s "MkAttachmentTrigger, every key" $
    Common.assertCodec
      s
      AttachmentTrigger.codec
      (AttachmentTrigger.MkAttachmentTrigger AttachmentEnd.Host AttachDirection.Attaches (Filter.HasSubtype Subtype.Aura))
      " {\"end\":\"Host\",\"direction\":\"Attaches\",\"other\":{\"type\":\"HasSubtype\",\"value\":\"Aura\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachmentTrigger.codec
