module Parun.Codec.LeavingPermanentSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.LeavingPermanent as LeavingPermanent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LeavingPermanent as LeavingPermanent
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LeavingPermanent" $ do
  Spec.it s "Self" $
    Common.assertCodec s LeavingPermanent.codec LeavingPermanent.Self " {\"type\":\"Self\"} "
  Spec.it s "Matching" $
    Common.assertCodec
      s
      LeavingPermanent.codec
      (LeavingPermanent.Matching (Filter.Not Filter.IsSource))
      " {\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "Attached" $
    Common.assertCodec s LeavingPermanent.codec LeavingPermanent.Attached " {\"type\":\"Attached\"} "
  Spec.it s "Haunted" $
    Common.assertCodec s LeavingPermanent.codec LeavingPermanent.Haunted " {\"type\":\"Haunted\"} "
  Spec.it s "Bound" $
    Common.assertCodec
      s
      LeavingPermanent.codec
      (LeavingPermanent.Bound (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"Bound\",\"value\":\"target\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LeavingPermanent.codec
