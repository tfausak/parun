-- Costs as Oracle text prints them: mana symbols (CR 107.4), mana costs (CR
-- 202.1) and the costs of activated abilities and keywords (CR 118, CR 602.1).
module Parun.Oracle.Cost where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.Text as Text
import qualified Parun.Oracle.Filter as Filter
import qualified Parun.Oracle.Prose as Prose
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.HybridPhyrexian as HybridPhyrexian
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.Sacrifice as Sacrifice

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

-- | A mana cost's symbols in order; the cost of no symbols is {0} (CR 202.1).
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
  pure (Text.intercalate (Text.pack ", ") (mana <> components))

-- | One non-mana component of a cost: "{T}", "Sacrifice a Mountain",
-- "Discard two cards" (CR 701.21a, CR 701.9a).
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
  CostComponent.DiscardCards (DiscardCards.MkDiscardCards ObjectCount.Every (Filter.Type.And [])) -> [Text.pack "Discard your hand"]
  CostComponent.DiscardCards (DiscardCards.MkDiscardCards (ObjectCount.Exactly (CostAmount.Fixed n)) f) -> do
    p <- Filter.phrase f named
    let card = Filter.MkNoun (Text.pack "card") (Just (Text.pack "cards"))
    fmap (Text.pack "Discard " <>) (some (toInteger n) card (Filter.merge p (Filter.MkPhrase [] [card] [])))
      <> [ Text.pack "Discard " <> Prose.article one <> Text.pack " " <> one <> Text.pack " or " <> other
         | n == 1,
           Filter.Type.Or [left, right] <- [f],
           one <- singular named card left,
           other <- singular named card right
         ]
  CostComponent.Blight (CostAmount.Fixed n) -> [Text.pack ("Blight " <> show n)]
  _ -> []

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
    [(verb <> rest, verb <> Text.pack "s" <> rest)]
  _ -> []

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
