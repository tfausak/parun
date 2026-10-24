{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExchangeBlocks where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExchangeBlocks as ExchangeBlocks

codec :: Codec.Codec ExchangeBlocks.ExchangeBlocks
codec = Fields.object $ do
  first <- Fields.required "first" SlotName.codec ExchangeBlocks.first
  second <- Fields.required "second" SlotName.codec ExchangeBlocks.second
  pure
    ExchangeBlocks.MkExchangeBlocks
      { ExchangeBlocks.first = first,
        ExchangeBlocks.second = second
      }
