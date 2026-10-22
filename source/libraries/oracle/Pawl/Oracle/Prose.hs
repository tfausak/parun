-- English the rest of Pawl.Oracle builds sentences from. Every renderer there
-- answers a list: empty when it cannot render its value, and otherwise the
-- wordings Oracle text uses for it, the current one first. More than one
-- arises only where Oracle text words the same value two ways and nothing the
-- DSL records picks between them; where the card or the value decides, the
-- renderer decides with it.
module Pawl.Oracle.Prose where

import qualified Data.Char as Char
import qualified Data.Text as Text

-- | A number spelled out, as Oracle text spells a count of cards or objects:
-- "two cards", "three target creatures". Past twenty Oracle text writes
-- digits.
cardinal :: Integer -> Text.Text
cardinal n = case n of
  0 -> Text.pack "zero"
  1 -> Text.pack "one"
  2 -> Text.pack "two"
  3 -> Text.pack "three"
  4 -> Text.pack "four"
  5 -> Text.pack "five"
  6 -> Text.pack "six"
  7 -> Text.pack "seven"
  8 -> Text.pack "eight"
  9 -> Text.pack "nine"
  10 -> Text.pack "ten"
  11 -> Text.pack "eleven"
  12 -> Text.pack "twelve"
  13 -> Text.pack "thirteen"
  14 -> Text.pack "fourteen"
  15 -> Text.pack "fifteen"
  16 -> Text.pack "sixteen"
  17 -> Text.pack "seventeen"
  18 -> Text.pack "eighteen"
  19 -> Text.pack "nineteen"
  20 -> Text.pack "twenty"
  _ -> Text.pack (show n)

-- | The text with its first letter in upper case.
capitalise :: Text.Text -> Text.Text
capitalise text = case Text.uncons text of
  Just (c, rest) -> Text.cons (Char.toUpper c) rest
  Nothing -> text

-- | The text with its first letter in lower case, as a sentence reads after
-- a trigger's comma.
decapitalise :: Text.Text -> Text.Text
decapitalise text = case Text.uncons text of
  Just (c, rest) -> Text.cons (Char.toLower c) rest
  Nothing -> text

-- | A sentence: capitalised, with a full stop.
sentence :: Text.Text -> Text.Text
sentence text = capitalise text <> Text.pack "."

-- | Items joined as English joins a list with the given conjunction: "a",
-- "a or b", "a, b, or c".
listing :: String -> [Text.Text] -> Text.Text
listing conjunction items = case items of
  [] -> Text.empty
  [one] -> one
  [one, two] -> one <> Text.pack (" " <> conjunction <> " ") <> two
  _ -> Text.intercalate (Text.pack ", ") (init items) <> Text.pack (", " <> conjunction <> " ") <> last items
