module Parun.Json.Pair where

import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Parun.Json.Array as Array
import qualified Parun.Json.String as String
import qualified Text.Parsec as Parsec

data Pair a = MkPair
  { name :: String.String,
    value :: a
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u a -> Parsec.Parsec Text.Text u (Pair a)
decode p =
  MkPair
    <$> (String.decode <* Array.decodeBlanks)
    <*> (Parsec.char ':' *> Array.decodeBlanks *> p)

encode :: (a -> Builder.Builder) -> Pair a -> Builder.Builder
encode b p = String.encode (name p) <> Builder.charUtf8 ':' <> b (value p)
