-- | The deck lists parun ships, one per file under data/decks, each a deck list
-- as Parun.DeckList reads it: preconstructed decks to play with `parun play`.
-- Under data/decks/sets, one more per finished set, naming each of its cards
-- once: not a deck to play, but the proof that every card of the set loads.
module Parun.Decks where

import qualified Data.ByteString as ByteString
import qualified Data.List as List
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Paths_parun as Paths
import qualified System.Directory as Directory

-- | The deck corpus's default root, Parun.Registry.defaultRoot's posture.
defaultRoot :: IO FilePath
defaultRoot = Paths.getDataFileName "decks"

-- | Every deck file in a root, ascending by path.
listRoot :: FilePath -> IO [FilePath]
listRoot root = do
  entries <- fmap List.sort (Directory.listDirectory root)
  pure (fmap (\entry -> root <> "/" <> entry) (filter (List.isSuffixOf ".txt") entries))

-- | One deck file's text, decoded as UTF-8 explicitly for
-- Parun.Registry.parseCard's reason.
loadFile :: FilePath -> IO (Either Text.Text Text.Text)
loadFile = fmap (either (\err -> Left (Text.pack ("not valid UTF-8: " <> show err))) Right . Encoding.decodeUtf8') . ByteString.readFile
