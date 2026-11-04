module Parun.Json.String where

import qualified Control.Monad as Monad
import qualified Data.ByteString.Builder as Builder
import qualified Data.Char as Char
import qualified Data.Text as Text
import qualified Parun.Extra.Ord as Ord
import qualified Parun.Extra.Parsec as Parsec
import qualified Parun.Extra.Semigroup as Semigroup
import qualified Text.Parsec as Parsec

newtype String = MkString
  { unwrap :: Text.Text
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u Parun.Json.String.String
decode = Parsec.char '"' *> decodeBody []

-- | The rest of a string, after the chunks read so far, newest first. A run of
-- unescaped characters is read in one step.
decodeBody :: [Text.Text] -> Parsec.Parsec Text.Text u Parun.Json.String.String
decodeBody chunks = do
  chunk <- Parsec.takeWhile isUnescaped
  Parsec.choice
    [ Parsec.char '"' *> (pure $! MkString (assemble (chunk : chunks))),
      do
        c <- Parsec.char '\\' *> decodeEscapedChar
        decodeBody (Text.singleton c : chunk : chunks)
    ]

-- | Joins the chunks, newest first. A lone chunk is a slice of the whole
-- input, so it is copied rather than keeping the input alive.
assemble :: [Text.Text] -> Text.Text
assemble chunks = case chunks of
  [chunk] -> Text.copy chunk
  _ -> Text.concat (reverse chunks)

isUnescaped :: Char -> Bool
isUnescaped c = c >= ' ' && c /= '"' && c /= '\\'

decodeEscapedChar :: Parsec.Parsec Text.Text u Char
decodeEscapedChar =
  Parsec.choice
    [ '"' <$ Parsec.char '"',
      '\\' <$ Parsec.char '\\',
      '/' <$ Parsec.char '/',
      '\b' <$ Parsec.char 'b',
      '\f' <$ Parsec.char 'f',
      '\n' <$ Parsec.char 'n',
      '\r' <$ Parsec.char 'r',
      '\t' <$ Parsec.char 't',
      Parsec.char 'u' *> decodeCodePoint
    ]

decodeCodePoint :: Parsec.Parsec Text.Text u Char
decodeCodePoint = do
  hi <- decodeHex
  if Ord.between 0xd800 0xdbff hi
    then do
      lo <- Parsec.string' "\\u" *> decodeHex
      Monad.unless (Ord.between 0xdc00 0xdfff lo) $ fail "invalid low surrogate"
      pure . Char.chr $ 0x10000 + ((hi - 0xd800) * 0x400) + (lo - 0xdc00)
    else do
      Monad.when (Ord.between 0xdc00 0xdfff hi) $ fail "unpaired low surrogate"
      pure $ Char.chr hi

decodeHex :: Parsec.Parsec Text.Text u Int
decodeHex = do
  ds <- Parsec.count 4 Parsec.hexDigit
  pure $ foldl' (\n d -> (16 * n) + Char.digitToInt d) 0 ds

encode :: Parun.Json.String.String -> Builder.Builder
encode =
  Semigroup.around (Builder.charUtf8 '"') (Builder.charUtf8 '"')
    . Text.foldr (\c b -> encodeChar c <> b) mempty
    . unwrap

encodeChar :: Char -> Builder.Builder
encodeChar c = case c of
  '"' -> Builder.stringUtf8 "\\\""
  '\\' -> Builder.stringUtf8 "\\\\"
  '\b' -> Builder.stringUtf8 "\\b"
  '\f' -> Builder.stringUtf8 "\\f"
  '\n' -> Builder.stringUtf8 "\\n"
  '\r' -> Builder.stringUtf8 "\\r"
  '\t' -> Builder.stringUtf8 "\\t"
  _ ->
    if c >= ' '
      then Builder.charUtf8 c
      else
        let (q, r) = quotRem (Char.ord c) 16
         in Builder.stringUtf8 "\\u00"
              <> Builder.charUtf8 (Char.intToDigit q)
              <> Builder.charUtf8 (Char.intToDigit r)
