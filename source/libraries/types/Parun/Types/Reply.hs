module Parun.Types.Reply where

import qualified Data.Text as Text

-- | The JSON an Answer move carries, held here because Parun.Json is not a
-- dependency of the types; Parun.Codec.Reply converts at the edge.
data Reply
  = Null
  | Boolean Bool
  | Number Integer
  | Text Text.Text
  | Array [Reply]
  | Object [(Text.Text, Reply)]
  deriving (Eq, Ord, Show)
