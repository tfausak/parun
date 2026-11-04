module Parun.Json.Number where

import qualified Data.ByteString.Builder as Builder
import qualified Data.Char as Char
import qualified Data.Text as Text
import qualified Parun.Decimal as Decimal
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Ord as Ord
import qualified Parun.Extra.Parsec as Parsec
import qualified Text.Parsec as Parsec

newtype Number = MkNumber
  { unwrap :: Decimal.Decimal
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u Number
decode = do
  sign <- Parsec.option id $ negate <$ Parsec.char '-'
  int <- integerPart
  frac <- Parsec.option Text.empty fractionPart
  ex <- Parsec.option 0 exponentPart
  let mantissa = sign . fromDigits $ int <> frac
      scale = ex - toInteger (Text.length frac)
  pure . MkNumber $ Decimal.mkDecimal mantissa scale

integerPart :: Parsec.Parsec Text.Text u Text.Text
integerPart =
  Parsec.choice
    [ Text.singleton '0' <$ Parsec.char '0' <* Parsec.notFollowedBy Parsec.digit,
      Text.cons <$> Parsec.satisfy (Ord.between '1' '9') <*> Parsec.takeWhile Char.isDigit
    ]

fractionPart :: Parsec.Parsec Text.Text u Text.Text
fractionPart = Parsec.char '.' *> digits

exponentPart :: Parsec.Parsec Text.Text u Integer
exponentPart =
  Parsec.oneOf "eE" *> do
    sign <-
      Parsec.option id $
        Parsec.choice
          [ negate <$ Parsec.char '-',
            id <$ Parsec.char '+'
          ]
    ds <- digits
    pure . sign $ fromDigits ds

-- | One or more digits.
digits :: Parsec.Parsec Text.Text u Text.Text
digits = Text.cons <$> Parsec.digit <*> Parsec.takeWhile Char.isDigit

fromDigits :: Text.Text -> Integer
fromDigits = Text.foldl' (\n c -> (10 * n) + toInteger (Char.digitToInt c)) 0

-- | An integer is written out in full, as a person writes one (50, not 5e1),
-- up to six trailing zeros, which reaches the largest number a card prints
-- (Gleemax's {1000000}); past that, and for a fraction, the exponent is
-- written.
encode :: Number -> Builder.Builder
encode n =
  let d = unwrap n
      e = Decimal.exponent d
   in Builder.integerDec (Decimal.mantissa d)
        <> if e == 0
          then mempty
          else
            if e > 0 && e <= 6
              then Builder.string7 (replicate (Integer.toIntSaturating e) '0')
              else Builder.charUtf8 'e' <> Builder.integerDec e
