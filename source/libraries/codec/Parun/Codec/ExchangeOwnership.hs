{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExchangeOwnership where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExchangeOwnership as ExchangeOwnership

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec ExchangeOwnership.ExchangeOwnership
codec = Fields.object $ do
  one <- Fields.required "one" ObjectRef.codec ExchangeOwnership.one
  other <- Fields.required "other" ObjectRef.codec ExchangeOwnership.other
  pure
    ExchangeOwnership.MkExchangeOwnership
      { ExchangeOwnership.one = one,
        ExchangeOwnership.other = other
      }
