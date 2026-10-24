module Parun.Exceptions.InvalidCorpus where

import qualified Control.Exception as Exception
import qualified Data.List as List

-- | A file registry's lookup or enumeration reached files it could not use:
-- files that would not parse, or one name claimed by more than one card. A
-- lookup returns it as a value, and the host decides what it means.
--
-- Every problem among the files reached rather than the first, so a broken
-- pool is one report rather than N runs (#167).
--
-- Rendered `problems` rather than a structured list, because this sublibrary
-- sits above `types` and cannot speak CardName, and because a caller's only
-- move is to show them.
data InvalidCorpus = MkInvalidCorpus
  { root :: FilePath,
    problems :: [String]
  }
  deriving (Eq, Ord, Show)

-- | The problems on one line, each already naming its file.
instance Exception.Exception InvalidCorpus where
  displayException corpus = "card files under " <> root corpus <> " cannot be used: " <> List.intercalate "; " (problems corpus)
