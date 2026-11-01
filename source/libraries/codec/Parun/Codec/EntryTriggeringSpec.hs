module Parun.Codec.EntryTriggeringSpec where

import qualified Parun.Codec.EntryTriggering as EntryTriggering
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryTriggering as EntryTriggering

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryTriggering" $ do
  Spec.it s "NoTrigger" $
    Common.assertCodec
      s
      EntryTriggering.codec
      EntryTriggering.NoTrigger
      " {\"type\":\"NoTrigger\"} "
  Spec.it s "AnAdditionalTime" $
    Common.assertCodec
      s
      EntryTriggering.codec
      EntryTriggering.AnAdditionalTime
      " {\"type\":\"AnAdditionalTime\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s EntryTriggering.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s EntryTriggering.codec
