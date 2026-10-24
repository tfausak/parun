module Parun.Codec.EventGroupSpec where

import qualified Parun.Codec.EventGroup as EventGroup
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EventGroup as EventGroup

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EventGroup" $ do
  Spec.it s "the first group" $
    Common.assertCodec s EventGroup.codec EventGroup.first " 0 "
  -- CR 608.2f's groups are minted in order, and the ordering is what makes the
  -- log's "non-decreasing along the log" invariant checkable.
  Spec.it s "the group after it" $
    Common.assertCodec s EventGroup.codec (EventGroup.next EventGroup.first) " 1 "
  Spec.it s "has a schema" $
    Common.assertHasSchema s EventGroup.codec
