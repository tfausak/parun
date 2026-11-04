module Parun.Json.Null where

import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Text.Parsec as Parsec

newtype Null = MkNull
  { unwrap :: ()
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u Null
decode = MkNull () <$ Parsec.string' "null"

encode :: Null -> Builder.Builder
encode = const $ Builder.stringUtf8 "null"
