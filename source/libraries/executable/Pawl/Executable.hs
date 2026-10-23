module Pawl.Executable where

import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Builder as Builder
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Data.Text.IO as TextIO
import qualified Pawl.Benchmark
import qualified Pawl.Codec.Card as Card
import qualified Pawl.Codec.Scenario as Codec.Scenario
import qualified Pawl.Codec.StickerSheet as StickerSheet
import qualified Pawl.DeckList as DeckList
import qualified Pawl.Ingest as Ingest
import qualified Pawl.Json.Value as Value
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonSchema.Define as Define
import qualified Pawl.Mtgish as Mtgish
import qualified Pawl.Oracle as Oracle
import qualified Pawl.Oracle.Normalise as Normalise
import qualified Pawl.Play.Command
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Scenario.Load as Load
import qualified Pawl.StickerSheets as StickerSheets
import qualified Pawl.Test
import qualified Pawl.Types.Card as Card.Type
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.StickerSheet as StickerSheet.Type
import qualified System.Directory as Directory
import qualified System.Environment as Environment
import qualified System.Exit as Exit
import qualified System.IO as IO

-- | Every entry point the package has, behind one dispatch. The `pawl`
-- executable, the test suite and the benchmark are all thin `Main.hs` wrappers
-- around this module and the two it delegates to, so importing this and
-- calling 'main' is exactly the installed binary.
--
-- Both delegates parse their own arguments (tasty and tasty-bench each read
-- 'Environment.getArgs' themselves), so the subcommand is stripped with
-- 'Environment.withArgs' rather than passed along.
main :: IO ()
main = do
  arguments <- Environment.getArgs
  case arguments of
    ["schema"] -> schema
    ["schema", "scenario"] -> scenarioSchema
    ["deck", path] -> deck path
    ["ingest", path] -> ingest path
    ["oracle"] -> oracle
    "translate" : mtgish : candidates : rest@(_ : _) -> translate mtgish candidates rest
    "scenario" : paths@(_ : _) -> scenario paths
    "play" : rest -> Pawl.Play.Command.main rest
    "bench" : rest -> Environment.withArgs rest Pawl.Benchmark.main
    "test" : rest -> Environment.withArgs rest Pawl.Test.main
    _ -> do
      name <- Environment.getProgName
      IO.hPutStrLn IO.stderr $ "usage: " <> name <> " (schema [scenario] | deck FILE | ingest FILE | oracle | translate MTGISH CANDIDATES [--out DIR] [--set CODE] [NAME | @FILE...] | scenario FILE... | play [OPTION...] DECK DECK | bench | test)"
      Exit.exitFailure

-- | Reads a deck list and writes back the deck it means, which is what makes a
-- deck expressible as the text a player types rather than only as Haskell.
-- Round-tripping it is the point: the output is itself a deck list, so a name
-- that resolved is echoed in the spelling this pool files it under.
--
-- Decoded as UTF-8 explicitly rather than through TextIO.readFile, for
-- Pawl.Registry.parseCard's reason: that one decodes using the locale encoding,
-- so a card with a non-ASCII character in its name would fail under LC_ALL=C.
deck :: FilePath -> IO ()
deck path = do
  bytes <- ByteString.readFile path
  case Encoding.decodeUtf8' bytes of
    Left err -> do
      IO.hPutStrLn IO.stderr $ path <> ": not valid UTF-8: " <> show err
      Exit.exitFailure
    Right contents -> do
      root <- Registry.defaultRoot
      registry <- Registry.fileRegistry root
      result <- DeckList.parse registry contents
      case result of
        Left corpus -> do
          IO.hPutStrLn IO.stderr (Exception.displayException corpus)
          Exit.exitFailure
        Right (Left problems) -> do
          mapM_ (TextIO.hPutStrLn IO.stderr . (\p -> Text.pack (path <> ": ") <> DeckList.explain p)) problems
          Exit.exitFailure
        Right (Right parsed) -> TextIO.putStr (DeckList.render parsed)

