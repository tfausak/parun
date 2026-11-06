-- Covers Parun.Engine.Subtype's families, Parun.Types.CardType and
-- Parun.Types.Supertype against the closed lists docs/rules.txt names, so a
-- rules update that adds a type turns the suite red until the enum has it.
module Parun.SubtypeSpec where

import qualified Data.ByteString as ByteString
import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Parun.Engine.Subtype as Subtype.Engine
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Supertype as Supertype

spec :: (Monad n) => Spec.Spec IO n -> n ()
spec s = Spec.describe s "Parun.Engine.Subtype" $ do
  Spec.it s "CR 205.2a the card types are exactly CardType" $
    agrees s "205.2a" ["The card types are "] (named (enumerate :: [CardType.CardType]))
  Spec.it s "CR 205.4a the supertypes are exactly Supertype" $
    agrees s "205.4a" ["The supertypes are "] (named (enumerate :: [Supertype.Supertype]))
  mapM_
    ( \(rule, markers, cardTypes) ->
        Spec.it s ("CR " <> rule <> " the subtypes it lists are exactly those correlatedCardTypes files under " <> show cardTypes) $
          agrees s rule markers (named (filter (inFamily cardTypes) enumerate))
    )
    [ ("205.3g", ["The artifact types are "], [CardType.Artifact]),
      ("205.3h", ["The enchantment types are "], [CardType.Enchantment]),
      ("205.3i", ["The land types are "], [CardType.Land]),
      ("205.3j", ["The planeswalker types are "], [CardType.Planeswalker]),
      ("205.3k", ["The spell types are "], [CardType.Instant, CardType.Sorcery]),
      ("205.3m", ["two words long: ", "one word long: "], [CardType.Creature, CardType.Kindred]),
      ("205.3n", ["The planar types are "], [CardType.Plane]),
      ("205.3p", ["That dungeon type is "], [CardType.Dungeon]),
      ("205.3q", ["That battle type is "], [CardType.Battle])
    ]

-- A subtype whose correlated card types include all of these, bar notInRules.
inFamily :: [CardType.CardType] -> Subtype.Subtype -> Bool
inFamily cardTypes subtype =
  Set.fromList cardTypes `Set.isSubsetOf` Subtype.Engine.correlatedCardTypes subtype
    && Set.notMember subtype notInRules

-- Printed on a card but in no CR 205.3 list: Clamfolk is an un-card's (Clam-I-Am).
notInRules :: Set.Set Subtype.Subtype
notInRules = Set.fromList [Subtype.Clamfolk]

enumerate :: (Bounded a, Enum a) => [a]
enumerate = [minBound .. maxBound]

named :: (Show a) => [a] -> Set.Set Text.Text
named = Set.fromList . fmap (normalise . Text.pack . show)

-- Compared without case or punctuation, so "Urza’s" is Urzas and "artifact" is
-- Artifact.
normalise :: Text.Text -> Text.Text
normalise = Text.toLower . Text.filter Char.isAlphaNum

agrees :: Spec.Spec IO n -> String -> [String] -> Set.Set Text.Text -> IO ()
agrees s rule markers enum = do
  rules <- rulesText
  let listed = listedBy rules rule markers
  Spec.assertBool s (not (Set.null listed)) ("no list found in CR " <> rule)
  Spec.assertEqWith s "listed by the CR, but no constructor" [] (Set.toList (Set.difference listed enum))
  Spec.assertEqWith s "a constructor, but not listed by the CR" [] (Set.toList (Set.difference enum listed))

-- The items after each marker on the rule's line, up to the sentence's full
-- stop, with "(see rule N)" asides dropped.
listedBy :: Text.Text -> String -> [String] -> Set.Set Text.Text
listedBy rules rule markers = Set.fromList (concatMap items markers)
  where
    line = Maybe.fromMaybe Text.empty (List.find (Text.isPrefixOf (Text.pack (rule <> " "))) (Text.lines rules))
    items marker = case Text.breakOn (Text.pack marker) line of
      (_, rest)
        | Text.null rest -> []
        | otherwise ->
            let body = Text.takeWhile (/= '.') (dropAsides (Text.drop (length marker) rest))
             in filter (not . Text.null) (fmap item (concatMap (Text.splitOn (Text.pack " and ")) (Text.splitOn (Text.pack ",") body)))
    item = normalise . stripAnd . Text.strip
    stripAnd x = Maybe.fromMaybe x (Text.stripPrefix (Text.pack "and ") x)
    dropAsides t = case Text.breakOn (Text.pack "(") t of
      (before, rest)
        | Text.null rest -> before
        | otherwise -> before <> dropAsides (Text.drop 1 (Text.dropWhile (/= ')') rest))

rulesText :: IO Text.Text
rulesText = do
  root <- Registry.defaultRoot
  bytes <- ByteString.readFile (root <> "/../../docs/rules.txt")
  either (fail . show) pure (Encoding.decodeUtf8' bytes)
