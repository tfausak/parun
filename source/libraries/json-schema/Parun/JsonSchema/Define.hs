module Parun.JsonSchema.Define where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Parun.Json.Value as Value
import qualified Parun.JsonSchema.Name as Name
import qualified Parun.JsonSchema.Schema as Schema

-- | 'Nothing' marks a definition currently being built. 'Just' is a finished
-- one. The distinction is what 'define' reads to break a cycle.
type SchemaM = State.State (Map.Map Name.Name (Maybe Schema.Schema))

-- | A schema document: the root schema, and the @$defs@ every
-- 'Schema.Reference' in it resolves against.
data Document = MkDocument
  { root :: Schema.Schema,
    definitions :: Map.Map Name.Name Schema.Schema
  }
  deriving (Eq, Show)

-- | Registers a definition and returns a reference to it. The name goes into
-- the map BEFORE the body is evaluated, so a re-entrant call finds it and
-- returns the reference instead of recurring.
--
-- Memoized on the rendered 'Name.Name' alone: a second 'define' call for a
-- name already present returns the first call's reference without running
-- its own body, even if that body differs.
define :: Name.Name -> SchemaM Schema.Schema -> SchemaM Schema.Schema
define name body = do
  existing <- State.get
  if Map.member name existing
    then pure $ reference name
    else do
      State.modify' $ Map.insert name Nothing
      schema <- body
      State.modify' . Map.insert name $ Just schema
      pure $ reference name

reference :: Name.Name -> Schema.Schema
reference = Schema.Reference

run :: SchemaM Schema.Schema -> Document
run m =
  let (r, ds) = State.runState m Map.empty
   in MkDocument {root = r, definitions = Map.mapMaybe id ds}

toValue :: Document -> Value.Value
toValue d =
  Value.object $
    [Value.pair "$schema" $ Value.string "https://json-schema.org/draft/2020-12/schema"]
      <> Schema.keywords (root d)
      <> [ Value.pair "$defs" . Value.object . fmap (\(n, s) -> Value.pair (Text.unpack $ Name.unwrap n) $ Schema.toValue s) . Map.toAscList $
             definitions d
         ]