-- | Reads script/ingest/candidates.jq's reduction of MTGJSON's AtomicCards and
-- writes a card file for every keyword-only card it holds, Oracle text included
-- (#9). A card already in the pool is never overwritten -- the hand-written
-- file wins -- and is named on stderr if it says something other than MTGJSON
-- does. Then every pool card gains its faces' Oracle text, the one field this
-- writes into a hand-written file. Files are written compact;
-- `script/format-json.sh fix` puts them in canonical form.
--
-- Prints what it did, and why the cards it did not write were left out, by the
-- kind of word that disqualified them.
ingest :: FilePath -> IO ()
ingest path = do
  bytes <- ByteString.readFile path
  let parsed = do
        contents <- either (\err -> Left (Text.pack ("not valid UTF-8: " <> show err))) Right (Encoding.decodeUtf8' bytes)
        fields <- Common.parse contents >>= Common.asObject
        records <- Common.field "cards" fields >>= Common.asArray
        known <- Common.field "texts" fields >>= Ingest.texts
        pure (records, known)
  case parsed of
    Left problem -> do
      TextIO.hPutStrLn IO.stderr (Text.pack (path <> ": ") <> problem)
      Exit.exitFailure
    Right (records, known) -> do
      root <- Registry.defaultRoot
      outcomes <- mapM (ingestOne root) records
      loaded <- Registry.loadRoot root
      stamped <- fmap length . Monad.filterM (stampOne known) $ Maybe.mapMaybe (\entry@(file, _) -> fmap ((,) file) (Registry.referenceCard entry)) loaded
      sheetRoot <- StickerSheets.defaultRoot
      sheets <- StickerSheets.loadRoot sheetRoot
      sheetsStamped <- fmap length (Monad.filterM (stampSheet known) [(file, sheet) | (file, Right sheet) <- sheets])
      let reasons = Map.fromListWith (+) [(Text.takeWhile (/= ':') reason, 1 :: Int) | Left reason <- outcomes]
      putStrLn $ "written: " <> show (length (filter (== Right True) outcomes))
      putStrLn $ "already in the pool: " <> show (length (filter (== Right False) outcomes))
      putStrLn $ "pool files given Oracle text: " <> show stamped
      putStrLn $ "sticker sheets given Oracle text: " <> show sheetsStamped
      putStrLn $ "left out: " <> show (sum reasons)
      mapM_ (\(kind, n) -> TextIO.putStrLn (Text.pack "  " <> kind <> Text.pack (": " <> show n))) (Map.toDescList reasons)

-- | Prints how much of the pool Pawl.Oracle renders, by card and by ability:
-- the coverage the Oracle check measures (#5477). Pawl.IngestSpec checks the
-- cards it renders in full; an ability rendered on any other card is counted
-- but not checked.
oracle :: IO ()
oracle = do
  loaded <- Registry.defaultRoot >>= Registry.loadRoot
  let cards = Maybe.mapMaybe Registry.referenceCard loaded
      rendered = filter (Maybe.isJust . Oracle.render) cards
      abilities = concatMap Oracle.abilities cards
      whole = concatMap Oracle.abilities rendered
  putStrLn $ "rendered: " <> show (length rendered) <> " of " <> show (length cards)
  putStrLn $ "abilities rendered: " <> show (length (filter (not . null) abilities)) <> " of " <> show (length abilities) <> ", " <> show (length whole) <> " of them on cards rendered in full"

-- | Translates the named cards, or a set's, from mtgish's AST file (one card
-- per line) and writes a card file for each that renders back to its Oracle
-- text, which CANDIDATES (script/ingest/candidates.jq's output) supplies, as
-- `pawl ingest` stamps it (#5478). A card the pool already holds is never
-- overwritten; it is named on stderr if its translation differs. With --out
-- every accepted card is written to DIR instead, the pool's included. A name
-- written @FILE stands for the names FILE lists, one a line. Each
-- card rejected is named on stderr with why: the node kind not translated, or
-- what it renders as. A card's printed characteristics are CANDIDATES', not
-- mtgish's ('Ingest.reprint'). Each card accepted is listed with its
-- abilities, each marked new or named with a pool card that shares its
-- wording.
translate :: FilePath -> FilePath -> [String] -> IO ()
translate mtgishPath candidatesPath options = do
  let go (o, c, names) rest = case rest of
        "--out" : dir : more -> go (Just dir, c, names) more
        "--set" : code : more -> go (o, Just (Text.pack code), names) more
        name : more -> go (o, c, names <> [Text.pack name]) more
        [] -> (o, c, names)
      (out, set, requested) = go (Nothing, Nothing, []) options
  bytes <- ByteString.readFile candidatesPath
  let parsed = do
        contents <- either (Left . Text.pack . show) Right (Encoding.decodeUtf8' bytes)
        fields <- Common.parse contents >>= Common.asObject
        known <- Common.field "texts" fields >>= Ingest.texts
        records <- Common.field "cards" fields >>= Common.asArray
        printed <- case set of
          Nothing -> Right []
          Just code -> fmap concat (traverse (inSet code) records)
        named <- traverse (\record -> fmap (\name -> (name, Ingest.printed record)) (Common.asObject record >>= Common.field "name" >>= Common.asText)) records
        pure (known, Map.fromList named, printed)
  case parsed of
    Left problem -> do
      TextIO.hPutStrLn IO.stderr (Text.pack (candidatesPath <> ": ") <> problem)
      Exit.exitFailure
    Right (known, records, printed) -> do
      listed <- traverse (\name -> maybe (pure [name]) (fmap (filter (not . Text.null) . Text.lines) . readUtf8 . Text.unpack) (Text.stripPrefix (Text.pack "@") name)) requested
      let wanted = Set.fromList (concat listed <> printed)
      contents <- readUtf8 mtgishPath
      let asts = Map.fromListWith (<>) [(name, [line]) | line <- Text.lines contents, Just name <- [lineName line], Set.member name wanted]
      root <- Registry.defaultRoot
      pool <- fmap (Maybe.mapMaybe (either (const Nothing) Just . snd)) (Registry.loadRoot root)
      outcomes <- mapM (translateOne root out known records asts) (Set.toList wanted)
      -- A node kind is its own reason; anything else, the words before its colon.
      let grouped reason = if Text.isPrefixOf (Text.pack "_") reason then reason else Text.takeWhile (/= ':') reason
          reasons = Map.fromListWith (+) [(grouped reason, 1 :: Int) | Left reason <- outcomes]
      putStrLn $ "translated: " <> show (length [() | Right _ <- outcomes])
      mapM_ (\(kind, n) -> putStrLn ("  " <> kind <> ": " <> show n)) (Map.toList (Map.fromListWith (+) [(kind, 1 :: Int) | Right (kind, _) <- outcomes]))
      mapM_ (TextIO.putStrLn . sharing pool) [card | Right (_, card) <- outcomes]
      putStrLn $ "rejected: " <> show (sum reasons)
      mapM_ (\(kind, n) -> TextIO.putStrLn (Text.pack "  " <> kind <> Text.pack (": " <> show n))) (List.sortOn (negate . snd) (Map.toList reasons))
  where
    inSet code value = do
      fields <- Common.asObject value
      name <- Common.field "name" fields >>= Common.asText
      sets <- maybe (Right []) (Common.asArray Monad.>=> traverse Common.asText) (Common.optionalField "printings" fields)
      pure [name | elem code sets]

-- A file's text, or an exit naming it when it is not UTF-8.
readUtf8 :: FilePath -> IO Text.Text
readUtf8 path = do
  bytes <- ByteString.readFile path
  case Encoding.decodeUtf8' bytes of
    Right text -> pure text
    Left err -> do
      IO.hPutStrLn IO.stderr $ path <> ": not valid UTF-8: " <> show err
      Exit.exitFailure

-- The card name an mtgish AST line is for, read without parsing the line.
lineName :: Text.Text -> Maybe Text.Text
lineName line = do
  rest <- Text.stripPrefix (Text.pack "{\"_OracleCard\":\"Card\",\"Name\":") line
  let (quoted, _) = Text.breakOn (Text.pack ",\"Typeline\"") rest
  either (const Nothing) Just (Common.parse quoted >>= Common.asText)

-- One line per ability of a translated card: whether another pool card has an
-- ability its wording matches, modulo 'Normalise.normalise', and which. Cards
-- sharing an ability's wording share its scenarios (CLAUDE.md), so an ability
-- marked new is one that owes a scenario of its own.
sharing :: [Card.Type.Card] -> Card.Type.Card -> Text.Text
sharing pool card =
  let name = nameOf card
      line (key, wording) = case Set.toList (Set.delete name (Map.findWithDefault Set.empty key byWording)) of
        [] -> Text.pack "  new: " <> wording
        others -> Text.pack "  shared with " <> Text.intercalate (Text.pack ", ") (take 3 others) <> Text.pack ": " <> wording
      byWording = Map.fromListWith Set.union [(key, Set.singleton (nameOf other)) | other <- pool, (key, _) <- wordings other]
   in Text.unlines (name : fmap line (wordings card))
  where
    joined = CardName.join . fmap Face.name . Card.Type.faces
    nameOf = CardName.unwrap . joined
    wordings c = [(Normalise.normalise (joined c) wording, wording) | wording : _ <- Oracle.abilities c]

-- What became of one card: Right with what was done and the card, or Left
-- with why not.
translateOne :: FilePath -> Maybe FilePath -> (Map.Map (Text.Text, Text.Text) Text.Text, Map.Map Text.Text Text.Text) -> Map.Map Text.Text (Either Text.Text (Face.Face Card.Type.Card, Maybe Text.Text, Maybe Text.Text)) -> Map.Map Text.Text [Text.Text] -> Text.Text -> IO (Either Text.Text (String, Card.Type.Card))
translateOne root out known records asts name = do
  let result = case (Map.findWithDefault [] name asts, Map.lookup name records) of
        ([line], Just record) -> Common.parse line >>= Mtgish.card >>= \card -> record >>= Mtgish.accepted . Ingest.stamp known . flip Ingest.reprint card
        ([_], Nothing) -> Left (Text.pack "not in CANDIDATES")
        ([], _) -> Left (Text.pack "not in mtgish")
        _ -> Left (Text.pack "several mtgish cards")
  case result of
    Left reason -> do
      TextIO.hPutStrLn IO.stderr (name <> Text.pack ": " <> reason)
      pure (Left reason)
    Right card -> fmap (fmap (\done -> (done, card))) $ case out of
      Just dir -> Right "written" <$ writeCard (Registry.cardPath dir (Registry.filedAs card)) card
      Nothing -> do
        let file = Registry.cardPath root (Registry.filedAs card)
        exists <- Directory.doesFileExist file
        if exists
          then do
            existing <- fmap Registry.parseCard (ByteString.readFile file)
            if existing == Right card
              then pure (Right "already in the pool, agreeing")
              else Right "already in the pool, differing" <$ IO.hPutStrLn IO.stderr (file <> ": differs from its translation; the pool's file is kept")
          else Right "written" <$ writeCard file card

-- Right True for a card written, Right False for one the pool already holds.
ingestOne :: FilePath -> Value.Value -> IO (Either Text.Text Bool)
ingestOne root record = case Ingest.candidate record of
  Left reason -> pure (Left reason)
  Right card -> do
    let file = Registry.cardPath root (Registry.filedAs card)
    exists <- Directory.doesFileExist file
    if exists
      then do
        existing <- fmap Registry.parseCard (ByteString.readFile file)
        Monad.unless (fmap (Ingest.stamp (Map.empty, texts card)) existing == Right card) $
          IO.hPutStrLn IO.stderr (file <> ": disagrees with MTGJSON; the pool's file is kept")
      else writeCard file card
    pure (Right (not exists))
  where
    texts card = Map.fromList [(CardName.unwrap (Face.name face), text) | face <- NonEmpty.toList (Card.Type.faces card), Just text <- [Face.oracleText face]]

-- True when the card's file changed.
stampOne :: (Map.Map (Text.Text, Text.Text) Text.Text, Map.Map Text.Text Text.Text) -> (FilePath, Card.Type.Card) -> IO Bool
stampOne known (file, card) =
  let stamped = Ingest.stamp known card
   in if stamped == card then pure False else True <$ writeCard file stamped

-- True when the sheet's file changed: CR 123.2's sheet given MTGJSON's text,
-- stampOne's posture for a sheet. A sheet has one face, its own name.
stampSheet :: (Map.Map (Text.Text, Text.Text) Text.Text, Map.Map Text.Text Text.Text) -> (FilePath, StickerSheet.Type.StickerSheet) -> IO Bool
stampSheet (exact, _) (file, sheet) =
  let name = StickerSheet.Type.name sheet
      stamped = sheet {StickerSheet.Type.oracleText = Map.lookup (name, name) exact}
   in if stamped == sheet || Maybe.isNothing (StickerSheet.Type.oracleText stamped)
        then pure False
        else True <$ ByteString.writeFile file (Encoding.encodeUtf8 (Common.render (Codec.encode StickerSheet.codec stamped)))

writeCard :: FilePath -> Card.Type.Card -> IO ()
writeCard file = ByteString.writeFile file . Encoding.encodeUtf8 . Common.render . Codec.encode Card.codec

-- | Emits the card format's JSON Schema, which is otherwise reachable only
-- from a REPL. Card rather than Printing because Pawl.Registry.parseCard is what reads
-- a committed file and it decodes a Card; the two write the same wire.
--
-- Emitted on demand rather than committed as a file: a committed copy would
-- need a test regenerating and comparing it, which is a second mechanism to
-- keep honest, and Pawl.CardsSpec already validates the corpus against this
-- exact value.
schema :: IO ()
schema =
  Builder.hPutBuilder IO.stdout $
    Value.encode (Define.run (Codec.schema Card.codec)) <> Builder.charUtf8 '\n'

-- | The scenario format's JSON Schema, for an editor or a contributor writing
-- one by hand. Emitted on demand for 'schema''s reason.
scenarioSchema :: IO ()
scenarioSchema =
  Builder.hPutBuilder IO.stdout $
    Value.encode (Define.run (Codec.schema Codec.Scenario.codec)) <> Builder.charUtf8 '\n'

-- | Runs each scenario file against the bundled cards and says how it went,
-- one line each: the first way to drive the engine that is not the test suite.
-- Exits 1 if any did not decode or did not run clean.
scenario :: [FilePath] -> IO ()
scenario paths = do
  root <- Registry.defaultRoot
  registry <- Registry.fileRegistry root
  outcomes <- mapM (runOne registry) paths
  Monad.unless (and outcomes) Exit.exitFailure

runOne :: Registry.Registry IO -> FilePath -> IO Bool
runOne registry path = do
  let report message ok = do
        TextIO.hPutStrLn (if ok then IO.stdout else IO.stderr) (Text.pack (path <> ": ") <> message)
        pure ok
  (_, decoded) <- Load.loadFile path
  case decoded of
    Left problem -> report (Text.pack "does not decode: " <> problem) False
    Right parsed -> do
      result <- Scenario.run registry parsed
      case result of
        Left failure -> report (Scenario.render failure) False
        Right _ -> report (Text.pack "ok") True
