-- Costs as Oracle text prints them: mana symbols (CR 107.4), mana costs (CR
-- 202.1) and the costs of activated abilities and keywords (CR 118, CR 602.1).
module Pawl.Oracle.Cost where

import qualified Data.Text as Text
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.CostAmount as CostAmount
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.Hybrid as Hybrid
import qualified Pawl.Types.HybridPhyrexian as HybridPhyrexian
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType

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
-- argument is what the card calls itself. An unpayable cost (CR 118.6) prints
-- nothing, so answers nothing.
cost :: Text.Text -> Cost.Cost k -> [Text.Text]
cost self c = do
  mana <- case Cost.mana c of
    Nothing -> []
    Just m
      | null (ManaCost.unwrap m) && not (null (Cost.components c)) -> [[]]
      | otherwise -> [[manaCost m]]
  components <- traverse (component self) (Cost.components c)
  pure (Text.intercalate (Text.pack ", ") (mana <> components))

-- | One non-mana component of a cost.
component :: Text.Text -> CostComponent.CostComponent k -> [Text.Text]
component self c = case c of
  CostComponent.TapThis -> [braced (Text.pack "T")]
  CostComponent.UntapThis -> [braced (Text.pack "Q")]
  CostComponent.SacrificeThis -> [Text.pack "Sacrifice " <> self]
  CostComponent.PayLife (CostAmount.Fixed n) -> [Text.pack ("Pay " <> show n <> " life")]
  CostComponent.PayLife (CostAmount.Announced _) -> [Text.pack "Pay X life"]
  _ -> []

-- | A cost following a keyword: "Echo {1}{G}" for a cost of mana alone, and
-- otherwise the cost as a sentence after a dash, "Ward--Pay 3 life." (CR
-- 702.21a).
keyworded :: Text.Text -> Text.Text -> Cost.Cost k -> [Text.Text]
keyworded self name c = do
  text <- cost self c
  pure $ case Cost.components c of
    [] -> name <> Text.pack " " <> text
    _ -> name <> Text.pack "\8212" <> Prose.sentence text

braced :: Text.Text -> Text.Text
braced text = Text.pack "{" <> text <> Text.pack "}"
