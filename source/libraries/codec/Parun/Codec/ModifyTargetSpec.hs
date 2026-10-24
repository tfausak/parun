module Parun.Codec.ModifyTargetSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ModifyTarget as ModifyTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ModifyTarget" $ do
  -- CR 611: a modification over the objects the ref names, for a duration.
  Spec.it s "MkModifyTarget, without each" $
    Common.assertCodec
      s
      (ModifyTarget.codec Common.text)
      ( ModifyTarget.MkModifyTarget
          { ModifyTarget.duration = Duration.UntilEndOfTurn,
            ModifyTarget.modification = Modification.GainKeyword Keyword.Flying,
            ModifyTarget.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            ModifyTarget.each = Nothing
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"modification\":{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}},\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 701.10b: each affected object bound under its own name while the
  -- quantities freeze.
  Spec.it s "MkModifyTarget, with each" $
    Common.assertCodec
      s
      (ModifyTarget.codec Common.text)
      ( ModifyTarget.MkModifyTarget
          { ModifyTarget.duration = Duration.UntilEndOfTurn,
            ModifyTarget.modification = Modification.GainKeyword Keyword.Flying,
            ModifyTarget.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            ModifyTarget.each = Just (SlotName.MkSlotName (Text.pack "creature"))
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"each\":\"creature\",\"modification\":{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Flying\"}},\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (ModifyTarget.codec Common.text)
