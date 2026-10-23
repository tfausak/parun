-- Filters (Pawl.Types.Filter) as the noun phrases Oracle text describes
-- objects with: "nonblack creature", "creatures without flying", "artifact or
-- enchantment".
module Pawl.Oracle.Filter where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
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
-- part.
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
-- opponent controls" and "creatures your opponents control" do not.
data Qualifier = MkQualifier
  { one :: Text.Text,
    many :: Text.Text
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
  Filter.Or fs
    | Just ts <- traverse cardTypeOf fs, Just p <- permanentCard (Set.fromList ts) -> [p]
    | otherwise -> disjunction =<< traverse (\g -> phrase g named) fs
  Filter.HasCardType t -> [noun (cardType Singular t) (Just (cardType Plural t))]
  Filter.HasSubtype s -> do
    name <- subtype s
    [noun name (Just (pluralOf name))]
  Filter.HasColor c -> [adjective (color c)]
  Filter.HasSupertype s -> [adjective (supertype s)]
  Filter.Not (Filter.HasColor c) -> [adjective (Text.pack "non" <> color c)]
  Filter.Not (Filter.HasCardType t) -> [adjective (Text.pack "non" <> cardType Singular t)]
  -- Free: "nonlegendary" (Cytoshape) or "that aren't legendary" (Urza's
  -- Ruinous Blast).
  Filter.Not (Filter.HasSupertype s) -> [adjective (Text.pack "non" <> supertype s), qualifier (Text.pack "that isn't " <> supertype s) (Text.pack "that aren't " <> supertype s)]
  Filter.Not (Filter.HasSubtype s) -> do
    name <- subtype s
    [adjective (Text.pack "non-" <> name)]
  Filter.HasKeyword k -> do
    word <- named k
    [qualifier (Text.pack "with " <> Text.toLower word) (Text.pack "with " <> Text.toLower word)]
  Filter.Not (Filter.HasKeyword k) -> do
    word <- named k
    [qualifier (Text.pack "without " <> Text.toLower word) (Text.pack "without " <> Text.toLower word)]
  Filter.Not Filter.IsSource -> [adjective (Text.pack "other")]
  -- Another of the mode's objects than the one a slot names (Fall of the
  -- Hammer).
  Filter.Not (Filter.IsBound _) -> [adjective (Text.pack "other")]
  Filter.Not Filter.IsToken -> [adjective (Text.pack "nontoken")]
  Filter.HasAttached (Filter.HasSubtype Subtype.Aura) -> [adjective (Text.pack "enchanted")]
  Filter.HasAttached (Filter.HasSubtype Subtype.Equipment) -> [adjective (Text.pack "equipped")]
  Filter.IsTapped -> [adjective (Text.pack "tapped")]
  Filter.Not Filter.IsTapped -> [adjective (Text.pack "untapped")]
  Filter.IsAttacking -> [adjective (Text.pack "attacking")]
  Filter.IsBlocking -> [adjective (Text.pack "blocking")]
  Filter.ControlledBy PlayerRelation.You -> [qualifier (Text.pack "you control") (Text.pack "you control")]
  Filter.ControlledBy PlayerRelation.Opponent -> [qualifier (Text.pack "an opponent controls") (Text.pack "your opponents control")]
  Filter.Not (Filter.ControlledBy PlayerRelation.You) -> [qualifier (Text.pack "you don't control") (Text.pack "you don't control")]
  Filter.IsPlayer PlayerRelation.Opponent -> [noun (Text.pack "opponent") (Just (Text.pack "opponents"))]
  Filter.IsPlayer PlayerRelation.AnyPlayer -> [noun (Text.pack "player") (Just (Text.pack "players"))]
  _ -> []

-- | The phrase in the given number, with the noun the context supplies when
-- the filter names none: a filter over permanents that says only "nonblack"
-- describes a nonblack permanent. Of several nouns the kinds of object (card
-- types, "spell") stand last and only the last is plural: "Sliver creatures",
-- "artifact creatures", "creature spells".
describe :: Number -> Noun -> Phrase -> [Text.Text]
describe number fallback p = do
  let chosen = case nouns p of
        [] -> [fallback]
        ns -> ns
      (typed, named) = List.partition kind chosen
  headword <- case (number, named <> typed) of
    (Singular, ns) -> [Text.unwords (fmap singular ns)]
    (Plural, ns) -> case List.unsnoc ns of
      Just (front, final) -> Maybe.maybeToList (fmap (\many' -> Text.unwords (fmap singular front <> [many'])) (plural final))
      Nothing -> []
  before <- adjectiveText number (adjectives p)
  after <- traverse (agreeing number) (qualifiers p)
  pure (Text.unwords (filter (not . Text.null) (before <> [headword] <> after)))

