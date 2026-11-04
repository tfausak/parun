-- | A JSON Schema @pattern@, held as a tree rather than as text, so a schema
-- can carry only a pattern this module can match.
--
-- Deliberately NOT a regular expression engine. 'Node' has exactly the
-- constructs the patterns this project writes use --- alternation, grouping,
-- character classes with ranges, literals, and postfix @*@ --- and 'render'
-- anchors every pattern at both ends, so JSON Schema's partial match and this
-- module's whole-string match agree.
module Parun.JsonSchema.Pattern where

import qualified Data.List as List
import qualified Data.Text as Text

-- | A whole pattern: a sequence, anchored at both ends.
newtype Pattern = MkPattern
  { unwrap :: [Node]
  }
  deriving (Eq, Ord, Show)

-- | One element of a pattern. A group is an 'Alternation', since a group with
-- one branch and a group are the same thing.
data Node
  = Literal Char
  | -- | Inclusive ranges; a bare character is a range with itself.
    Class [(Char, Char)]
  | Alternation [[Node]]
  | Star Node
  deriving (Eq, Ord, Show)

-- | Whether the whole string matches the pattern.
matches :: Pattern -> Text.Text -> Bool
matches pat = List.any null . matchNodes (unwrap pat) . Text.unpack

-- Rendering ------------------------------------------------------------------

-- | The pattern in ECMA-262 syntax, as a schema publishes it. Every group is
-- parenthesized, so a top-level alternation cannot bind to an anchor.
render :: Pattern -> Text.Text
render pat = Text.pack $ "^" <> concatMap renderNode (unwrap pat) <> "$"

renderNode :: Node -> String
renderNode node = case node of
  Literal c -> escape metacharacters c
  Class ranges -> "[" <> concatMap renderRange ranges <> "]"
  Alternation branches -> "(" <> List.intercalate "|" (fmap (concatMap renderNode) branches) <> ")"
  Star inner -> case inner of
    Star {} -> "(" <> renderNode inner <> ")*"
    _ -> renderNode inner <> "*"

renderRange :: (Char, Char) -> String
renderRange (a, b) =
  if a == b
    then escape classMetacharacters a
    else escape classMetacharacters a <> "-" <> escape classMetacharacters b

escape :: String -> Char -> String
escape special c = if List.elem c special then ['\\', c] else [c]

metacharacters :: String
metacharacters = "\\^$.|?*+()[]{}"

classMetacharacters :: String
classMetacharacters = "[]-\\^"

-- Matching -------------------------------------------------------------------
--
-- Every matcher answers with EVERY remaining input the node could leave, so
-- backtracking falls out of the list rather than needing its own machinery.

matchNodes :: [Node] -> String -> [String]
matchNodes nodes input = case nodes of
  [] -> [input]
  node : rest -> concatMap (matchNodes rest) $ matchNode node input

matchNode :: Node -> String -> [String]
matchNode node input = case node of
  Literal c -> case input of
    x : xs | x == c -> [xs]
    _ -> []
  Class ranges -> case input of
    x : xs | List.any (\(a, b) -> a <= x && x <= b) ranges -> [xs]
    _ -> []
  Alternation branches -> concatMap (`matchNodes` input) branches
  Star inner -> star inner input

-- | Only a repetition that CONSUMED input is repeated, so a group that matches
-- the empty string cannot loop forever.
star :: Node -> String -> [String]
star node input =
  let n = length input
   in input : concatMap (star node) (filter ((< n) . length) $ matchNode node input)
