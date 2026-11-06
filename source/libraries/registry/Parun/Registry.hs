-- Answering two questions: given a card's name, what card is that? And which
-- cards are there?
--
-- The registry is those two functions and nothing else. It is parameterized over the
-- monad a LOOKUP works in, which is what lets a registry that does no IO to
-- answer -- a fixture map, a pool compiled in, a generated one, or the
-- file-backed one below, which reads every file's bytes before the registry
-- exists and parses them only as lookups reach them -- be used at whatever monad
-- the caller has, without pretending to do IO. The parameter earns its keep at
-- the other end: a registry fetching cards on demand from a remote source
-- genuinely needs effects at lookup time, mid-game where
-- Parun.Interpreter.lookingUpCards asks, and m is the difference. How a registry
-- answers is not part of the type.
--
-- Enumerating the pool is in the interface for the questions a game asks about
-- the whole reference: which cards an Alchemy conjure picks over, and which
-- names Spy Kit's CR 612.7 grant reaches (Parun.Interpreter.lookingUpCards). A
-- lint of the corpus parun ships is a claim about the data rather than a
-- question for a registry, and that lives in the test suite -- every file
-- parses (Parun.CardsSpec), no card repeats a face name and no two cards claim
-- one (Parun.EffectLintSpec) -- which borrows cardPath, listRoot, loadRoot,
-- parseCard and filedAs: facts about the on-disk format rather than about
-- looking a card up.
module Parun.Registry where

import qualified Control.Exception as Exception
import qualified Data.Bifunctor as Bifunctor
import qualified Data.ByteString as ByteString
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Parun.Codec.Card as Card
import qualified Parun.Engine.Card as EngineCard
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.Exceptions.MissingRoot as MissingRoot
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Slug as Slug
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Face as Face
import qualified Paths_parun as Paths
import qualified System.Directory as Directory

-- Nothing says only that no card has that name, and the caller supplied the
-- name (#649). A lookup that reaches a file the registry cannot use answers
-- InvalidCorpus instead, so a broken root never reads as a missing card; what
-- that means is the caller's to decide.
data Registry m = MkRegistry
  { fetchCard :: CardName.CardName -> m (Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)),
    -- | Every card of the Oracle card reference the pool holds, once each. A
    -- synthetic test fixture is in the pool without being such a card.
    cards :: m (Either InvalidCorpus.InvalidCorpus [Card.Card])
  }

-- A card by name ("Goblin Piker") or by slug ("goblin-piker") -- a file-backed
-- registry slugifies, and slugify is idempotent, so both are the same lookup.
-- Takes a String because parun does not enable OverloadedStrings: the newtype is
-- what the interface speaks, this is what callers write.
named :: Registry m -> String -> m (Either InvalidCorpus.InvalidCorpus (Maybe Card.Card))
named registry = fetchCard registry . CardName.MkCardName . Text.pack

-- The card corpus's default root: data/cards declared as cabal data-files,
-- resolved through the cabal-generated Paths_parun so an installed parun finds
-- its cards. A default, not a hidden global -- 'fileRegistry' still takes an
-- explicit FilePath.
defaultRoot :: IO FilePath
defaultRoot = Paths.getDataFileName "cards"

