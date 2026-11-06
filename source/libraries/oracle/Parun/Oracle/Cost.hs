-- Costs as Oracle text prints them: mana symbols (CR 107.4), mana costs (CR
-- 202.1) and the costs of activated abilities and keywords (CR 118, CR 602.1).
module Parun.Oracle.Cost where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Parun.Oracle.Filter as Filter
import qualified Parun.Oracle.Prose as Prose
import qualified Parun.Types.CardSelection as CardSelection
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterName as CounterName
import qualified Parun.Types.CounterSpread as CounterSpread
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.CountersOnThis as CountersOnThis
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.ExileCardsFromGraveyard as ExileCardsFromGraveyard
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.HybridPhyrexian as HybridPhyrexian
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.TapPermanents as TapPermanents
import qualified Parun.Types.WhichCounters as WhichCounters

-- | A mana symbol in braces (CR 107.4).
symbol :: ManaSymbol.ManaSymbol -> Text.Text
symbol s = braced $ case s of
  ManaSymbol.Generic n -> Text.pack (show n)
  ManaSymbol.OfType t -> manaType t
  ManaSymbol.Hybrid h -> manaType (Hybrid.left h) <> Text.pack "/" <> manaType (Hybrid.right h)
  ManaSymbol.MonocoloredHybrid t -> Text.pack "2/" <> manaType t
  ManaSymbol.Phyrexian c -> color c <> Text.pack "/P"
  ManaSymbol.HybridPhyrexian h -> color (HybridPhyrexian.left h) <> Text.pack "/" <> color (HybridPhyrexian.right h) <> Text.pack "/P"
  ManaSymbol.Snow -> Text.pack "S"
  ManaSymbol.Variable -> Text.pack "X"

-- | A mana cost's symbols in order (CR 202.1); the pool writes {0} (CR 118.5) as
-- a cost of no symbols.
manaCost :: ManaCost.ManaCost -> Text.Text
manaCost m = case ManaCost.unwrap m of
  [] -> braced (Text.pack "0")
  symbols -> foldMap symbol symbols

-- | The letter a mana type's symbol carries (CR 107.4c).
manaType :: ManaType.ManaType -> Text.Text
manaType t = case t of
  ManaType.Colored c -> color c
  ManaType.Colorless -> Text.pack "C"

-- | The letter a colour's mana symbol carries (CR 107.4a).
color :: Color.Color -> Text.Text
color c = Text.pack $ case c of
  Color.White -> "W"
  Color.Blue -> "U"
  Color.Black -> "B"
  Color.Red -> "R"
  Color.Green -> "G"

-- | A cost as an activated ability or a keyword prints it: the mana first,
-- then each other component, separated by commas (CR 602.1a). The first
-- argument is what the card calls itself, the second how to print a keyword a
-- filter names. An unpayable cost (CR 118.6) prints nothing, so answers
-- nothing.
cost :: Text.Text -> (k -> [Text.Text]) -> Cost.Cost k -> [Text.Text]
cost self named c = do
  mana <- case Cost.mana c of
    Nothing -> []
    Just m
      | null (ManaCost.unwrap m) && not (null (Cost.components c)) -> [[]]
      | otherwise -> [[manaCost m]]
  components <- traverse (component self named) (Cost.components c)
  -- Free: sacrificing the source after another component naming it joins
  -- that one, "Remove two pressure counters from this land and sacrifice it"
  -- (Hellion Crucible).
  joined <-
    components
      : [ front <> [previous <> Text.pack " and sacrifice it"]
        | CostComponent.SacrificeThis : before : _ <- [reverse (Cost.components c)],
          namesSelf before,
          (front, [previous, _]) <- [splitAt (length components - 2) components]
        ]
  pure (Text.intercalate (Text.pack ", ") (mana <> joined))

