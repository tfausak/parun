-- | The deck lists pawl ships, one per file under data/decks, each a deck list
-- as Pawl.DeckList reads it: preconstructed decks to play with `pawl play`.
module Pawl.Decks where

import qualified Data.ByteString as ByteString
import qualified Data.List as List
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Paths_pawl as Paths
import qualified System.Directory as Directory

-- | The deck corpus's default root, Pawl.Registry.defaultRoot's posture.
defaultRoot :: IO FilePath
defaultRoot = Paths.getDataFileName "decks"

-- | Every deck file in a root, ascending by path, with its text, decoded as
-- UTF-8 explicitly for Pawl.Registry.parseCard's reason.
loadRoot :: FilePath -> IO [(FilePath, Either Text.Text Text.Text)]
loadRoot root = do
  entries <- fmap List.sort (Directory.listDirectory root)
  let paths = fmap (\entry -> root <> "/" <> entry) (filter (List.isSuffixOf ".txt") entries)
  mapM (\path -> fmap (\bytes -> (path, either (\err -> Left (Text.pack ("not valid UTF-8: " <> show err))) Right (Encoding.decodeUtf8' bytes))) (ByteString.readFile path)) paths
