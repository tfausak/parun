-- | Validates a JSON value against a schema document, so that a codec's
-- encoder can be checked against its own schema rather than reviewed by eye.
--
-- Deliberately NOT a general JSON Schema implementation: it checks exactly the
-- shapes 'Schema.Schema' can hold, and a shape it cannot hold cannot be
-- written, so there is no keyword for it to ignore.
module Parun.JsonSchema.Validate where

import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Decimal as Decimal
import qualified Parun.Extra.Builder as Builder
import qualified Parun.Json.Array as Array
import qualified Parun.Json.Number as Number
import qualified Parun.Json.Object as Object
import qualified Parun.Json.Pair as Pair
import qualified Parun.Json.String as String
import qualified Parun.Json.Value as Value
import qualified Parun.JsonPointer.Pointer as Pointer
import qualified Parun.JsonPointer.Token as Token
import qualified Parun.JsonSchema.Define as Define
import qualified Parun.JsonSchema.Name as Name
import qualified Parun.JsonSchema.Pattern as Pattern
import qualified Parun.JsonSchema.Schema as Schema

-- | Why a value was rejected, and where in the value it happened. The pointer
-- is rendered rather than kept structured because reading it is the whole
-- point: it is what a maintainer sees when a card file stops matching.
data Failure = MkFailure
  { pointer :: Text.Text,
    message :: Text.Text
  }
  deriving (Eq, Ord, Show)

-- | What a check needs beyond a schema and a value: the document every
-- reference resolves against, where in the value we are, and which references
-- have been followed since the last step INTO the value.
data Context = MkContext
  { document :: Define.Document,
    location :: Pointer.Pointer,
    seen :: Set.Set Name.Name
  }

-- | Validates a value against a whole schema document. An empty list means the
-- value is valid.
validate :: Define.Document -> Value.Value -> [Failure]
validate d =
  check
    MkContext {document = d, location = Pointer.MkPointer [], seen = Set.empty}
    (Define.root d)

check :: Context -> Schema.Schema -> Value.Value -> [Failure]
check c schema value = case schema of
  Schema.Any -> []
  Schema.Reference name -> checkReference c name value
  Schema.Null -> case value of
    Value.Null {} -> []
    _ -> expectedType c "null" value
  Schema.Boolean -> case value of
    Value.Boolean {} -> []
    _ -> expectedType c "boolean" value
  Schema.Integer bound -> case value of
    Value.Number n -> checkIntegral c n value <> foldMap (\b -> checkMinimum c b n value) bound
    _ -> expectedType c "integer" value
  Schema.String pat -> case value of
    Value.String x -> foldMap (\p -> checkPattern c p (String.unwrap x) value) pat
    _ -> expectedType c "string" value
  Schema.Constant t ->
    if value == Value.text t
      then []
      else [failure c $ Text.pack "expected the constant " <> render (Value.text t) <> Text.pack " but got " <> render value]
  Schema.Array items count unique -> case value of
    Value.Array a ->
      concat (zipWith (\i -> check (index c i) items) [0 ..] $ Array.unwrap a)
        <> checkItemCount c "at least" (>=) (toInteger count) a value
        <> (if unique then checkUniqueItems c a value else [])
    _ -> expectedType c "array" value
  Schema.Tuple schemas -> case value of
    Value.Array a ->
      concat (zipWith3 (check . index c) [0 ..] schemas $ Array.unwrap a)
        <> checkItemCount c "exactly" (==) (List.genericLength schemas) a value
    _ -> expectedType c "array" value
  Schema.Object properties required -> case value of
    Value.Object o -> checkProperties c properties o <> checkRequired c required o
    _ -> expectedType c "object" value
  Schema.Map keys values -> case value of
    Value.Object o -> concatMap (checkEntry c keys values) $ Object.unwrap o
    _ -> expectedType c "object" value
  Schema.OneOf branches -> checkOneOf c branches value
  -- An annotation rather than a constraint: a value differing from the default
  -- is still valid.
  Schema.Defaulted _ s -> check c s value

expectedType :: Context -> String -> Value.Value -> [Failure]
expectedType c name value =
  [failure c $ Text.pack ("expected type " <> name <> " but got ") <> render value]

-- | Follows a reference. The context's 'seen' set makes a reference that leads
-- back to itself without ever stepping into the value a failure instead of a
-- hang. It is NOT a visited set over definition names: it is emptied by every
-- step into the value, so an ordinary recursive schema -- a card holding faces
-- holding abilities -- follows the same reference as often as the value nests,
-- and terminates because the value is finite.
checkReference :: Context -> Name.Name -> Value.Value -> [Failure]
checkReference c name value =
  let target = Name.fragment name
   in if Set.member name $ seen c
        then [failure c $ Text.pack "cyclic $ref " <> target]
        else case Map.lookup name . Define.definitions $ document c of
          Nothing -> [failure c $ Text.pack "unresolvable $ref " <> target]
          Just schema -> check c {seen = Set.insert name $ seen c} schema value

