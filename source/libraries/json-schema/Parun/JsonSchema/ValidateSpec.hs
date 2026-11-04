module Parun.JsonSchema.ValidateSpec where

import qualified Data.Text as Text
import qualified Parun.Json.Value as Value
import qualified Parun.JsonSchema.Define as Define
import qualified Parun.JsonSchema.Name as Name
import qualified Parun.JsonSchema.Pattern as Pattern
import qualified Parun.JsonSchema.Schema as Schema
import qualified Parun.JsonSchema.Validate as Validate
import qualified Parun.Spec as Spec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.JsonSchema.Validate" $ do
  let name = Name.MkName . Text.pack
      text = Value.text . Text.pack
      -- The two assertions every case below is built from. Both go through
      -- Define.run, so what is validated is a whole document rather than a
      -- bare schema, which is the only shape a codec ever produces.
      accepts label schema value =
        Spec.it s (label <> " accepts") $
          Spec.assertEq s (Validate.validate (Define.run (pure schema)) value) []
      rejects label schema value =
        Spec.it s (label <> " rejects") $
          Spec.assertNe s (Validate.validate (Define.run (pure schema)) value) []

  accepts "string" Schema.string (text "a")
  rejects "string" Schema.string (Value.integer 1)

  accepts "boolean" Schema.boolean (Value.boolean True)
  rejects "boolean" Schema.boolean (text "true")

  accepts "null" Schema.null Value.null
  rejects "null" Schema.null (text "null")

  accepts "integer" Schema.integer (Value.integer (-2))
  -- 3 / 2, which mkDecimal cannot normalize to a non-negative exponent.
  rejects "a fractional number against integer" Schema.integer (Value.number 15 (-1))
  -- 20, written with a positive exponent. Integer-ness is a property of the
  -- normalized value and not of how the number was spelled.
  accepts "a scaled whole number against integer" Schema.integer (Value.number 2 1)

  accepts "natural" Schema.natural (Value.integer 0)
  rejects "a negative number against natural" Schema.natural (Value.integer (-1))

  accepts "constant" (Schema.constant (Text.pack "Untap")) (text "Untap")
  rejects "constant" (Schema.constant (Text.pack "Untap")) (text "Upkeep")

  accepts "array" (Schema.array Schema.string) (Value.array [text "a", text "b"])
  rejects "an ill-typed element against array" (Schema.array Schema.string) (Value.array [Value.integer 1])

  accepts "uniqueArray" (Schema.uniqueArray Schema.string) (Value.array [text "a", text "b"])
  rejects "a repeat against uniqueArray" (Schema.uniqueArray Schema.string) (Value.array [text "a", text "a"])

  accepts "nonEmptyArray" (Schema.nonEmptyArray Schema.string) (Value.array [text "a"])
  rejects "an empty array against nonEmptyArray" (Schema.nonEmptyArray Schema.string) (Value.array [])

  let natural =
        Pattern.MkPattern
          [ Pattern.Alternation
              [ [Pattern.Literal '0'],
                [Pattern.Class [('1', '9')], Pattern.Star (Pattern.Class [('0', '9')])]
              ]
          ]
      keyed = Schema.mapOfKeys (Schema.matching natural) Schema.integer
  accepts "mapOfKeys" keyed (Value.object [Value.pair "0" (Value.integer 1), Value.pair "10" (Value.integer 2)])
  rejects "a non-numeric key against mapOfKeys" keyed (Value.object [Value.pair "abc" (Value.integer 1)])
  -- The alternation's first branch, so a matcher that only ever tried the last
  -- one accepts nothing here.
  rejects "a leading zero against mapOfKeys" keyed (Value.object [Value.pair "01" (Value.integer 1)])
  rejects "an ill-typed value against mapOfKeys" keyed (Value.object [Value.pair "0" (text "a")])

  accepts "matching" (Schema.matching natural) (text "10")
  rejects "a non-string against matching" (Schema.matching natural) (Value.integer 10)

  accepts "an object against anything" Schema.Any (Value.object [])
  accepts "a null against anything" Schema.Any Value.null

  accepts "tupleOf" (Schema.tupleOf [Schema.string, Schema.integer]) (Value.array [text "a", Value.integer 1])
  rejects
    "a short array against tupleOf"
    (Schema.tupleOf [Schema.string, Schema.integer])
    (Value.array [text "a"])
  rejects
    "a long array against tupleOf"
    (Schema.tupleOf [Schema.string, Schema.integer])
    (Value.array [text "a", Value.integer 1, Value.integer 2])
  rejects
    "a mistyped position against tupleOf"
    (Schema.tupleOf [Schema.string, Schema.integer])
    (Value.array [Value.integer 1, text "a"])

  let object = Schema.object [Value.pair "a" Schema.string] [Text.pack "a"]
  accepts "object" object (Value.object [Value.pair "a" (text "x")])
  rejects "a missing required property against object" object (Value.object [])
  rejects "an ill-typed property against object" object (Value.object [Value.pair "a" (Value.integer 1)])
  -- Schema.object writes no additionalProperties, so an unnamed property is
  -- allowed. Asserted rather than assumed: tightening the schema would break
  -- every card file carrying a field a codec defaults.
  accepts
    "an unnamed property against object"
    object
    (Value.object [Value.pair "a" (text "x"), Value.pair "b" (Value.integer 1)])

  accepts "mapOf" (Schema.mapOf Schema.integer) (Value.object [Value.pair "anything" (Value.integer 1)])
  rejects "an ill-typed entry against mapOf" (Schema.mapOf Schema.integer) (Value.object [Value.pair "k" (text "v")])

  accepts "a null against nullable" (Schema.nullable Schema.string) Value.null
  accepts "a string against nullable" (Schema.nullable Schema.string) (text "a")
  rejects "an integer against nullable" (Schema.nullable Schema.string) (Value.integer 1)

  -- oneOf is EXACTLY one. Two matching branches means two decoders claim the
  -- value, which is the defect the keyword exists to catch, so at-least-one
  -- semantics would accept here.
  rejects
    "a value matching two oneOf branches"
    (Schema.oneOf [Schema.integer, Schema.natural])
    (Value.integer 1)

  -- withDefault annotates; it must not constrain.
  accepts
    "a value differing from withDefault's default"
    (Schema.withDefault (text "x") Schema.string)
    (text "y")

  Spec.it s "resolves a reference into $defs" $ do
    Spec.assertEq
      s
      (Validate.validate (Define.run (Define.define (name "Word") (pure Schema.string))) (text "a"))
      []

  Spec.it s "rejects through a reference into $defs" $ do
    Spec.assertNe
      s
      (Validate.validate (Define.run (Define.define (name "Word") (pure Schema.string))) (Value.integer 1))
      []

  -- The knot Parun.Codec.Card ties: the definition refers to itself, so a
  -- validator memoizing on definition names alone would stop descending and
  -- wrongly accept. Termination comes from the value, which is finite.
  let tree =
        Define.define
          (name "Tree")
          (fmap (\r -> Schema.object [Value.pair "next" r] []) tree)
      nest v = Value.object [Value.pair "next" v]
      leaf = Value.object []
  Spec.it s "descends a recursive reference as far as the value nests" $ do
    Spec.assertEq s (Validate.validate (Define.run tree) (nest (nest leaf))) []

  Spec.it s "rejects deep inside a recursive reference" $ do
    Spec.assertNe s (Validate.validate (Define.run tree) (nest (nest (Value.integer 1)))) []

  Spec.it s "reports where in the value the failure was" $ do
    Spec.assertEq
      s
      (fmap Validate.pointer (Validate.validate (Define.run tree) (nest (nest (Value.integer 1)))))
      [Text.pack "/next/next"]

  -- A reference that leads back to itself without ever stepping into the value:
  -- the definition's body is the bare reference define hands back. Without the
  -- guard this case does not terminate, and the suite's timeout is what would
  -- say so.
  Spec.it s "rejects a reference that cycles without consuming the value" $ do
    let cyclic = Define.define (name "Loop") cyclic
    Spec.assertNe s (Validate.validate (Define.run cyclic) (text "a")) []

  -- An unresolvable reference is a schema defect, and skipping it would let a
  -- broken document validate everything.
  Spec.it s "rejects an unresolvable reference" $ do
    Spec.assertNe
      s
      (Validate.validate (Define.run (pure (Define.reference (name "Absent")))) (text "a"))
      []
