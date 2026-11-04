module Parun.Json.Boolean where

import qualified Data.Bool as Bool
import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Text.Parsec as Parsec

newtype Boolean = MkBoolean
  { unwrap :: Bool
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u Boolean
decode =
  MkBoolean
    <$> Parsec.choice
      [ False <$ Parsec.string' "false",
        True <$ Parsec.string' "true"
      ]

encode :: Boolean -> Builder.Builder
encode = Builder.stringUtf8 . Bool.bool "false" "true" . unwrap
