-- Covers Pawl.Registry. Every test builds its own corpus in a temporary
-- directory: the committed data/cards is read-only here, and the failure modes
-- (an unknown card, a missing root, a malformed file, two cards claiming one
-- name) have no representative in it -- the last two because the corpus lints
-- in Pawl.CardsSpec and Pawl.EffectLintSpec forbid them.
module Pawl.RegistrySpec where

import qualified Control.Exception as Exception
import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Char8 as ByteString.Char8
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.Engine.Card as Card
import qualified Pawl.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Pawl.Exceptions.MissingRoot as MissingRoot
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Card as Card.Type
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Printing as Printing
import qualified System.Directory as Directory

-- A registry over a throwaway corpus, handing the case both the root (for the
-- one case that removes a file from it) and the registry itself.
withCorpus :: String -> [(FilePath, Text.Text)] -> (FilePath -> Registry.Registry IO -> IO a) -> IO a
withCorpus label files action =
  S.withCorpusDir label files (\dir -> Registry.fileRegistry dir >>= action dir)

-- Like withCorpus, but writes a single file's raw bytes rather than Text:
-- withCorpus cannot express a file containing invalid UTF-8, since Text.Text
-- cannot hold one. This exercises Registry.parseCard's decodeUtf8' failure
-- branch, otherwise unreached by any case here.
withInvalidUtf8Corpus :: String -> (FilePath -> Registry.Registry IO -> IO a) -> IO a
withInvalidUtf8Corpus label action = do
  tmp <- Directory.getTemporaryDirectory
  let dir = tmp <> "/pawl-registry-spec-" <> label
      -- Valid JSON except for a lone 0xFF byte inside the name string, which
      -- is not valid UTF-8 on its own (it is never a legal leading byte).
      badBytes =
        ByteString.concat
          [ ByteString.Char8.pack "{\"name\": \"Goblin Piker",
            ByteString.singleton 0xFF,
            ByteString.Char8.pack "\"}"
          ]
  Exception.bracket_
    ( do
        Directory.createDirectoryIfMissing True dir
        ByteString.writeFile (dir <> "/goblin-piker.json") badBytes
    )
    (Directory.removeDirectoryRecursive dir)
    (Registry.fileRegistry dir >>= action dir)

-- An IO action that must fail with a specific exception VALUE. The `expected`
-- argument fixes Exception.try's type, so no ScopedTypeVariables is needed.
-- Building a registry throws only for a missing root (MissingRoot), and this
-- checks its exact value, since MissingRoot carries only the one path. A broken
-- pool answers InvalidCorpus from a lookup instead, asserted on via problemsOf.
--
-- Takes the build itself rather than any IO action: fileRegistry's result is
-- polymorphic in the lookup monad, and a case that only ever throws never
-- settles it, so naming Registry IO here is what makes these calls unambiguous.
expectException :: (Exception.Exception e, Eq e) => Spec.Spec IO n -> String -> e -> IO (Registry.Registry IO) -> IO ()
expectException s label expected action = do
  result <- Exception.try action
  case result of
    Left err -> Spec.assertEqWith s label err expected
    Right _ -> Spec.assertFailure s (label <> ": expected " <> show expected <> ", got a value")

-- The problems an InvalidCorpus carries, for the cases that assert on their
-- content: the lookup or enumeration that reached them must answer one.
problemsOf :: Spec.Spec IO n -> String -> IO (Either InvalidCorpus.InvalidCorpus a) -> IO [String]
problemsOf s label action = do
  result <- action
  case result of
    Left err -> pure (InvalidCorpus.problems err)
    Right _ -> Spec.assertFailure s (label <> ": expected an InvalidCorpus")

-- Whether a lookup found a card, its InvalidCorpus kept: what lets a case
-- asserting that a lookup still answers name that assertion when it fails.
found :: IO (Either InvalidCorpus.InvalidCorpus (Maybe a)) -> IO (Either InvalidCorpus.InvalidCorpus Bool)
found = fmap (fmap Maybe.isJust)