-- A registry over a directory of one-card-per-file JSON, read once, here, and
-- parsed only as far as lookups reach.
--
-- The root is checked before anything else because a mistyped --cards-dir
-- otherwise surfaces as N identical failures, one per card, instead of one
-- clear failure at startup (#167).
--
-- Every file's bytes are read now and its parse is a pure thunk, shared by
-- every lookup and by `cards`, so each file is parsed at most once (#265)
-- without a lock or unsafeInterleaveIO. A lookup parses the files whose names
-- hold its slug as a run of words, which under filedAs is every file the name
-- can belong to; failing that, it falls back to one index of the whole root,
-- built once, which is what still finds a card in a misfiled root and what
-- answers Nothing. `cards` forces that same index.
--
-- A lookup or enumeration that reaches a file that will not parse, or a name
-- two cards claim, answers InvalidCorpus naming every such problem among the
-- files it reached. The rest of the root is not validated here; the corpus
-- parun ships is, by the lints the module header names.
--
-- The two halves of the signature are construction and lookup, and they are not
-- the same monad: building the registry reads the directory, so construction is
-- IO, while a lookup is pure work wrapped in pure, so it works in any
-- Applicative. Applicative rather than Monad because pure is the only thing the
-- body needs of m.
fileRegistry :: (Applicative m) => FilePath -> IO (Registry m)
fileRegistry root = do
  exists <- Directory.doesDirectoryExist root
  if not exists
    then Exception.throwIO MissingRoot.MkMissingRoot {MissingRoot.path = root}
    else do
      loaded <- loadRoot root
      let usable :: Either [String] a -> Either InvalidCorpus.InvalidCorpus a
          usable = Bifunctor.first (\problems -> InvalidCorpus.MkInvalidCorpus {InvalidCorpus.root = root, InvalidCorpus.problems = problems})
          whole = usable (index loaded)
          byRun = Map.fromListWith (<>) (concatMap (\entry -> fmap (\run -> (run, [entry])) (Set.toList (runs (stemOf (fst entry))))) loaded)
          find name = do
            let slug = slugFor name
            near <- usable (index (Map.findWithDefault [] slug byRun))
            case Map.lookup slug near of
              Just card -> Right (Just card)
              Nothing -> fmap (Map.lookup slug) whole
      pure MkRegistry {fetchCard = pure . find, cards = pure (fmap (const (Maybe.mapMaybe referenceCard loaded)) whole)}

-- The slug a card file is named by: its file name, less the directory and the
-- extension.
stemOf :: FilePath -> Slug.Slug
stemOf path = Slug.fromText (Text.pack (List.reverse (List.drop (List.length ".json") (List.takeWhile (/= '/') (List.reverse path)))))

-- Every run of consecutive words in a slug, each once however often it recurs.
-- filedAs joins a card's face names, so each face name's slug is one of these
-- runs of the card's file name.
runs :: Slug.Slug -> Set.Set Slug.Slug
runs slug =
  let segments = Text.splitOn (Text.singleton '-') (Slug.unwrap slug)
   in Set.fromList $ do
        start <- List.tails segments
        size <- [1 .. List.length start]
        pure (Slug.fromText (Text.intercalate (Text.singleton '-') (List.take size start)))

-- A parsed card of the Oracle card reference, which a synthetic is not: a card
-- no printing carries, written only to reach a rule, and filed as
-- `synthetic-*.json` (docs/design.md section 6).
referenceCard :: (FilePath, Either Text.Text Card.Card) -> Maybe Card.Card
referenceCard (path, parsed) =
  if "synthetic-" `List.isPrefixOf` List.reverse (List.takeWhile (/= '/') (List.reverse path))
    then Nothing
    else either (const Nothing) Just parsed

-- The slug a name is looked up by. `named` accepts a name or a slug for the
-- same reason: slugify is idempotent, so the two are one lookup.
slugFor :: CardName.CardName -> Slug.Slug
slugFor = Slug.fromText . CardName.unwrap

-- Every name a lookup answers to, pointing at its card -- or every reason the
-- pool cannot be indexed.
--
-- Two tiers. A card's OWN names are the ones it has off the stack
-- (Parun.Engine.Card.combinedNames): both halves of a split card (CR 709.4a),
-- the one name of anything else. Its other faces' names are ALTERNATIVE: an
-- Adventure's, an omen's or a prepare spell's (CR 715.4, 720.4, 722.4), a back
-- face's (CR 712.8a). A card does not have those, but a player may choose one
-- as a card name (CR 715.5, 720.5, 722.5, 201.4d), which a name-keyed lookup has
-- to answer all the same (Parun.Interpreter.chosenFace). So an own name wins: a
-- prepare spell reprinting a real card (Encouraging Aviator's Jump) leaves the
-- name to that card, and only a name no card owns answers by its alternative.
--
-- An own name claimed by two cards is fatal, and so is a card repeating its own
-- face name; see 'ambiguities'.
index :: [(FilePath, Either Text.Text Card.Card)] -> Either [String] (Map.Map Slug.Slug Card.Card)
index loaded =
  let parsed = Maybe.mapMaybe (\entry -> case entry of (path, Right card) -> Just (path, card); _ -> Nothing) loaded
      unparsed = Maybe.mapMaybe (\entry -> case entry of (path, Left reason) -> Just (path <> ": " <> Text.unpack reason); _ -> Nothing) loaded
      claimed = claims parsed
      answer claimants = case (Map.toList (owners claimants), Map.toList (alternatives claimants)) of
        ([(_, card)], _) -> Just card
        ([], [(_, card)]) -> Just card
        _ -> Nothing
   in case unparsed <> ambiguities parsed of
        [] -> Right (Map.mapMaybe answer claimed)
        problems -> Left problems

-- Who claims one name: the cards owning it and the cards holding it only as an
-- alternative, each by path, with every face of a path that claims it.
data Claimants = MkClaimants
  { owners :: Map.Map FilePath Card.Card,
    alternatives :: Map.Map FilePath Card.Card,
    claimsPerPath :: Map.Map FilePath Int
  }

instance Semigroup Claimants where
  MkClaimants a b c <> MkClaimants a' b' c' = MkClaimants (Map.union a a') (Map.union b b') (Map.unionWith (+) c c')

-- Every face name of every card, by slug, with who claims it.
claims :: [(FilePath, Card.Card)] -> Map.Map Slug.Slug Claimants
claims parsed = Map.fromListWith (<>) $ do
  (path, card) <- parsed
  let own = Set.map slugFor (EngineCard.combinedNames card)
  face <- NonEmpty.toList (Card.faces card)
  let slug = slugFor (Face.name face)
      held = Map.singleton path card
      claimant = if Set.member slug own then MkClaimants held Map.empty else MkClaimants Map.empty held
  pure (slug, claimant (Map.singleton path 1))

-- Every name the pool cannot answer with one card: one card repeating a face
-- name, two cards owning one, or two cards holding one only as an alternative
-- that no card owns. Over the corpus parun ships, Parun.EffectLintSpec's "no two
-- cards claim one name" holds this for every file.
--
-- Answering a name two cards hold only as an alternative is not implemented
-- (#6457).
ambiguities :: [(FilePath, Card.Card)] -> [String]
ambiguities parsed = do
  (slug, claimants) <- Map.toAscList (claims parsed)
  let name = Text.unpack (Slug.unwrap slug)
      repeats = Map.toAscList (Map.filter (> 1) (claimsPerPath claimants))
      contested = if Map.null (owners claimants) then alternatives claimants else owners claimants
  fmap (\(path, n) -> name <> " is claimed by " <> path <> ", which repeats it across " <> show n <> " of its own faces") repeats
    <> [name <> " is claimed by " <> List.intercalate ", " (Map.keys contested) | Map.size contested > 1]

-- Where the file for a given slug lives, one file per card. What the slug IS
-- varies by caller: for a single-faced card it is the card's own name, but
-- `filedAs` below derives it from a split or adventurer card's JOINED face
-- names instead, so "the card's own name" does not hold in general.
cardPath :: FilePath -> Slug.Slug -> FilePath
cardPath root slug = root <> "/" <> Text.unpack (Slug.unwrap slug) <> ".json"

-- What a card file's bytes mean. Pure, and separate from reading them, because
-- that is exactly what a lookup and the corpus-wide lints agree about; they
-- disagree about how to obtain the bytes and about what a failure to obtain
-- them means. The caller pairs the reason with the path.
--
-- Decoded as UTF-8 explicitly rather than via Data.Text.IO.readFile, which
-- decodes using the locale encoding -- ASCII under LC_ALL=C -- so a card with a
-- non-ASCII character would fail with "invalid byte sequence" instead of naming
-- the offending file.
--
-- Says NOTHING about where the file was found: that is `filedAs` below, and
-- keeping the two apart is what lets a root be read without a filename deciding
-- what any of it answers for.
parseCard :: ByteString.ByteString -> Either Text.Text Card.Card
parseCard bytes = do
  contents <- either (\err -> Left (Text.pack ("not valid UTF-8: " <> show err))) Right (Encoding.decodeUtf8' bytes)
  Common.parse contents >>= Codec.decode Card.codec

-- The slug a card's file is named for: its face names joined, slugified.
--
-- A FILING convention and not a name the card has -- CR 709.4a gives a split
-- card two names and no combined one (#649) -- so this decides where a file
-- LIVES and never what a lookup may ask for. Also not Parun.Engine.Card.combined's
-- name, which is a different question and only coincidentally the same string:
-- CR 715.4 gives an adventurer card its normal face's name alone, so the
-- combined view would name embereth-shieldbreaker while the file is
-- embereth-shieldbreaker-battle-display.
filedAs :: Card.Card -> Slug.Slug
filedAs = Slug.fromText . CardName.unwrap . CardName.join . fmap Face.name . Card.faces

-- Every card file in a root, ascending by path, each paired with what its bytes
-- mean. One IO pass over the whole directory: this is what a registry is built
-- from and what the corpus-wide lints sweep, so neither has to restate how a
-- pool is enumerated.
--
-- Per-file Either rather than an exception, so one pass can name every bad file
-- instead of dying on the first -- but that covers only a file that will not
-- PARSE. ByteString.readFile below is unguarded: a file that cannot be READ (a
-- permission error, or one removed between listDirectory and the read) throws
-- a raw IOException and aborts construction rather than being reported as one
-- more problem. The deleted loadFile drew this same line; it survives here.
--
-- Sorted so that what a caller reports first is a fact about the pool rather
-- than about the order a directory happens to enumerate in. Non-.json entries
-- are ignored outright -- a README is not a broken card.
loadRoot :: FilePath -> IO [(FilePath, Either Text.Text Card.Card)]
loadRoot root = do
  paths <- listRoot root
  mapM (\path -> fmap (\bytes -> (path, parseCard bytes)) (ByteString.readFile path)) paths

-- Every card file in a root, ascending by path, read no further: the
-- enumeration half of 'loadRoot', for a caller that parses each file later.
listRoot :: FilePath -> IO [FilePath]
listRoot root = do
  entries <- fmap List.sort (Directory.listDirectory root)
  pure (fmap (\entry -> root <> "/" <> entry) (filter (List.isSuffixOf ".json") entries))
