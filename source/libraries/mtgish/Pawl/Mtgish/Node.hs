-- One node of an mtgish card AST (#5478): an object naming its family and
-- constructor in one key, {"_Action": "DrawACard"}, with its arguments, if
-- any, under "args".
module Pawl.Mtgish.Node where

import qualified Data.Text as Text
import qualified Pawl.Json.Pair as Pair
import qualified Pawl.Json.String as String
import qualified Pawl.Json.Value as Value
import qualified Pawl.JsonCodec.Common as Common

-- | A node: its family ("Action"), its constructor ("DrawACard") and its
-- arguments.
data Node = MkNode
  { family :: String,
    tag :: String,
    args :: Maybe Value.Value
  }
  deriving (Eq, Show)

-- | Why a card is not translated: the node kind it stopped at, or what about
-- the card's shape it does not read.
type Translated = Either Text.Text

-- | The value as a node.
node :: Value.Value -> Translated Node
node value = do
  pairs <- Common.asObject value
  let keyed = filter ((== "_") . take 1 . fst) (fmap (\p -> (Text.unpack (String.unwrap (Pair.name p)), Pair.value p)) pairs)
  case keyed of
    [(name, v)] -> do
      t <- Common.asText v
      pure MkNode {family = drop 1 name, tag = Text.unpack t, args = Common.optionalField "args" pairs}
    _ -> Left (Text.pack "not a node: " <> Common.render value)

-- | The node's kind as the rejection names it, "_Action:DrawACard".
kind :: Node -> Text.Text
kind n = Text.pack ("_" <> family n <> ":" <> tag n)

-- | The rejection for a node not translated.
untranslated :: Node -> Translated a
untranslated n = Left (kind n)

-- | The node's one argument.
argument :: Node -> Translated Value.Value
argument n = case args n of
  Just v -> Right v
  Nothing -> untranslated n

-- | The node's arguments, a list.
arguments :: Node -> Translated [Value.Value]
arguments n = argument n >>= Common.asArray

-- | The node's argument, itself a node.
child :: Node -> Translated Node
child n = argument n >>= node
