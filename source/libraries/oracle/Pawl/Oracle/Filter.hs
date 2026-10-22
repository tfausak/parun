-- Filters (Pawl.Types.Filter) as the noun phrases Oracle text describes
-- objects with: "nonblack creature", "creatures without flying", "artifact or
-- enchantment".
module Pawl.Oracle.Filter where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.Supertype as Supertype

-- | A description in three parts, in the order English puts them: words
-- before the noun ("tapped", "nonblack"), the noun ("creature"), and words
-- after it ("with flying", "you control"). Conjoined filters merge part by
-- part (CR 109.2).
data Phrase = MkPhrase
  { adjectives :: [Qualifier],
    nouns :: [Noun],
    qualifiers :: [Qualifier]
  }
  deriving (Eq, Show)

-- | A noun in both numbers. A disjunction of whole phrases ("land or nonblack
-- creature") has no plural Oracle text uses, so answers none.
data Noun = MkNoun
  { singular :: Text.Text,
    plural :: Maybe Text.Text
  }
  deriving (Eq, Show)

-- | Words before or after the noun, which agree with it in number: "a
-- creature you control" and "creatures you control" agree, "a creature an
-- opponent controls" and "creatures your opponents control" do not. A plural
-- may have more than one wording: "white or blue" is "white and/or blue"
-- (Ignite Disorder) or "attacking or blocking" (Fire at Will) in the plural.
data Qualifier = MkQualifier
  { one :: Text.Text,
    many :: [Text.Text]
  }
  deriving (Eq, Show)

-- | Grammatical number.
data Number
  = Singular
  | Plural
  deriving (Eq, Show)

-- | The phrase a filter describes, or none for one this cannot describe.
phrase :: Filter.Filter k -> (k -> [Text.Text]) -> [Phrase]
phrase f named = case f of
  Filter.And fs -> do
    parts <- traverse (\g -> phrase g named) fs
    pure (List.foldl' merge empty parts)
  Filter.Or fs -> disjunction =<< traverse (\g -> phrase g named) fs
  Filter.HasCardType t -> [noun (cardType Singular t) (Just (cardType Plural t))]
  Filter.HasSubtype s -> do
    name <- subtype s
    [noun name (Just (pluralOf name))]
  Filter.HasColor c -> [adjective (color c)]
  Filter.HasSupertype s -> [adjective (supertype s)]
  Filter.Not (Filter.HasColor c) -> [adjective (Text.pack "non" <> color c)]
  Filter.Not (Filter.HasCardType t) -> [adjective (Text.pack "non" <> cardType Singular t)]
  Filter.Not (Filter.HasSupertype s) -> [adjective (Text.pack "non" <> supertype s)]
  Filter.Not (Filter.HasSubtype s) -> do
    name <- subtype s
    [adjective (Text.pack "non-" <> name)]
  Filter.HasKeyword k -> do
    word <- named k
    [qualifier (Text.pack "with " <> Text.toLower word) [Text.pack "with " <> Text.toLower word]]
  Filter.Not (Filter.HasKeyword k) -> do
    word <- named k
    [qualifier (Text.pack "without " <> Text.toLower word) [Text.pack "without " <> Text.toLower word]]
  Filter.IsTapped -> [adjective (Text.pack "tapped")]
  Filter.Not Filter.IsTapped -> [adjective (Text.pack "untapped")]
  Filter.IsAttacking -> [adjective (Text.pack "attacking")]
  Filter.IsBlocking -> [adjective (Text.pack "blocking")]
  Filter.ControlledBy PlayerRelation.You -> [qualifier (Text.pack "you control") [Text.pack "you control"]]
  Filter.ControlledBy PlayerRelation.Opponent -> [qualifier (Text.pack "an opponent controls") [Text.pack "your opponents control"]]
  Filter.IsPlayer PlayerRelation.Opponent -> [noun (Text.pack "opponent") (Just (Text.pack "opponents"))]
  Filter.IsPlayer PlayerRelation.AnyPlayer -> [noun (Text.pack "player") (Just (Text.pack "players"))]
  _ -> []

-- | The phrase in the given number, with the noun the context supplies when
-- the filter names none: a filter over permanents that says only "nonblack"
-- describes a nonblack permanent.
describe :: Number -> Noun -> Phrase -> [Text.Text]
describe number fallback p = do
  let chosen = case nouns p of
        [] -> [fallback]
        ns -> ns
  headword <- case number of
    Singular -> [Text.unwords (fmap singular chosen)]
    Plural -> Maybe.maybeToList (fmap Text.unwords (traverse plural chosen))
  before <- adjectiveText number (adjectives p)
  after <- traverse (agreeing number) (qualifiers p)
  pure (Text.unwords (filter (not . Text.null) (before <> [headword] <> after)))

-- | A qualifier's wordings in the given number.
agreeing :: Number -> Qualifier -> [Text.Text]
agreeing number q = case number of
  Singular -> [one q]
  Plural -> many q

-- | Adjectives as Oracle text strings them: "non-" ones separated by commas
-- ("nonartifact, nonblack"), with the type ones first, as Terror prints them.
adjectiveText :: Number -> [Qualifier] -> [[Text.Text]]
adjectiveText number qs = do
  as <- traverse (agreeing number) qs
  let (negated, plain) = List.partition (Text.isPrefixOf (Text.pack "non")) as
      ordered = List.sortOn (\a -> elem (Text.drop 3 a) (fmap color [minBound .. maxBound])) negated
  [plain <> [Text.intercalate (Text.pack ", ") ordered | not (null ordered)]]

empty :: Phrase
empty = MkPhrase [] [] []

merge :: Phrase -> Phrase -> Phrase
merge a b = MkPhrase (adjectives a <> adjectives b) (nouns a <> nouns b) (qualifiers a <> qualifiers b)

noun :: Text.Text -> Maybe Text.Text -> Phrase
noun s p = MkPhrase [] [MkNoun s p] []

adjective :: Text.Text -> Phrase
adjective a = MkPhrase [MkQualifier a [a]] [] []

qualifier :: Text.Text -> [Text.Text] -> Phrase
qualifier o m = MkPhrase [] [] [MkQualifier o m]

-- | Disjoined phrases: adjectives alone join into one ("attacking or
-- blocking"), and whole phrases join into one noun ("artifact or
-- enchantment"), whose plural Oracle text writes with "and" ("all creatures
-- and lands", Devastation) where the nouns are bare, and not at all otherwise.
disjunction :: [Phrase] -> [Phrase]
disjunction ps
  | length ps < 2 = []
  | all (\p -> null (nouns p) && null (qualifiers p) && length (adjectives p) == 1) ps = do
      let adjs = concatMap adjectives ps
          plurals = traverse many adjs
      [MkPhrase [MkQualifier (Prose.listing "or" (fmap one adjs)) (concatMap (\w -> [Prose.listing "or" w, Prose.listing "and/or" w]) plurals)] [] []]
  | not (any (null . nouns) ps) = do
      singulars <- traverse (describe Singular (MkNoun Text.empty Nothing)) ps
      let bare p = null (adjectives p) && null (qualifiers p)
          plurals = traverse (Maybe.listToMaybe . describe Plural (MkNoun Text.empty Nothing)) ps
      [noun (Prose.listing "or" singulars) (Monad.mfilter (const (all bare ps)) (fmap (Prose.listing "and") plurals))]
  | otherwise = []

-- | A card type's name, in lower case as rules text uses it.
cardType :: Number -> CardType.CardType -> Text.Text
cardType number t =
  let name = Text.toLower (Text.pack (show t))
   in case number of
        Singular -> name
        Plural -> pluralOf name

-- | A colour's name, as an adjective.
color :: Color.Color -> Text.Text
color c = Text.toLower (Text.pack (show c))

-- | A supertype's name, as an adjective.
supertype :: Supertype.Supertype -> Text.Text
supertype s = Text.toLower (Text.pack (show s))

-- | A subtype's name, for the ones whose name is a single word; a name of more
-- than one word is not spelled out here yet.
subtype :: Subtype.Subtype -> [Text.Text]
subtype s =
  let name = Text.pack (show s)
   in [name | Text.length (Text.filter Char.isUpper name) == 1]

-- | An English plural.
pluralOf :: Text.Text -> Text.Text
pluralOf word =
  let irregular = [("Plains", "Plains"), ("Elf", "Elves"), ("Dwarf", "Dwarves"), ("Wolf", "Wolves"), ("Werewolf", "Werewolves"), ("Mouse", "Mice"), ("Fungus", "Fungi"), ("Ox", "Oxen"), ("Thief", "Thieves")]
      ends suffix = Text.isSuffixOf (Text.pack suffix) word
   in case lookup (Text.unpack word) irregular of
        Just p -> Text.pack p
        Nothing
          | ends "y" && not (any ends ["ay", "ey", "oy", "uy"]) -> Text.dropEnd 1 word <> Text.pack "ies"
          | any ends ["s", "x", "ch", "sh"] -> word <> Text.pack "es"
          | otherwise -> word <> Text.pack "s"
