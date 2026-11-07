-- Covers Parun.Ingest, and Parun.Oracle against the pool and the keyword codec:
-- every card file Parun.Oracle renders against its Oracle text (#9, #5477).
-- Parun.OracleSpec covers Parun.Oracle on hand-built cards.
module Parun.IngestSpec where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Proxy as Proxy
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Ingest as Ingest
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonSchema.Define as Define
import qualified Parun.JsonSchema.Name as Name
import qualified Parun.JsonSchema.Schema as Schema
import qualified Parun.Oracle as Oracle
import qualified Parun.Oracle.Keyword as Keyword
import qualified Parun.Oracle.Normalise as Normalise
import qualified Parun.Registry as Registry
import qualified Parun.Slug as Slug
import qualified Parun.Spec as Spec
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Devour as Devour
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.Power as Power
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.TypeLine as TypeLine

spec :: (Monad n) => Spec.Spec IO n -> [(FilePath, Either Text.Text Card.Card)] -> n ()
spec s corpus = Spec.describe s "Parun.Ingest" $ do
  -- The invariant the renderer exists for: each face of a card it renders
  -- says what the face's Oracle text says, in one of the wordings Oracle uses
  -- for it.
  Spec.it s "each card that renders says what its Oracle text says" $ do
    let rendered = [card | entry@(_, Right card) <- corpus, Maybe.isJust (Registry.referenceCard entry), Maybe.isJust (Oracle.render card)]
        disagreements =
          [ (Text.unpack (Slug.unwrap (Registry.filedAs card)), fmap (Normalise.normalise name) text, fmap (Normalise.normalise name) (Oracle.renderFace face))
          | card <- rendered,
            face <- NonEmpty.toList (Card.faces card),
            let name = Face.name face
                text = Face.oracleText face,
            maybe True (not . Oracle.says card name) text
          ]
    Spec.assertBool s (not (null rendered)) "no card renders"
    Spec.assertEq s [] disagreements

  -- The check above passes over a card that does not render, so the cards
  -- that do not are listed, one slug a line in byte order, so that parallel
  -- branches adding slugs touch different lines: a card that stops rendering
  -- fails here, and one that starts is struck off the list. Not implemented:
  -- checking the abilities that do render on a listed card (#5488).
  Spec.it s "the cards that do not render are exactly those listed" $ do
    root <- Registry.defaultRoot
    slugs <- fmap (filter (not . null) . lines) (readFile (root <> "/../oracle-unrendered.txt"))
    let listed = Set.fromList slugs
    Spec.assertEqWith s "listed out of byte order (script/sort-lines.sh fix)" [] [(a, b) | (a, b) <- zip slugs (drop 1 slugs), a >= b]
    let unrendered = Set.fromList [Text.unpack (Slug.unwrap (Registry.filedAs card)) | entry@(_, Right card) <- corpus, Maybe.isJust (Registry.referenceCard entry), Maybe.isNothing (Oracle.render card)]
    Spec.assertEqWith s "listed, but renders or is no pool card" [] (Set.toList (Set.difference listed unrendered))
    Spec.assertEqWith s "does not render, but unlisted" [] (Set.toList (Set.difference unrendered listed))

  -- `parun ingest` stamps the text on every card MTGJSON has; a dungeon (CR
  -- 309) is not among them, since MTGJSON files dungeons with the tokens.
  Spec.it s "every face of the reference carries its Oracle text" $ do
    let missing =
          [ Text.unpack (CardName.unwrap (Face.name face))
          | entry@(_, Right card) <- corpus,
            Maybe.isJust (Registry.referenceCard entry),
            face <- NonEmpty.toList (Card.faces card),
            Maybe.isNothing (Face.oracleText face),
            CardType.Dungeon `Set.notMember` TypeLine.types (Face.typeLine face)
          ]
    Spec.assertEq s [] missing

  Spec.it s "render answers for a pool card it renders and not for a split card" $ do
    registry <- Registry.defaultRoot >>= Registry.fileRegistry
    elves <- Registry.named registry "Llanowar Elves"
    Spec.assertEq s (Right (Just (Just (Text.pack "{T}: Add {G}.")))) (fmap (fmap Oracle.render) elves)
    angel <- Registry.named registry "Serra Angel"
    Spec.assertEq s (Right (Just (Just (Text.pack "Flying\nVigilance")))) (fmap (fmap Oracle.render) angel)
    wax <- Registry.named registry "Wax"
    Spec.assertEq s (Right (Just Nothing)) (fmap (fmap Oracle.render) wax)

  Spec.it s "each standalone keyword prints as its codec tag spells it" $
    Monad.forM_
      Keyword.standalone
      ( \k -> case Keyword.printed (Text.pack "X") k of
          [p] -> Spec.assertEqWith s (show k) (Codec.encode Codec.Keyword.codec k) (Common.nullary (tagOf p))
          _ -> Spec.assertFailure s (show k <> ": not one printed form")
      )

  -- The witness that 'Keyword.standalone' is complete: every arm the keyword
  -- codec accepts with no value is listed, or is one of the three whose bare
  -- form prints a parameter or is never printed at all.
  Spec.it s "standalone lists every keyword the codec writes as a bare tag" $ do
    let unprinted = [Keyword.Type.Bloodthirst Nothing, Keyword.Type.Modular Nothing, Keyword.Type.Suspend Nothing]
    case bareTags (Define.run (Codec.schema Codec.Keyword.codec)) of
      Left reason -> Spec.assertFailure s (Text.unpack reason)
      Right tags -> do
        Spec.assertEq s (length tags) (length Keyword.standalone + length unprinted)
        Monad.forM_ tags $ \tag -> case Codec.decode Codec.Keyword.codec (Common.nullary tag) of
          Left reason -> Spec.assertFailure s (tag <> ": " <> Text.unpack reason)
          Right k -> Spec.assertBool s (k `elem` Keyword.standalone || k `elem` unprinted) (tag <> ": not in Parun.Oracle.Keyword.standalone")

  -- The witness that the payload tables are complete over the pool: every
  -- keyword a pool card carries that prints as one line of a name and a
  -- number, a mana cost (CR 107.4) or both reads back as itself, except where
  -- the name carries a filter (devour and splice) or the payload means more
  -- than it prints (backup, CR 702.165a).
  Spec.it s "keyword reads back each pool keyword printed with a number or a mana cost" $ do
    let excluded k = case k of
          Keyword.Type.Backup _ -> True
          Keyword.Type.Devour d -> Maybe.isJust (Devour.quality d)
          Keyword.Type.Splice _ -> True
          _ -> False
        keywords = Set.fromList [k | (_, Right card) <- corpus, face <- NonEmpty.toList (Card.faces card), k <- Map.keys (Face.keywords face), not (excluded k)]
        lines' = [(k, Text.toLower p) | k <- Set.toList keywords, [p] <- [Keyword.printed Text.empty k], payloaded (Text.toLower p)]
        payloaded line = case Text.breakOnEnd (Text.pack " ") line of
          (name, payload) -> Text.all (\c -> Char.isLetter c || c `elem` " -") name && not (Text.null payload) && Text.all (\c -> Char.isAlphaNum c || c `elem` "{}/\8212") payload && Text.any (\c -> Char.isDigit c || c == '{') payload
    Spec.assertBool s (length lines' > 50) "too few payload keywords in the pool"
    Spec.assertEq s [] [(show k, line) | (k, line) <- lines', Ingest.keyword line /= Right k]

  -- Each record as script/ingest/candidates.jq writes it, against a card
  -- written by hand and checked against Scryfall, so the two are independent.
  -- Rograkh is red only by its color indicator (CR 204), and it and
  -- Ornithopter cost {0}, which the pool writes as a cost of no symbols.
  -- Mountain Goat's mountainwalk is a landwalk over a basic land type (CR
  -- 702.14a). The rest carry a keyword's payload: a number, a mana cost, or
  -- both (CR 702.62a), Ainok Tracker's beside a bare keyword.
  Spec.it s "candidate builds the card the pool holds" $ do
    registry <- Registry.defaultRoot >>= Registry.fileRegistry
    Monad.forM_
      [ ("Mountain Goat", "{\"name\":\"Mountain Goat\",\"manaCost\":\"{R}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Goat\"],\"power\":\"1\",\"toughness\":\"1\",\"text\":\"Mountainwalk (This creature can't be blocked as long as defending player controls a Mountain.)\"}"),
        ("Ornithopter", "{\"name\":\"Ornithopter\",\"manaCost\":\"{0}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Artifact\",\"Creature\"],\"subtypes\":[\"Thopter\"],\"power\":\"0\",\"toughness\":\"2\",\"text\":\"Flying\"}"),
        ("Rograkh, Son of Rohgahh", "{\"name\":\"Rograkh, Son of Rohgahh\",\"manaCost\":\"{0}\",\"colorIndicator\":[\"R\"],\"supertypes\":[\"Legendary\"],\"types\":[\"Creature\"],\"subtypes\":[\"Kobold\",\"Warrior\"],\"power\":\"0\",\"toughness\":\"1\",\"text\":\"First strike, menace, trample\\nPartner (You can have two commanders if both have partner.)\"}"),
        ("Consulate Dreadnought", "{\"name\":\"Consulate Dreadnought\",\"manaCost\":\"{1}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Artifact\"],\"subtypes\":[\"Vehicle\"],\"power\":\"7\",\"toughness\":\"11\",\"text\":\"Crew 6 (Tap any number of creatures you control with total power 6 or more: This Vehicle becomes an artifact creature until end of turn.)\"}"),
        ("Barkhide Mauler", "{\"name\":\"Barkhide Mauler\",\"manaCost\":\"{4}{G}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Beast\"],\"power\":\"4\",\"toughness\":\"4\",\"text\":\"Cycling {2} ({2}, Discard this card: Draw a card.)\"}"),
        ("Ainok Tracker", "{\"name\":\"Ainok Tracker\",\"manaCost\":\"{5}{R}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Dog\",\"Scout\"],\"power\":\"3\",\"toughness\":\"3\",\"text\":\"First strike\\nMorph {4}{R} (You may cast this card face down as a 2/2 creature for {3}. Turn it face up any time for its morph cost.)\"}"),
        ("Durkwood Baloth", "{\"name\":\"Durkwood Baloth\",\"manaCost\":\"{4}{G}{G}\",\"colorIndicator\":null,\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Beast\"],\"power\":\"5\",\"toughness\":\"5\",\"text\":\"Suspend 5\8212{G} (Rather than cast this card from your hand, you may pay {G} and exile it with five time counters on it. At the beginning of your upkeep, remove a time counter. When the last is removed, you may cast it without paying its mana cost. It has haste.)\"}")
      ]
      $ \(name, json) -> do
        card <- Registry.named registry name
        case (Common.parse (Text.pack json), card) of
          (Right value, Right (Just expected)) -> Spec.assertEqWith s name (Right expected) (Ingest.candidate value)
          _ -> Spec.assertFailure s (name <> ": no record or no card")

  -- Replenish is reprinted as the spell face of Eiganjo Dynastorian, whose
  -- entry drops the reminder text; the card's own entry wins.
  Spec.it s "stamp prefers the entry naming the card itself" $ do
    registry <- Registry.defaultRoot >>= Registry.fileRegistry
    replenish <- Registry.named registry "Replenish"
    let own = "Return all enchantment cards from your graveyard to the battlefield. (Auras with nothing to enchant remain in your graveyard.)"
        json = "[{\"card\":\"Eiganjo Dynastorian // Replenish\",\"name\":\"Replenish\",\"text\":\"Return all enchantment cards from your graveyard to the battlefield.\"},{\"card\":\"Replenish\",\"name\":\"Replenish\",\"text\":\"" <> own <> "\"}]"
        unstamped c = c {Card.faces = fmap (\f -> f {Face.oracleText = Nothing}) (Card.faces c)}
    case (Common.parse (Text.pack json) >>= Ingest.texts, replenish) of
      (Right known, Right (Just card)) -> Spec.assertEq s (Just (Text.pack own)) (Face.oracleText (NonEmpty.head (Card.faces (Ingest.stamp known (unstamped card)))))
      _ -> Spec.assertFailure s "Replenish: no texts or no card"

  -- mtgish's AST for Dragon Engine predates its Dragon subtype; Maro's star
  -- is the translation's to keep.
  Spec.it s "reprint takes the printed characteristics from the record" $ do
    registry <- Registry.defaultRoot >>= Registry.fileRegistry
    Monad.forM_
      [ ("Dragon Engine", "{\"name\":\"Dragon Engine\",\"manaCost\":\"{3}\",\"supertypes\":[],\"types\":[\"Artifact\",\"Creature\"],\"subtypes\":[\"Dragon\",\"Construct\"],\"power\":\"1\",\"toughness\":\"3\",\"text\":null}"),
        ("Maro", "{\"name\":\"Maro\",\"manaCost\":\"{2}{G}{G}\",\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Elemental\"],\"power\":\"*\",\"toughness\":\"*\",\"text\":null}")
      ]
      $ \(name, json) -> do
        card <- Registry.named registry name
        -- A star stays as the translation has it, so only a number is staled.
        let staleNumber p = if p == Just (Power.MkPower Quantity.Star) then p else Just (Power.MkPower (Quantity.Literal 9))
            stale c = c {Card.faces = fmap (\f -> f {Face.manaCost = Nothing, Face.typeLine = (Face.typeLine f) {TypeLine.subtypes = Set.empty}, Face.power = staleNumber (Face.power f)}) (Card.faces c)}
        case (Common.parse (Text.pack json) >>= Ingest.printed, card) of
          (Right record, Right (Just expected)) -> Spec.assertEqWith s name expected (Ingest.reprint [record] (stale expected))
          _ -> Spec.assertFailure s (name <> ": no record or no card")

  -- CR 723: a preparation card's record holds a record for each face, which
  -- reprint matches to the card's faces by name.
  Spec.it s "reprint takes each face's printed characteristics from its own record" $ do
    registry <- Registry.defaultRoot >>= Registry.fileRegistry
    card <- Registry.named registry "Encouraging Aviator"
    let json = "{\"name\":\"Encouraging Aviator // Jump\",\"faces\":[{\"name\":\"Encouraging Aviator\",\"manaCost\":\"{2}{U}\",\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Bird\",\"Wizard\"],\"power\":\"2\",\"toughness\":\"3\",\"text\":null},{\"name\":\"Jump\",\"manaCost\":\"{U}\",\"supertypes\":[],\"types\":[\"Instant\"],\"subtypes\":[],\"power\":null,\"toughness\":null,\"text\":null}]}"
        stale c = c {Card.faces = fmap (\f -> f {Face.manaCost = Nothing, Face.typeLine = TypeLine.MkTypeLine Set.empty Set.empty Set.empty}) (Card.faces c)}
    case (Common.parse (Text.pack json) >>= Ingest.printedFaces, card) of
      (Right records, Right (Just expected)) -> Spec.assertEq s expected (Ingest.reprint records (stale expected))
      _ -> Spec.assertFailure s "Encouraging Aviator // Jump: no record or no card"

  Spec.it s "candidate leaves out a card it would have to guess at" $ do
    let reason json = Common.parse (Text.pack json) >>= Monad.void . Ingest.candidate
    Spec.assertEq s (Left (Text.pack "text: ward\8212pay 3 life")) (reason "{\"name\":\"X\",\"manaCost\":\"{1}\",\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[],\"power\":\"1\",\"toughness\":\"1\",\"text\":\"Ward\8212Pay 3 life\"}")
    Spec.assertEq s (Left (Text.pack "text: equip planeswalker {1}")) (reason "{\"name\":\"X\",\"manaCost\":\"{1}\",\"supertypes\":[],\"types\":[\"Artifact\"],\"subtypes\":[\"Equipment\"],\"text\":\"Equip planeswalker {1}\"}")
    Spec.assertEq s (Left (Text.pack "power/toughness: *")) (reason "{\"name\":\"X\",\"manaCost\":\"{1}\",\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[],\"power\":\"*\",\"toughness\":\"1\",\"text\":null}")
    Spec.assertEq s (Left (Text.pack "faces: more than one")) (reason "{\"name\":\"X // Y\",\"faces\":[]}")
    Spec.assertEq s (Left (Text.pack "subtype: Nonesuch")) (reason "{\"name\":\"X\",\"manaCost\":\"{1}\",\"supertypes\":[],\"types\":[\"Creature\"],\"subtypes\":[\"Nonesuch\"],\"power\":\"1\",\"toughness\":\"1\",\"text\":null}")

-- A printed keyword as its constructor's name: each word capitalised, then
-- everything but letters dropped ("Jump-start" is JumpStart).
tagOf :: Text.Text -> String
tagOf = concatMap (filter Char.isAlpha . capitalise . Text.unpack) . Text.split (`elem` " -")
  where
    capitalise w = case w of
      c : rest -> Char.toUpper c : rest
      [] -> []

-- Every tag of the Keyword union whose arm requires nothing but the tag.
bareTags :: Define.Document -> Either Text.Text [String]
bareTags document = case Map.lookup (Name.typeName (Proxy.Proxy :: Proxy.Proxy Keyword.Type.Keyword)) (Define.definitions document) of
  Just (Schema.OneOf arms) -> fmap Maybe.catMaybes . Monad.forM arms $ \arm -> case arm of
    Schema.Object properties required -> case Common.lookupPair "type" properties of
      Just (Schema.Constant tag) -> Right (if required == [Text.pack "type"] then Just (Text.unpack tag) else Nothing)
      _ -> Left (Text.pack "expected an arm's type to be a constant")
    _ -> Left (Text.pack "expected an arm to be an object")
  _ -> Left (Text.pack "expected the Keyword definition to be a oneOf")