spec :: (Monad n) => Spec.Spec IO n -> n ()
spec s = Spec.describe s "Pawl.Registry" $ do
  Spec.it s "a card loads by its real name" $ do
    piker <- S.pikerJson
    withCorpus "by-name" [("goblin-piker.json", piker)] $ \_ registry -> do
      p <- S.printingOf s registry "Goblin Piker"
      Spec.assertEq s (S.nameOf $ Printing.card p) . CardName.MkCardName $ Text.pack "Goblin Piker"

  Spec.it s "the same card loads by its slug -- slugify is idempotent" $ do
    piker <- S.pikerJson
    withCorpus "by-slug" [("goblin-piker.json", piker)] $ \_ registry -> do
      byName <- Registry.named registry "Goblin Piker"
      bySlug <- Registry.named registry "goblin-piker"
      Spec.assertEq s byName bySlug

  -- CR 709.4a: "Each split card has two names." Neither of them is the joined
  -- string the file is named for, so a lookup by either half's own name is a
  -- map hit under its own key, the same as any other name (#649).
  Spec.it s "CR 709.4a a split card is found by either of its names" $ do
    waxWane <- S.waxWaneJson
    withCorpus "split-by-either-name" [("wax-wane.json", waxWane)] $ \_ registry -> do
      byLeft <- Registry.named registry "Wax"
      byRight <- Registry.named registry "Wane"
      Spec.assertEqWith s "the same one card" byLeft byRight
      -- CR 709.2: "each split card is only one card", so what came back is the
      -- whole two-faced card rather than the half that was asked for. Without
      -- this, a fallback that returned some OTHER card entirely would pass the
      -- equality above.
      Spec.assertEqWith
        s
        "both faces"
        (fmap (fmap (fmap Face.name . NonEmpty.toList . Card.Type.faces)) byLeft)
        (Right (Just (fmap (CardName.MkCardName . Text.pack) ["Wax", "Wane"])))
      -- CR 709.4a gives a split card two names and no combined one, so the
      -- joined string is not a name a lookup may ask for -- it survived until
      -- now only because it happened to be the file name (#649).
      byJoined <- Registry.named registry "Wax // Wane"
      Spec.assertEqWith s "and not by the two joined" byJoined (Right Nothing)

  -- A word can recur in a file's name -- Grub, Storied Matriarch // Grub,
  -- Notorious Auntie -- and a lookup by it reaches that one file once, not
  -- once per occurrence, which would read as the card claiming the name twice.
  Spec.it s "a name whose words recur in its file's name reaches that file once" $ do
    waxWane <- S.waxWaneJson
    let recurring = Text.replace (Text.pack "\"name\": \"Wane\"") (Text.pack "\"name\": \"Wax Wane\"") waxWane
    Spec.assertBool s (recurring /= waxWane) "the fixture's back face was actually renamed"
    withCorpus "recurring" [("wax-wax-wane.json", recurring)] $ \_ registry -> do
      byWord <- found (Registry.named registry "Wax")
      Spec.assertEqWith s "found by the word its file name repeats" byWord (Right True)

  -- The registry reads every file's bytes when it is built and parses them
  -- later, so a file that vanishes in between is still there to parse.
  Spec.it s "a card's file is read when the registry is built: it is still found once its file has vanished" $ do
    piker <- S.pikerJson
    withCorpus "cached" [("goblin-piker.json", piker)] $ \root registry -> do
      Directory.removeFile (root <> "/goblin-piker.json")
      afterwards <- found (Registry.named registry "Goblin Piker")
      Spec.assertEqWith s "read at construction, before the file vanished" afterwards (Right True)

  -- A lookup says nothing about files, because it belongs to the interface and
  -- a map-backed registry has no path to report. Nothing says only that no card
  -- has the name; a file that will not parse answers InvalidCorpus instead (the
  -- cases below).
  Spec.it s "an unknown card is missing"
    . withCorpus "missing" []
    $ \_ registry -> do
      result <- Registry.named registry "Goblin Piker"
      Spec.assertEqWith s "missing, by name" result (Right Nothing)

  -- A lazy registry parses what a lookup reaches, so a malformed file is
  -- reported by the lookup that reaches it -- naming it, rather than answering
  -- Nothing as though a broken root were a missing card -- and a lookup that
  -- does not reach it is not poisoned by it. Wax and Wane are the halves of a
  -- file named for neither, which is what shows they resolve without the
  -- fallback over the whole root, which would reach the malformed file.
  Spec.it s "a lookup that reaches a malformed file fails, naming it, and one that does not still answers" $ do
    piker <- S.pikerJson
    waxWane <- S.waxWaneJson
    withCorpus "malformed" [("goblin-piker.json", piker), ("wax-wane.json", waxWane), ("bird-maiden.json", Text.pack "{oh no")] $ \root registry -> do
      problems <- problemsOf s "malformed" (Registry.named registry "Bird Maiden")
      Spec.assertEqWith s "one problem, for the one bad file" (length problems) 1
      Spec.assertBool s (any (List.isInfixOf (root <> "/bird-maiden.json")) problems) ("names the path: " <> show problems)
      Spec.assertBool s (not (any (List.isInfixOf "goblin-piker") problems)) ("and not the good file: " <> show problems)
      byName <- found (Registry.named registry "Goblin Piker")
      Spec.assertEqWith s "a card filed under its own name still loads" byName (Right True)
      byLeft <- found (Registry.named registry "Wax")
      Spec.assertEqWith s "the left half still loads" byLeft (Right True)
      byRight <- found (Registry.named registry "Wane")
      Spec.assertEqWith s "the right half still loads" byRight (Right True)

  -- A name no file is named for falls back to the whole root, which reaches
  -- every file; index's comment claims it names every offender at once, not
  -- the first (#167), and two bad files are what proves the whole pass runs.
  Spec.it s "a lookup that falls back to the whole root names every malformed file, not just the first" $ do
    withCorpus "malformed-two" [("bird-maiden.json", Text.pack "{oh no"), ("wax-wane.json", Text.pack "[also no")] $ \root registry -> do
      problems <- problemsOf s "malformed-two" (Registry.named registry "Shivan Dragon")
      Spec.assertEqWith s "one problem per bad file" (length problems) 2
      Spec.assertBool s (any (List.isInfixOf (root <> "/bird-maiden.json")) problems) ("names the first: " <> show problems)
      Spec.assertBool s (any (List.isInfixOf (root <> "/wax-wane.json")) problems) ("names the second: " <> show problems)

  -- Enumeration reaches every file, so it is refused over a root holding one
  -- that will not parse rather than quietly listing the rest.
  Spec.it s "the pool's cards are refused over a root holding a malformed file" $ do
    piker <- S.pikerJson
    withCorpus "cards-malformed" [("goblin-piker.json", piker), ("bird-maiden.json", Text.pack "{oh no")] $ \root registry -> do
      problems <- problemsOf s "cards-malformed" (Registry.cards registry)
      Spec.assertBool s (any (List.isInfixOf (root <> "/bird-maiden.json")) problems) ("names the path: " <> show problems)
    withCorpus "cards-sound" [("goblin-piker.json", piker)] $ \_ registry -> do
      listed <- Registry.cards registry
      Spec.assertEqWith s "and listed over a sound one" (fmap (fmap S.nameOf) listed) (Right [CardName.MkCardName (Text.pack "Goblin Piker")])

  -- CR 709.4a: a name belongs to a card, so one name answering for two cards is
  -- a broken pool rather than a lookup with a preference: a silent
  -- last-one-wins would be a lookup quietly serving a card it was not asked
  -- for. Over the corpus pawl ships, Pawl.EffectLintSpec's "no two cards claim
  -- one name" holds this for every name.
  Spec.it s "a lookup reaching two cards that claim its name fails, naming both" $ do
    waxWane <- S.waxWaneJson
    withCorpus "ambiguous" [("wax-wane.json", waxWane), ("wane-wax.json", waxWane)] $ \root registry -> do
      problems <- problemsOf s "ambiguous" (Registry.named registry "Wax")
      Spec.assertBool s (any (List.isInfixOf "wax") problems) ("names the ambiguous name: " <> show problems)
      Spec.assertBool s (any (List.isInfixOf (root <> "/wax-wane.json")) problems) ("names the first claimant: " <> show problems)
      Spec.assertBool s (any (List.isInfixOf (root <> "/wane-wax.json")) problems) ("names the second claimant: " <> show problems)

  -- index's own comment says a name claimed twice is fatal "wherever it comes
  -- from -- two cards, or one card repeating its own face name"; the case
  -- above is the two-cards half, this is the one-card half. Built by hand
  -- (Wane renamed to Wax) rather than by editing data/cards, since a card
  -- that offends a lint must not be a card file pawl ships.
  Spec.it s "a lookup reaching a card that repeats a face name fails, naming it" $ do
    waxWane <- S.waxWaneJson
    let selfRepeating = Text.replace (Text.pack "\"name\": \"Wane\"") (Text.pack "\"name\": \"Wax\"") waxWane
    withCorpus "self-repeating" [("wax-wane.json", selfRepeating)] $ \root registry -> do
      problems <- problemsOf s "self-repeating" (Registry.named registry "Wax")
      Spec.assertBool s (any (List.isInfixOf (root <> "/wax-wane.json")) problems) ("names the file: " <> show problems)
      -- Legibility, not just correctness: the message must say the ONE file
      -- was claimed twice rather than rendering it as though two different
      -- claimants happened to share a path (#649).
      Spec.assertBool s (any (List.isInfixOf "wax is claimed by") problems) ("names the repeated name: " <> show problems)
      Spec.assertBool s (any (List.isInfixOf "its own faces") problems) ("says it is a self-repeat, not a collision: " <> show problems)

  -- CR 400.1: "each player has their own library, hand, and graveyard. The
  -- other zones are shared by all players." A count scoped to one player's
  -- share of a shared zone therefore asks a question the rules do not have,
  -- and it is refused where card data enters the engine rather than only by
  -- Pawl.CardSpec's sweep of the committed pool.
  --
  -- The two corpora below differ in exactly one thing: Nightmare's own scope,
  -- with Relative AnyPlayer narrowed to Relative You. The unmodified file
  -- loading is what makes the rejection attributable to that swap rather than
  -- to anything else about the card, and the assertion that the two texts
  -- differ is what keeps the case from passing vacuously if the file's
  -- formatting changes under it.
  Spec.it s "CR 400.1 a lookup reaching a card dividing a shared zone between players fails" $ do
    nightmare <- S.nightmareJson
    let divided =
          Text.replace
            (Text.pack "\"type\": \"AnyPlayer\"")
            (Text.pack "\"type\": \"You\"")
            nightmare
    Spec.assertBool s (divided /= nightmare) "the fixture's scope was actually divided"
    withCorpus "shared-zone-whole" [("nightmare.json", nightmare)] $ \_ registry -> do
      whole <- found (Registry.named registry "Nightmare")
      Spec.assertEqWith s "the undivided card loads" whole (Right True)
    withCorpus "shared-zone-divided" [("nightmare.json", divided)] $ \root registry -> do
      problems <- problemsOf s "shared-zone-divided" (Registry.named registry "Nightmare")
      Spec.assertBool s (any (List.isInfixOf (root <> "/nightmare.json")) problems) ("names the file: " <> show problems)
      Spec.assertBool s (any (List.isInfixOf "Battlefield") problems) ("names the shared zone: " <> show problems)

  -- The filename is a filing convention with no standing in the rules (#649),
  -- so it decides where a file LIVES and never what a lookup may ask for. No
  -- file is named for Goblin Piker here, so finding it is the fallback over
  -- the whole root.
  Spec.it s "a card is found by its own name, and never by its file name" $ do
    piker <- S.pikerJson
    withCorpus "misfiled" [("bird-maiden.json", piker)] $ \_ registry -> do
      byOwnName <- found (Registry.named registry "Goblin Piker")
      Spec.assertEqWith s "found by the name the card has" byOwnName (Right True)
      byFileName <- Registry.named registry "Bird Maiden"
      Spec.assertEqWith s "and not by the name its file has" byFileName (Right Nothing)

  Spec.it s "a lookup reaching an undecodable file fails, naming the decode failure"
    . withInvalidUtf8Corpus "invalid-utf8"
    $ \root registry -> do
      problems <- problemsOf s "invalid-utf8" (Registry.named registry "Goblin Piker")
      Spec.assertBool s (any (List.isInfixOf (root <> "/goblin-piker.json")) problems) ("names the path: " <> show problems)
      -- Specifically the decodeUtf8' failure, not merely any problem: an
      -- incomplete JSON payload (this file's contents) would fail for an
      -- unrelated reason once decoded, so this pins the decode branch.
      Spec.assertBool s (any (List.isInfixOf "not valid UTF-8") problems) ("names the decode failure: " <> show problems)

  -- (b) A mistyped --cards-dir should fail once, at startup, rather than
  -- once per card looked up (#167). It is the one failure of CONSTRUCTING a
  -- file registry rather than of fetching a card.
  Spec.it s "a root that does not exist is rejected when the registry is built, not at the first lookup" $ do
    tmp <- Directory.getTemporaryDirectory
    let missing = tmp <> "/pawl-registry-spec-no-such-root"
    Directory.removePathForcibly missing
    expectException s "missing root" MissingRoot.MkMissingRoot {MissingRoot.path = missing} (Registry.fileRegistry missing)

  -- What a registry is built from and what the corpus-wide lints sweep, so
  -- neither restates how a pool is enumerated. Ascending, .json only, and a
  -- file that will not parse is a reported Left rather than a thrown exception
  -- -- one pass names every bad file instead of dying on the first.
  Spec.it s "loadRoot pairs every card file with what its bytes mean" $ do
    piker <- S.pikerJson
    S.withCorpusDir
      "load-root"
      [ ("goblin-piker.json", piker),
        ("bird-maiden.json", Text.pack "{oh no"),
        ("README.md", Text.pack "not a card")
      ]
      $ \root -> do
        loaded <- Registry.loadRoot root
        Spec.assertEqWith s "ascending, .json only" (fmap fst loaded) [root <> "/bird-maiden.json", root <> "/goblin-piker.json"]
        Spec.assertEqWith s "the good one parsed" (Maybe.mapMaybe (\entry -> case snd entry of Right c -> Just (Face.name (Card.combined c)); Left _ -> Nothing) loaded) [CardName.MkCardName $ Text.pack "Goblin Piker"]
        Spec.assertEqWith s "and the bad one is reported, not thrown" (length (Maybe.mapMaybe (\entry -> case snd entry of Left reason -> Just reason; Right _ -> Nothing) loaded)) 1