-- | Whether a cost component names the object the cost is on, so that the
-- effect after it may call that object "it" (Mogg Mob, Triskelion).
namesSelf :: CostComponent.CostComponent k -> Bool
namesSelf c = case c of
  CostComponent.SacrificeThis -> True
  CostComponent.ReturnThis -> True
  CostComponent.ExileThis -> True
  CostComponent.ExileThisFromGraveyard -> True
  CostComponent.RemoveCountersFromThis _ -> True
  CostComponent.RemoveCounters r -> case CountersFromPermanents.whichPermanent r of
    Filter.Type.IsSource -> True
    _ -> False
  _ -> False

-- | One non-mana component of a cost: "{T}", "Sacrifice a Mountain",
-- "Discard two cards", "Remove a +1/+1 counter from this creature", "Tap an
-- untapped creature you control", "Pay {E}{E}" (CR 701.21a, CR 701.9a, CR
-- 118.1, CR 107.14).
component :: Text.Text -> (k -> [Text.Text]) -> CostComponent.CostComponent k -> [Text.Text]
component self named c = case c of
  CostComponent.TapThis -> [braced (Text.pack "T")]
  CostComponent.UntapThis -> [braced (Text.pack "Q")]
  CostComponent.SacrificeThis -> [Text.pack "Sacrifice " <> self]
  CostComponent.PayLife (CostAmount.Fixed n) -> [Text.pack ("Pay " <> show n <> " life")]
  CostComponent.PayLife (CostAmount.Announced _) -> [Text.pack "Pay X life"]
  CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed n)) f) -> do
    p <- Filter.phrase f named
    fmap (Text.pack "Sacrifice " <>) (some (toInteger n) (Filter.MkNoun (Text.pack "permanent") (Just (Text.pack "permanents"))) p)
  CostComponent.DiscardCards (DiscardCards.MkDiscardCards ObjectCount.Every (Filter.Type.And []) _) -> [Text.pack "Discard your hand"]
  CostComponent.DiscardCards (DiscardCards.MkDiscardCards (ObjectCount.Exactly (CostAmount.Fixed n)) f CardSelection.AtRandom) -> do
    p <- Filter.phrase f named
    fmap (\phrase -> Text.pack "Discard " <> phrase <> Text.pack " at random") (some (toInteger n) card (Filter.merge p (Filter.MkPhrase [] [card] [])))
  CostComponent.DiscardCards (DiscardCards.MkDiscardCards (ObjectCount.Exactly (CostAmount.Fixed n)) f CardSelection.ByChoice) -> do
    p <- Filter.phrase f named
    fmap (Text.pack "Discard " <>) (some (toInteger n) card (Filter.merge p (Filter.MkPhrase [] [card] [])))
      <> [ Text.pack "Discard " <> Prose.article one <> Text.pack " " <> one <> Text.pack " or " <> other
         | n == 1,
           Filter.Type.Or [left, right] <- [f],
           one <- singular named card left,
           other <- singular named card right
         ]
  CostComponent.Blight (CostAmount.Fixed n) -> [Text.pack ("Blight " <> show n)]
  CostComponent.ReturnThis -> [Text.pack "Return " <> self <> Text.pack " to its owner's hand"]
  CostComponent.ExileThis -> [Text.pack "Exile " <> self]
  CostComponent.ExileThisFromGraveyard -> [Text.pack "Exile " <> self <> Text.pack " from your graveyard"]
  CostComponent.PayEnergy (CostAmount.Fixed n) | n > 0 -> [Text.pack "Pay " <> foldMap (const energy) [1 .. n]]
  CostComponent.PayEnergy (CostAmount.Announced _) -> [Text.pack "Pay X " <> energy]
  CostComponent.TapPermanents (TapPermanents.MkTapPermanents (CostAmount.Fixed n) f sharing) | not sharing || n > 1 -> do
    -- Free: "two artifacts and/or creatures" (Adaptive Gemguard).
    p <- ListUtils.nubOrd (Filter.phrase f named <> Filter.phraseJoining Filter.Inclusive f named)
    tapped <- some (toInteger n) permanent p
    [Text.pack "Tap " <> tapped <> (if sharing then Text.pack " that share a creature type" else Text.empty)]
  CostComponent.ExileCardsFromGraveyard (ExileCardsFromGraveyard.MkExileCardsFromGraveyard n f) -> do
    p <- Filter.phrase f named
    exiled <- some (toInteger n) card (Filter.merge p (Filter.MkPhrase [] [card] []))
    [Text.pack "Exile " <> exiled <> Text.pack " from your graveyard"]
  CostComponent.RemoveCountersFromThis (CountersOnThis.MkCountersOnThis kind n) -> do
    word <- counterWord named kind
    removed <- counted (word <> Text.pack " ") (toInteger n)
    [Text.pack "Remove " <> removed <> Text.pack " from " <> self]
  CostComponent.RemoveCounters (CountersFromPermanents.MkCountersFromPermanents amount which f spread) -> do
    word <- case which of
      WhichCounters.OfKind kind -> fmap (<> Text.pack " ") (counterWord named kind)
      WhichCounters.OfAnyKind -> [Text.empty]
    removed <- case (spread, amount) of
      (CounterSpread.FromAmongAtLeast, CostAmount.Fixed 0) -> [Text.pack "any number of " <> word <> Text.pack "counters"]
      (CounterSpread.FromAmongAtLeast, CostAmount.Fixed 1) -> [Text.pack "one or more " <> word <> Text.pack "counters"]
      (CounterSpread.FromAmongAtLeast, _) -> []
      (_, CostAmount.Fixed n) -> counted word (toInteger n)
      (_, CostAmount.Announced _) -> [Text.pack "X " <> word <> Text.pack "counters"]
    from <- case (f, spread) of
      (Filter.Type.IsSource, _) -> [self]
      (_, CounterSpread.FromOne) -> some 1 permanent =<< Filter.phrase f named
      _ -> fmap (Text.pack "among " <>) (Filter.describe Filter.Plural permanent =<< Filter.phrase f named)
    [Text.pack "Remove " <> removed <> Text.pack " from " <> from]
  _ -> []
  where
    card = Filter.MkNoun (Text.pack "card") (Just (Text.pack "cards"))
    permanent = Filter.MkNoun (Text.pack "permanent") (Just (Text.pack "permanents"))
    energy = braced (Text.pack "E")

