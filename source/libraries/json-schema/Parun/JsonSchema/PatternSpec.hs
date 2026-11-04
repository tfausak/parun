module Parun.JsonSchema.PatternSpec where

import qualified Data.Text as Text
import qualified Parun.JsonSchema.Pattern as Pattern
import qualified Parun.Spec as Spec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.JsonSchema.Pattern" $ do
  let matches label nodes value expected =
        Spec.it s label $
          Spec.assertEq s (Pattern.matches (Pattern.MkPattern nodes) (Text.pack value)) expected
      renders label nodes expected =
        Spec.it s (label <> " renders") $
          Spec.assertEq s (Pattern.render (Pattern.MkPattern nodes)) (Text.pack expected)
      ab = [Pattern.Literal 'a', Pattern.Literal 'b']
      aToC = Pattern.Class [('a', 'c')]
      abStar = [Pattern.Literal 'a', Pattern.Star (Pattern.Literal 'b')]
      aOrB = [Pattern.Alternation [[Pattern.Literal 'a'], [Pattern.Literal 'b']]]

  matches "a literal matches itself" ab "ab" True
  -- Whole-string, so a pattern matching a prefix does not match the string.
  matches "a literal does not match a longer string" ab "abc" False
  matches "the empty pattern matches only the empty string" [] "" True

  matches "a class matches a member" [aToC] "b" True
  matches "a class does not match a non-member" [aToC] "d" False
  matches "a class matches a bare member beside a range" [Pattern.Class [('a', 'c'), ('x', 'x')]] "x" True

  matches "a star matches nothing" abStar "a" True
  matches "a star matches repeats" abStar "abbb" True
  matches "a star does not match another character" abStar "ac" False

  matches "an alternation matches its first branch" aOrB "a" True
  matches "an alternation matches its last branch" aOrB "b" True
  matches "an alternation matches neither" aOrB "c" False

  -- The pattern Parun.JsonCodec.Common.naturalMap publishes: a group, an
  -- alternation inside it, a class and a starred class.
  let natural =
        [ Pattern.Alternation
            [ [Pattern.Literal '0'],
              [Pattern.Class [('1', '9')], Pattern.Star (Pattern.Class [('0', '9')])]
            ]
        ]
  matches "a natural key of one digit" natural "0" True
  matches "a natural key of several digits" natural "100" True
  matches "a natural key with a leading zero" natural "01" False
  matches "a natural key with a sign" natural "-1" False
  matches "a natural key with an exponent" natural "1e0" False
  matches "a natural key that is not a number at all" natural "abc" False

  -- A group that can match the empty string, so the repetition has to notice it
  -- made no progress rather than looping. A failure here is the suite's timeout
  -- rather than an assertion.
  matches
    "a star over a group that matches nothing terminates"
    [Pattern.Star (Pattern.Alternation [[Pattern.Star (Pattern.Literal 'a')]]), Pattern.Literal 'b']
    "b"
    True

  renders "the natural key" natural "^(0|[1-9][0-9]*)$"
  -- Parenthesized, so the branches do not bind to the anchors: @^a|b$@ is
  -- "starts with a, or ends with b".
  renders "a top-level alternation" aOrB "^(a|b)$"
  renders "a metacharacter literal" [Pattern.Literal '.', Pattern.Literal '+'] "^\\.\\+$"
  renders "a class metacharacter" [Pattern.Class [('-', '-'), ('^', '^'), ('a', ']')]] "^[\\-\\^a-\\]]$"
  -- @a**@ is not a pattern at all.
  renders "a star of a star" [Pattern.Star (Pattern.Star (Pattern.Literal 'a'))] "^(a*)*$"