-- | 'Decimal.mkDecimal' normalizes by dividing every factor of ten out of the
-- mantissa and into the exponent, and every number 'Value.number' and
-- 'Number.decode' build goes through it. So a non-negative exponent is exactly
-- an integral value, with no rounding through a 'Double' anywhere.
checkIntegral :: Context -> Number.Number -> Value.Value -> [Failure]
checkIntegral c n value =
  if Decimal.exponent (Number.unwrap n) >= 0
    then []
    else expectedType c "integer" value

checkMinimum :: Context -> Integer -> Number.Number -> Value.Value -> [Failure]
checkMinimum c bound n value =
  if Number.unwrap n >= Decimal.mkDecimal bound 0
    then []
    else
      [ failure c $
          Text.pack ("expected a number at least " <> show bound <> " but got ")
            <> render value
      ]

checkPattern :: Context -> Pattern.Pattern -> Text.Text -> Value.Value -> [Failure]
checkPattern c pat x value =
  if Pattern.matches pat x
    then []
    else
      [ failure c $
          Text.pack "expected a string matching "
            <> render (Value.text (Pattern.render pat))
            <> Text.pack " but got "
            <> render value
      ]

-- | @minItems@ against an array, and both bounds of a tuple: the same shape
-- with the comparison and the wording swapped.
checkItemCount ::
  Context ->
  String ->
  (Integer -> Integer -> Bool) ->
  Integer ->
  Array.Array Value.Value ->
  Value.Value ->
  [Failure]
checkItemCount c wording op bound a value =
  if op (List.genericLength $ Array.unwrap a) bound
    then []
    else
      [ failure c $
          Text.pack ("expected " <> wording <> " " <> show bound <> " items but got ")
            <> render value
      ]

checkUniqueItems :: Context -> Array.Array Value.Value -> Value.Value -> [Failure]
checkUniqueItems c a value =
  let items = Array.unwrap a
   in if Set.size (Set.fromList items) == length items
        then []
        else [failure c $ Text.pack "expected unique items but got " <> render value]

-- | Walks the VALUE's properties rather than the schema's, so that an object
-- carrying a name twice has both of its values checked. Duplicate keys are
-- pathological either way; checking every occurrence is the direction that
-- cannot hide one.
checkProperties :: Context -> [Pair.Pair Schema.Schema] -> Object.Object Value.Value -> [Failure]
checkProperties c properties o =
  concatMap
    ( \p ->
        let name = String.unwrap $ Pair.name p
         in case member name properties of
              Nothing -> []
              Just schema -> check (into c name) schema $ Pair.value p
    )
    $ Object.unwrap o

checkRequired :: Context -> [Text.Text] -> Object.Object Value.Value -> [Failure]
checkRequired c required o =
  concatMap
    ( \name ->
        if List.any ((== name) . String.unwrap . Pair.name) $ Object.unwrap o
          then []
          else [failure c $ Text.pack "expected the required property " <> name]
    )
    required

-- | Checks one map entry: its NAME, as a string, against the key schema, and
-- its value against the value schema. Both failures are located at the
-- property rather than at the object, since that is where a reader would look
-- for the offending key.
checkEntry :: Context -> Maybe Schema.Schema -> Schema.Schema -> Pair.Pair Value.Value -> [Failure]
checkEntry c keys values p =
  let name = String.unwrap $ Pair.name p
      at = into c name
   in foldMap (\k -> check at k $ Value.text name) keys <> check at values (Pair.value p)

-- | EXACTLY one branch, not at least one. 'Parun.JsonSchema.Schema.oneOf' is how
-- every tagged union is written, and two branches matching one value means two
-- decoders claim it.
checkOneOf :: Context -> [Schema.Schema] -> Value.Value -> [Failure]
checkOneOf c branches value =
  -- Counted through take 2, so a union with many arms stops at the second
  -- match instead of checking the value against every remaining arm.
  let matched = length . take 2 $ filter (\schema -> null $ check c schema value) branches
   in case matched of
        1 -> []
        0 -> [failure c $ Text.pack "no oneOf branch matched " <> render value]
        _ -> [failure c $ Text.pack "more than one oneOf branch matched " <> render value]

-- | Steps into a named property. Emptying 'seen' is what makes the reference
-- guard a loop detector rather than a memo that would wrongly accept.
into :: Context -> Text.Text -> Context
into c step =
  MkContext
    { document = document c,
      location =
        Pointer.MkPointer
          . (<> [Token.MkToken step])
          $ Pointer.unwrap (location c),
      seen = Set.empty
    }

-- | 'into' an array element, whose reference token is its index.
index :: Context -> Integer -> Context
index c = into c . Text.pack . show

member :: Text.Text -> [Pair.Pair a] -> Maybe a
member name =
  fmap Pair.value
    . List.find ((== name) . String.unwrap . Pair.name)

failure :: Context -> Text.Text -> Failure
failure c m =
  MkFailure
    { pointer = Text.pack . Builder.toString . Pointer.encode $ location c,
      message = m
    }

-- | 'Parun.JsonCodec.Common.render' is the same function and is not reachable
-- from here: parun:json-codec depends on this library rather than the reverse.
render :: Value.Value -> Text.Text
render = Text.pack . Builder.toString . Value.encode