-- | So many counters, the kind's word given with its trailing space or empty
-- for counters of any kind: "a +1/+1 counter", "three counters" (CR 122.1).
counted :: Text.Text -> Integer -> [Text.Text]
counted word n
  | n == 1 = [Prose.article single <> Text.pack " " <> single]
  | n > 1 = [Prose.cardinal n <> Text.pack " " <> word <> Text.pack "counters"]
  | otherwise = []
  where
    single = word <> Text.pack "counter"

-- | A counter's kind as the word before "counter": "+1/+1", "flying" (CR
-- 122.1).
counterWord :: (k -> [Text.Text]) -> CounterKind.CounterKind k -> [Text.Text]
counterWord named kind = case kind of
  CounterKind.PlusOnePlusOne -> [Text.pack "+1/+1"]
  CounterKind.MinusOneMinusOne -> [Text.pack "-1/-1"]
  CounterKind.Keyword k -> named k
  CounterKind.UnsafePowerToughness p t -> [signed t p <> Text.pack "/" <> signed p t]
  CounterKind.Named n -> [CounterName.unwrap n]
  CounterKind.Loyalty -> [Text.pack "loyalty"]
  CounterKind.Lore -> [Text.pack "lore"]
  CounterKind.Defense -> [Text.pack "defense"]
  CounterKind.Time -> [Text.pack "time"]
  CounterKind.Fade -> [Text.pack "fade"]
  CounterKind.Age -> [Text.pack "age"]
  CounterKind.Shield -> [Text.pack "shield"]
  CounterKind.Finality -> [Text.pack "finality"]
  CounterKind.Stun -> [Text.pack "stun"]
  CounterKind.Level -> [Text.pack "level"]
  CounterKind.Hone -> [Text.pack "hone"]
  where
    -- A +X/+Y counter's half, "-0" where the other half is negative.
    signed other n
      | n > 0 = Text.pack ("+" <> show n)
      | n < 0 = Text.pack (show n)
      | other < 0 = Text.pack "-0"
      | otherwise = Text.pack "+0"

