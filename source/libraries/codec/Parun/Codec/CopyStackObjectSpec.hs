module Parun.Codec.CopyStackObjectSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.CopyStackObject as CopyStackObject
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CopyException as CopyException
import qualified Parun.Types.CopyStackObject as CopyStackObject
import qualified Parun.Types.CopyTargets as CopyTargets
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Supertype as Supertype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CopyStackObject" $ do
  -- CR 707.10 alone: the copy keeps the original's targets, so the key that
  -- says otherwise is absent.
  Spec.it s "MkCopyStackObject, the original's targets: the key is omitted" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) CopyTargets.Copied CopyStackObject.defaultQuantity CopyStackObject.defaultCopier [])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"}} "
  -- CR 707.10c, Twincast's second sentence.
  Spec.it s "MkCopyStackObject, new targets offered: it is written" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) CopyTargets.ChosenByController CopyStackObject.defaultQuantity CopyStackObject.defaultCopier [])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"},\"targets\":{\"type\":\"ChosenByController\"}} "
  -- CR 707.10d, Zada, Hedron Grinder's second sentence.
  Spec.it s "MkCopyStackObject, one copy per candidate: the candidates' ref rides in the payload" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) (CopyTargets.ForEach (ObjectRef.EachMatching (Filter.ControlledBy PlayerRelation.You) NonEmpty.:| [])) CopyStackObject.defaultQuantity CopyStackObject.defaultCopier [])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"},\"targets\":{\"type\":\"ForEach\",\"value\":[{\"type\":\"EachMatching\",\"value\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}}]}} "
  -- CR 702.40a, storm's "copy it for each": a count other than one is written.
  Spec.it s "MkCopyStackObject, a count: it is written" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) CopyTargets.ChosenByController Quantity.SpellsCastBefore CopyStackObject.defaultCopier [])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"},\"targets\":{\"type\":\"ChosenByController\"},\"quantity\":{\"type\":\"SpellsCastBefore\"}} "
  -- CR 707.10, Meletis Charlatan's "the controller of target ... spell copies it".
  Spec.it s "MkCopyStackObject, another player copies it: the copier is written" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) CopyTargets.ChosenByController CopyStackObject.defaultQuantity (PlayerRef.HolderOfBound Holder.Controller Hop.Itself (SlotName.MkSlotName (Text.pack "spell"))) [])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"},\"targets\":{\"type\":\"ChosenByController\"},\"copier\":{\"type\":\"HolderOfBound\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"hop\":{\"type\":\"Itself\"},\"slot\":\"spell\"}}} "
  -- CR 707.9b, Double Major's "except it isn't legendary".
  Spec.it s "MkCopyStackObject, an exception: it is written" $
    Common.assertCodec
      s
      (CopyStackObject.codec Common.text)
      (CopyStackObject.MkCopyStackObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "spell"))) CopyTargets.Copied CopyStackObject.defaultQuantity CopyStackObject.defaultCopier [CopyException.RemoveSupertypes (Set.singleton Supertype.Legendary)])
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"spell\"},\"exceptions\":[{\"type\":\"RemoveSupertypes\",\"value\":[{\"type\":\"Legendary\"}]}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (CopyStackObject.codec Common.text)
