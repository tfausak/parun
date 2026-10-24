{-# LANGUAGE FlexibleContexts #-}

module Parun.Json.Value where

import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Parun.Decimal as Decimal
import qualified Parun.Json.Array as Array
import qualified Parun.Json.Boolean as Boolean
import qualified Parun.Json.Null as Null
import qualified Parun.Json.Number as Number
import qualified Parun.Json.Object as Object
import qualified Parun.Json.Pair as Pair
import qualified Parun.Json.String as String
import qualified Text.Parsec as Parsec

data Value
  = Null Null.Null
  | Boolean Boolean.Boolean
  | Number Number.Number
  | String String.String
  | Array (Array.Array Value)
  | Object (Object.Object Value)
  deriving (Eq, Ord, Show)

null :: Value
null = Null $ Null.MkNull ()

boolean :: Bool -> Value
boolean = Boolean . Boolean.MkBoolean

number :: Integer -> Integer -> Value
number m = Number . Number.MkNumber . Decimal.mkDecimal m

integer :: Integer -> Value
integer = flip number 0

text :: Text.Text -> Value
text = String . String.MkString

string :: Prelude.String -> Value
string = text . Text.pack

array :: [Value] -> Value
array = Array . Array.MkArray

pair :: String -> a -> Pair.Pair a
pair = Pair.MkPair . String.MkString . Text.pack

object :: [Pair.Pair Value] -> Value
object = Object . Object.MkObject

decode :: (Parsec.Stream s m Char) => Parsec.ParsecT s u m Value
decode =
  Parsec.between (Parsec.many Array.decodeBlank) (Parsec.many Array.decodeBlank) $
    Parsec.choice
      [ Null <$> Null.decode,
        Boolean <$> Boolean.decode,
        Number <$> Number.decode,
        String <$> String.decode,
        Array <$> Array.decode decode,
        Object <$> Object.decode decode
      ]

encode :: Value -> Builder.Builder
encode v = case v of
  Null n -> Null.encode n
  Boolean b -> Boolean.encode b
  Number n -> Number.encode n
  String s -> String.encode s
  Array a -> Array.encode encode a
  Object o -> Object.encode encode o
