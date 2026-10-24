module Parun.Codec.ExchangeBlocksSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExchangeBlocks as ExchangeBlocks
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExchangeBlocks as ExchangeBlocks
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExchangeBlocks" $ do
  -- Distinct names, so a codec swapping the two sides disagrees.
  Spec.it s "MkExchangeBlocks" $
    Common.assertCodec
      s
      ExchangeBlocks.codec
      (ExchangeBlocks.MkExchangeBlocks (SlotName.MkSlotName (Text.pack "first")) (SlotName.MkSlotName (Text.pack "second")))
      " {\"first\":\"first\",\"second\":\"second\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExchangeBlocks.codec
