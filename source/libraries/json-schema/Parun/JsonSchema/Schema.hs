-- | A JSON schema, restricted to the shapes this project's codecs write. Each
-- constructor is what one combinator below builds, and 'keywords' is the one
-- place that spells it as JSON Schema keywords.
module Parun.JsonSchema.Schema where

import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Parun.Json.Pair as Pair
import qualified Parun.Json.Value as Value
import qualified Parun.JsonSchema.Name as Name
import qualified Parun.JsonSchema.Pattern as Pattern

data Schema
  = -- | Any value: the empty schema.
    Any
  | -- | @$ref@ to the definition filed under the name.
    Reference Name.Name
  | Null
  | Boolean
  | -- | An integer, with an optional @minimum@.
    Integer (Maybe Integer)
  | -- | A string, with an optional @pattern@.
    String (Maybe Pattern.Pattern)
  | -- | @const@: exactly this string.
    Constant Text.Text
  | -- | @items@, @minItems@ (omitted at zero) and @uniqueItems@ (omitted unset).
    Array Schema Natural.Natural Bool
  | -- | @prefixItems@, with @minItems@ and @maxItems@ both its length.
    Tuple [Schema]
  | -- | @properties@ and @required@; an unnamed property is allowed.
    Object [Pair.Pair Schema] [Text.Text]
  | -- | A map: the optional @propertyNames@, and @additionalProperties@.
    Map (Maybe Schema) Schema
  | -- | Exactly one of the branches.
    OneOf [Schema]
  | -- | @default@: an annotation beside the schema, never a constraint.
    Defaulted Value.Value Schema
  deriving (Eq, Ord, Show)

toValue :: Schema -> Value.Value
toValue = Value.object . keywords

-- | A schema's keywords, so 'Parun.JsonSchema.Define.toValue' can write the
-- root's beside @$schema@ and @$defs@.
keywords :: Schema -> [Pair.Pair Value.Value]
keywords schema = case schema of
  Any -> []
  Reference name -> [Value.pair "$ref" . Value.text $ Name.fragment name]
  Null -> [typeIs "null"]
  Boolean -> [typeIs "boolean"]
  Integer bound -> typeIs "integer" : foldMap (pure . Value.pair "minimum" . Value.integer) bound
  String pat -> typeIs "string" : foldMap (pure . Value.pair "pattern" . Value.text . Pattern.render) pat
  Constant t -> [Value.pair "const" $ Value.text t]
  Array s count unique ->
    [typeIs "array", Value.pair "items" $ toValue s]
      <> [Value.pair "minItems" . Value.integer $ toInteger count | count > 0]
      <> [Value.pair "uniqueItems" $ Value.boolean True | unique]
  Tuple ss ->
    let count = Value.integer . toInteger $ length ss
     in [ typeIs "array",
          Value.pair "prefixItems" . Value.array $ fmap toValue ss,
          Value.pair "minItems" count,
          Value.pair "maxItems" count
        ]
  Object properties required ->
    [ typeIs "object",
      Value.pair "properties" . Value.object $ fmap (\p -> Pair.MkPair (Pair.name p) . toValue $ Pair.value p) properties,
      Value.pair "required" . Value.array $ fmap Value.text required
    ]
  Map k v ->
    typeIs "object"
      : foldMap (pure . Value.pair "propertyNames" . toValue) k
        <> [Value.pair "additionalProperties" $ toValue v]
  OneOf ss -> [Value.pair "oneOf" . Value.array $ fmap toValue ss]
  Defaulted d s -> keywords s <> [Value.pair "default" d]

typeIs :: String -> Pair.Pair Value.Value
typeIs = Value.pair "type" . Value.string

string :: Schema
string = String Nothing

integer :: Schema
integer = Integer Nothing

natural :: Schema
natural = Integer $ Just 0

null :: Schema
null = Null

boolean :: Schema
boolean = Boolean

array :: Schema -> Schema
array s = Array s 0 False

uniqueArray :: Schema -> Schema
uniqueArray s = Array s 0 True

-- | An array whose decoder rejects an empty one, e.g. 'Parun.JsonCodec.Common.nonEmpty'.
nonEmptyArray :: Schema -> Schema
nonEmptyArray s = Array s 1 False

tupleOf :: [Schema] -> Schema
tupleOf = Tuple

constant :: Text.Text -> Schema
constant = Constant

object :: [Pair.Pair Schema] -> [Text.Text] -> Schema
object = Object

-- | An object used as a MAP: every value shares one shape and the keys are
-- unconstrained, e.g. @Parun.JsonCodec.Common.textMap@ -- named rather than
-- linked, since parun:json-schema does not depend on parun:json-codec. Distinct from
-- 'object', which names its properties and requires some of them; this names
-- none.
--
-- No @propertyNames@. The decoder accepts any string as a key, so constraining
-- keys here would make the schema claim more than the decoder guarantees --- the
-- wrong direction, since the decoder is tightened to honour the schema rather
-- than the schema loosened to describe the decoder. 'mapOfKeys' is the sibling
-- for a decoder that does constrain its keys.
mapOf :: Schema -> Schema
mapOf = Map Nothing

-- | An object used as a map whose KEYS are constrained too, e.g. a map keyed
-- by the decimal rendering of a number. Separate from 'mapOf' rather than an
-- argument to it: 'mapOf' says the keys are unconstrained, which is the honest
-- schema for a decoder that accepts any string, and this one is honest only
-- for a decoder that rejects a key the key schema rejects.
mapOfKeys :: Schema -> Schema -> Schema
mapOfKeys = Map . Just

-- | A string matching a pattern.
matching :: Pattern.Pattern -> Schema
matching = String . Just

oneOf :: [Schema] -> Schema
oneOf = OneOf

nullable :: Schema -> Schema
nullable s = oneOf [s, Parun.JsonSchema.Schema.null]

withDefault :: Value.Value -> Schema -> Schema
withDefault = Defaulted
