-- The one comparison both sides of the Oracle check go through: a card's
-- stamped text and what Pawl.Oracle renders for it. Everything this absorbs
-- goes unchecked, so it absorbs only what the DSL does not record: reminder
-- text, the order of lines and of a line's comma-separated pieces, letter
-- case, and how the card names itself.
module Pawl.Oracle.Normalise where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Text as Text
import qualified Pawl.Types.CardName as CardName

-- | Oracle text as a multiset of lowercase pieces: reminder text dropped (CR
-- 207.2a), self-reference unified ('selfReferences'), and each line split at
-- commas and semicolons, so "Flying, vigilance" and "Flying\nVigilance" agree.
-- A semicolon separates keywords too, as older Oracle text writes a keyword
-- line ("Haste; horsemanship", Lu Bu, Master-at-Arms).
normalise :: CardName.CardName -> Text.Text -> [Text.Text]
normalise name =
  List.sort
    . filter (not . Text.null)
    . fmap Text.strip
    . concatMap (Text.splitOn (Text.pack ", "))
    . concatMap (Text.splitOn (Text.pack "; "))
    . Text.lines
    . selfReferences name
    . Text.toLower
    . withoutReminders

-- | Lowercase text with every way a card names itself written "~": its name,
-- the part of a legendary name before the comma (CR 201.5c), and "this
-- creature" and its siblings, which Oracle text uses for the same thing on
-- newer cards (CR 201.5).
selfReferences :: CardName.CardName -> Text.Text -> Text.Text
selfReferences name text =
  let full = Text.toLower (CardName.unwrap name)
      short = Text.takeWhile (/= ',') full
      nouns = fmap (\noun -> Text.pack ("this " <> noun)) ["creature", "spell", "artifact", "enchantment", "land", "permanent", "card", "planeswalker", "aura", "equipment", "vehicle"]
   in List.foldl' (\t needle -> replaceWord needle (Text.pack "~") t) text ([full, short] <> nouns)

-- | Every occurrence of the needle standing as whole words replaced, so a card
-- named Shock leaves "shockwave" alone.
replaceWord :: Text.Text -> Text.Text -> Text.Text -> Text.Text
replaceWord needle replacement haystack =
  let wordy = maybe False Char.isAlphaNum
      final = fmap snd . Text.unsnoc
      go previous rest = case Text.breakOn needle rest of
        (prefix, match)
          | Text.null match -> prefix
          | otherwise ->
              let after = Text.drop (Text.length needle) match
                  before = Monad.mplus (final prefix) previous
                  bounded = not (wordy before) && not (wordy (fmap fst (Text.uncons after)))
                  kept = if bounded then replacement else needle
               in prefix <> kept <> go (final needle) after
   in if Text.null needle then haystack else go Nothing haystack

-- | The text with every parenthesised span removed, nested ones included.
withoutReminders :: Text.Text -> Text.Text
withoutReminders = Text.pack . go (0 :: Int) . Text.unpack
  where
    go depth string = case string of
      [] -> []
      '(' : rest -> go (depth + 1) rest
      ')' : rest | depth > 0 -> go (depth - 1) rest
      c : rest -> if depth > 0 && c /= '\n' then go depth rest else c : go depth rest
