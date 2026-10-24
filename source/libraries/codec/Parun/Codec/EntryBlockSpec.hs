module Parun.Codec.EntryBlockSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.EntryBlock as EntryBlock
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryBlock as EntryBlock
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryBlock" $ do
  Spec.it s "Chosen" $
    Common.assertCodec s EntryBlock.codec EntryBlock.Chosen " {\"type\":\"Chosen\"} "
  Spec.it s "Specified" $
    Common.assertCodec
      s
      EntryBlock.codec
      (EntryBlock.Specified (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"Specified\",\"value\":\"target\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntryBlock.codec