-- | One object of a filter, named as a card: "land card", "Shrine card".
singular :: (k -> [Text.Text]) -> Filter.Noun -> Filter.Type.Filter k -> [Text.Text]
singular named card f = do
  p <- Filter.phrase f named
  Filter.describe Filter.Singular card (Filter.merge p (Filter.MkPhrase [] [card] []))

-- | So many objects a phrase describes: "a Mountain", "another creature",
-- "three Forests".
some :: Integer -> Filter.Noun -> Filter.Phrase -> [Text.Text]
some n fallback p
  | n == 1 = do
      one <- Filter.describe Filter.Singular fallback p
      [maybe (Prose.article one <> Text.pack " " <> one) (Text.pack "another " <>) (Text.stripPrefix (Text.pack "other ") one)]
  | n > 1 = do
      many <- Filter.describe Filter.Plural fallback p
      [Prose.cardinal n <> Text.pack " " <> many]
  | otherwise = []

-- | A cost as the instruction to pay it, in the second person and the third:
-- ("pay {3}", "pays {3}"), ("sacrifice a Mountain", "sacrifices a
-- Mountain") (CR 118.12). A cost of mana and something else, or of two
-- things other than mana, is not spelled out here.
payment :: Text.Text -> (k -> [Text.Text]) -> Cost.Cost k -> [(Text.Text, Text.Text)]
payment self named c = case (Cost.mana c, Cost.components c) of
  (Just m, []) -> [(Text.pack "pay " <> manaCost m, Text.pack "pays " <> manaCost m)]
  (mana, [one]) | maybe True (null . ManaCost.unwrap) mana -> do
    text <- component self named one
    Monad.guard (maybe False (Char.isAlpha . fst) (Text.uncons text))
    let (verb, rest) = Text.breakOn (Text.pack " ") (Prose.decapitalise text)
    -- Free: "sacrifices a creature", or "... of their choice" (Indulgent
    -- Tormentor), the same payment.
    tail' <- rest : [rest <> Text.pack " of their choice" | CostComponent.Sacrifice {} <- [one]]
    [(verb <> tail', verb <> Text.pack "s" <> tail')]
  _ -> []

-- | 'payment' of a cost offering a choice. Of two options, free in whether the
-- second repeats a shared "pay": "pays {1} or 1 life" (Erosion), "sacrifices a
-- creature of their choice or pays 3 life" (Indulgent Tormentor).
paymentChoice :: Text.Text -> (k -> [Text.Text]) -> NonEmpty.NonEmpty (Cost.Cost k) -> [(Text.Text, Text.Text)]
paymentChoice self named options = case options of
  only NonEmpty.:| [] -> payment self named only
  one NonEmpty.:| [other] -> do
    (second, third) <- payment self named one
    (second', third') <- payment self named other
    let either' a b = a <> Text.pack " or " <> b
    case (Text.stripPrefix verb second, Text.stripPrefix verb second') of
      (Just _, Just rest) -> [(either' second rest, either' third rest)]
      _ -> []
      <> [(either' second second', either' third third')]
  _ -> []
  where
    verb = Text.pack "pay "

-- | A cost following a keyword: "Echo {1}{G}" for a cost of mana alone, and
-- otherwise the cost as a sentence after a dash, "Ward--Pay 3 life." (CR
-- 702.21a).
keyworded :: Text.Text -> (k -> [Text.Text]) -> Text.Text -> Cost.Cost k -> [Text.Text]
keyworded self named name c = do
  text <- cost self named c
  pure $ case Cost.components c of
    [] -> name <> Text.pack " " <> text
    _ -> name <> Text.pack "\8212" <> Prose.sentence text

braced :: Text.Text -> Text.Text
braced text = Text.pack "{" <> text <> Text.pack "}"
