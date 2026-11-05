-- | The deck lists parun ships, each a deck list as Parun.DeckList reads it, in
-- data/decks/sets/CODE by set: preconstructed decks to play with `parun play`,
-- and all.txt for a finished set, naming each of its cards once: not a deck to
-- play, but the proof that every card of the set loads.
module Parun.Decks where

import qualified Control.Monad as Monad
import qualified Data.ByteString as ByteString
import qualified Data.List as List
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Paths_parun as Paths
import qualified System.Directory as Directory

-- | The deck corpus's default root, Parun.Registry.defaultRoot's posture.
defaultRoot :: IO FilePath
defaultRoot = Paths.getDataFileName "decks"

-- | Every deck file beneath a root, ascending by path.
listRoot :: FilePath -> IO [FilePath]
listRoot = fmap List.sort . deckFiles

deckFiles :: FilePath -> IO [FilePath]
deckFiles dir = do
  entries <- Directory.listDirectory dir
  fmap concat . Monad.forM entries $ \entry -> do
    let path = dir <> "/" <> entry
    nested <- Directory.doesDirectoryExist path
    if nested
      then deckFiles path
      else pure [path | List.isSuffixOf ".txt" entry]

-- | One deck file's text, decoded as UTF-8 explicitly for
-- Parun.Registry.parseCard's reason.
loadFile :: FilePath -> IO (Either Text.Text Text.Text)
loadFile = fmap (either (\err -> Left (Text.pack ("not valid UTF-8: " <> show err))) Right . Encoding.decodeUtf8') . ByteString.readFile
