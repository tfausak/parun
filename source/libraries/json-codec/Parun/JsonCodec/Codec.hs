module Parun.JsonCodec.Codec where

import qualified Data.Text as Text
import qualified Parun.Json.Value as Value
import qualified Parun.JsonSchema.Define as Define
import qualified Parun.JsonSchema.Schema as Schema

-- | An encoder, a decoder and a schema as one value, so the three cannot drift
-- apart.
data Codec a = MkCodec
  { encode :: a -> Value.Value,
    decode :: Value.Value -> Either Text.Text a,
    schema :: Define.SchemaM Schema.Schema
  }