-- | Whether the noun names a kind of object (a card type, "spell") rather
-- than a subtype.
kind :: Noun -> Bool
kind n = elem (singular n) (fmap Text.pack ["spell", "permanent", "card"] <> fmap (cardType Singular) [minBound .. maxBound])

-- | A qualifier's wordings in the given number.
agreeing :: Number -> Qualifier -> [Text.Text]
agreeing number q = case number of
  Singular -> [one q]
  Plural -> [many q]

-- | Adjectives as Oracle text strings them: "other" first ("other white
-- creatures"), and "non-" ones separated by commas ("nonartifact, nonblack"),
-- with the type ones first, as Terror prints them. Free: the "non-" ones
-- after the others ("attacking nonwhite") or before them ("nonwhite
-- attacking", Exile).
adjectiveText :: Number -> [Qualifier] -> [[Text.Text]]
adjectiveText number qs = do
  as <- traverse (agreeing number) qs
  let (negated, plain) = List.partition (Text.isPrefixOf (Text.pack "non")) as
      ordered = List.sortOn (\a -> elem (Text.drop 3 a) (fmap color [minBound .. maxBound])) negated
      plain' = List.sortOn (/= Text.pack "other") plain
      negated' = [Text.intercalate (Text.pack ", ") ordered | not (null ordered)]
  [plain' <> negated'] <> [negated' <> plain' | not (null plain'), not (null negated'), notElem (Text.pack "other") plain']

empty :: Phrase
empty = MkPhrase [] [] []

merge :: Phrase -> Phrase -> Phrase
merge a b = MkPhrase (adjectives a <> adjectives b) (nouns a <> nouns b) (qualifiers a <> qualifiers b)

noun :: Text.Text -> Maybe Text.Text -> Phrase
noun s p = MkPhrase [] [MkNoun s p] []

adjective :: Text.Text -> Phrase
adjective a = MkPhrase [MkQualifier a a] [] []

qualifier :: Text.Text -> Text.Text -> Phrase
qualifier o m = MkPhrase [] [] [MkQualifier o m]

-- | The card type a filter names, if that is all it names.
cardTypeOf :: Filter.Filter k -> Maybe CardType.CardType
cardTypeOf f = case f of
  Filter.HasCardType t -> Just t
  _ -> Nothing

-- | A disjunction of every permanent type as CR 110.4a names it, "permanent",
-- and of every one but one as "nonland permanent".
permanentCard :: Set.Set CardType.CardType -> Maybe Phrase
permanentCard ts =
  let permanents = Set.fromList [CardType.Artifact, CardType.Battle, CardType.Creature, CardType.Enchantment, CardType.Land, CardType.Planeswalker]
      thing = noun (Text.pack "permanent") (Just (Text.pack "permanents"))
   in case Set.toList (Set.difference permanents ts) of
        _ | not (Set.isSubsetOf ts permanents) -> Nothing
        [] -> Just thing
        [t] -> Just (merge (adjective (Text.pack "non" <> cardType Singular t)) thing)
        _ -> Nothing

-- | Disjoined phrases: adjectives alone join into one ("attacking or
-- blocking"), colours "and/or" in the plural, since one object may have both
-- ("white and/or blue creatures", Ignite Disorder), and whole phrases join
-- into one noun ("artifact or enchantment"), whose plural Oracle text writes
-- with "and" ("all creatures and lands", Devastation) where the nouns are
-- bare, and not at all otherwise.
disjunction :: [Phrase] -> [Phrase]
disjunction ps
  | length ps < 2 = []
  | all (\p -> null (nouns p) && null (qualifiers p) && length (adjectives p) == 1) ps = do
      let adjs = concatMap adjectives ps
          colours = all (\q -> elem (one q) (fmap color [minBound .. maxBound])) adjs
          conjunction = if colours then "and/or" else "or"
      [MkPhrase [MkQualifier (Prose.listing "or" (fmap one adjs)) (Prose.listing conjunction (fmap many adjs))] [] []]
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
  let irregular = [("Plains", "Plains"), ("Elf", "Elves"), ("Merfolk", "Merfolk"), ("Dwarf", "Dwarves"), ("Wolf", "Wolves"), ("Werewolf", "Werewolves"), ("Mouse", "Mice"), ("Fungus", "Fungi"), ("Ox", "Oxen"), ("Thief", "Thieves")]
      ends suffix = Text.isSuffixOf (Text.pack suffix) word
   in case lookup (Text.unpack word) irregular of
        Just p -> Text.pack p
        Nothing
          | ends "y" && not (any ends ["ay", "ey", "oy", "uy"]) -> Text.dropEnd 1 word <> Text.pack "ies"
          | any ends ["s", "x", "ch", "sh"] -> word <> Text.pack "es"
          | otherwise -> word <> Text.pack "s"
