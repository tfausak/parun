-- What an instruction is about, as Oracle text names it: target slots (CR
-- 115), the objects and players a reference names, and the numbers it reads.
module Pawl.Oracle.Target where

import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot

-- | What a renderer needs from around the instruction: what the card calls
-- itself, the mode's target slots, and how to print a keyword a filter names.
data Context = MkContext
  { self :: Text.Text,
    slots :: Map.Map SlotName.SlotName TargetSlot.TargetSlot,
    keyword :: Keyword.Keyword -> [Text.Text]
  }

-- | Words that name something, with the target slots they announce (each slot
-- is named exactly once in a mode's text, CR 601.2c) and their number, which
-- a later pronoun agrees with.
data Reference = MkReference
  { wording :: Text.Text,
    mentions :: [SlotName.SlotName],
    number :: Filter.Number
  }
  deriving (Eq, Show)

-- | Whether a description of many objects reads "each" or "all": damage is
-- dealt to "each creature" and destruction is of "all creatures".
data Determiner
  = Each
  | All
  deriving (Eq, Show)

-- | The slot the engine binds the object an instruction is on to, which CR
-- 201.5 names "this" or the card's name; the slot names are
-- Pawl.Engine.Binding's, which this library cannot import.
selfSlot :: SlotName.SlotName
selfSlot = SlotName.MkSlotName (Text.pack "self")

-- | The slot the engine binds the instruction's controller to, CR 109.5's
-- "you".
youSlot :: SlotName.SlotName
youSlot = SlotName.MkSlotName (Text.pack "you")

-- | The slot the engine binds a chosen X to (CR 107.3).
xSlot :: SlotName.SlotName
xSlot = SlotName.MkSlotName (Text.pack "X")

-- | A number as digits ("3 damage", "4 life"), or X.
amount :: Quantity.Quantity -> [Text.Text]
amount q = case q of
  Quantity.Literal n | n >= 0 -> [Text.pack (show n)]
  Quantity.InSlot s | s == xSlot -> [Text.pack "X"]
  _ -> []

-- | A count of cards: "a card", "two cards", "X cards".
cards :: Quantity.Quantity -> [Text.Text]
cards q = case q of
  Quantity.Literal 1 -> [Text.pack "a card"]
  Quantity.Literal n | n > 1 -> [Prose.cardinal n <> Text.pack " cards"]
  Quantity.InSlot s | s == xSlot -> [Text.pack "X cards"]
  _ -> []

-- | The objects or players a reference names, with the given determiner for a
-- description of many: damage is dealt to "each of two target creatures"
-- (Jagged Lightning), and two target lands are destroyed.
object :: Context -> Determiner -> ObjectRef.ObjectRef -> [Reference]
object context determiner ref = case ref of
  ObjectRef.InSlot s
    | s == selfSlot -> [MkReference (self context) [] Filter.Singular]
    | s == youSlot -> [MkReference (Text.pack "you") [] Filter.Singular]
    | otherwise -> do
        named <- target context s
        case (determiner, number named) of
          (Each, Filter.Plural) -> [named {wording = Text.pack "each of " <> wording named}]
          _ -> [named]
  ObjectRef.EachMatching f -> do
    p <- Filter.phrase f (keyword context)
    case determiner of
      Each -> do
        text <- Filter.describe Filter.Singular permanent p
        [MkReference (Text.pack "each " <> text) [] Filter.Plural]
      All -> do
        text <- Filter.describe Filter.Plural permanent p
        [MkReference (Text.pack "all " <> text) [] Filter.Plural]
  ObjectRef.EachPlayer -> [MkReference (Text.pack "each player") [] Filter.Plural]
  ObjectRef.EachOpponent -> [MkReference (Text.pack "each opponent") [] Filter.Plural]
  _ -> []

-- | A player as the subject of a sentence, and whether the verb takes the
-- second person ("you gain") or the third ("target player gains").
data Person
  = Second
  | Third
  deriving (Eq, Show)

-- | The players a reference names, as a subject.
player :: Context -> PlayerRef.PlayerRef -> [(Reference, Person)]
player context ref = case ref of
  PlayerRef.Relative PlayerRelation.You -> [(MkReference (Text.pack "you") [] Filter.Singular, Second)]
  PlayerRef.Relative PlayerRelation.Opponent -> [(MkReference (Text.pack "each opponent") [] Filter.Plural, Third)]
  PlayerRef.Relative PlayerRelation.AnyPlayer -> [(MkReference (Text.pack "each player") [] Filter.Plural, Third)]
  PlayerRef.InSlot s -> fmap (\r -> (r, Third)) (target context s)
  PlayerRef.OwnerOfBound _ -> [(MkReference (Text.pack "its owner") [] Filter.Singular, Third)]
  PlayerRef.ControllerOfBound _ -> [(MkReference (Text.pack "its controller") [] Filter.Singular, Third)]
  _ -> []

-- | A target slot as its announcement reads: "target creature", "any
-- target", "two target lands", "up to three target creatures". A slot whose
-- damage is divided reads through 'among' instead.
target :: Context -> SlotName.SlotName -> [Reference]
target context s = case Map.lookup s (slots context) of
  Just slot
    | Maybe.isNothing (TargetSlot.chooser slot),
      Maybe.isNothing (TargetSlot.perPlayer slot),
      Maybe.isNothing (TargetSlot.together slot),
      Maybe.isNothing (TargetSlot.amount slot),
      Maybe.isNothing (TargetSlot.divided slot) -> do
        (one, many) <- heads context slot
        (text, n) <- counted (TargetSlot.count slot) one many
        [MkReference text [s] n]
  _ -> []

-- | A slot whose damage is divided (CR 601.2d), as "among" reads it: "one or
-- two targets", "any number of target creatures".
among :: Context -> SlotName.SlotName -> [(Reference, Quantity.Quantity)]
among context s = case Map.lookup s (slots context) of
  Just slot
    | Maybe.isNothing (TargetSlot.chooser slot),
      Maybe.isNothing (TargetSlot.perPlayer slot),
      Maybe.isNothing (TargetSlot.together slot),
      Maybe.isNothing (TargetSlot.amount slot),
      Just total <- TargetSlot.divided slot -> do
        (_, many) <- heads context slot
        text <- case TargetSlot.count slot of
          SlotCount.Printed (TargetCount.MkTargetCount 1 (Just most))
            | most > 1 -> [Prose.listing "or" (fmap (Prose.cardinal . toInteger) [1 .. most]) <> Text.pack " " <> many]
          SlotCount.Printed (TargetCount.MkTargetCount 0 Nothing) -> [Text.pack "any number of " <> many]
          _ -> []
        [(MkReference text [s] Filter.Plural, total)]
  _ -> []

-- | A slot's head in both numbers, "target" included: ("target creature",
-- "target creatures"), or ("any target", "targets") for CR 115.4's phrase.
heads :: Context -> TargetSlot.TargetSlot -> [(Text.Text, Text.Text)]
heads context slot =
  let described fallback p = do
        one <- Filter.describe Filter.Singular fallback p
        many <- Filter.describe Filter.Plural fallback p
        [(Text.pack "target " <> one, Text.pack "target " <> many)]
      filtered = case TargetSlot.filter slot of
        Nothing -> [Filter.empty]
        Just f -> Filter.phrase f (keyword context)
      noun s = Filter.MkNoun (Text.pack s) (Just (Text.pack (s <> "s")))
   in case (TargetSlot.pool slot, TargetSlot.filter slot) of
        (Pool.AnyTarget, Nothing) -> [(Text.pack "any target", Text.pack "targets")]
        (Pool.AnyTarget, Just _) -> filtered >>= described (Filter.MkNoun Text.empty Nothing)
        (Pool.Creatures, _) -> filtered >>= described (noun "creature") . (\p -> Filter.merge p (Filter.MkPhrase [] [noun "creature"] []))
        (Pool.Players, _) -> filtered >>= described (noun "player")
        (Pool.PlayersAndPlaneswalkers, Nothing) -> [(Text.pack "target player or planeswalker", Text.pack "target players and/or planeswalkers")]
        (Pool.Permanents, _) -> filtered >>= described (noun "permanent")
        (Pool.Spells, _) -> filtered >>= described (noun "spell") . (\p -> Filter.merge p (Filter.MkPhrase [] [noun "spell"] []))
        _ -> []

-- | A slot's count before its head: one target reads singular, a fixed number
-- or a range plural.
counted :: SlotCount.SlotCount -> Text.Text -> Text.Text -> [(Text.Text, Filter.Number)]
counted c one many = case c of
  SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 1)) -> [(one, Filter.Singular)]
  SlotCount.Printed (TargetCount.MkTargetCount 0 (Just 1)) -> [(Text.pack "up to one " <> one, Filter.Singular)]
  SlotCount.Printed (TargetCount.MkTargetCount least (Just most))
    | least == most -> [(Prose.cardinal (toInteger most) <> Text.pack " " <> many, Filter.Plural)]
    | least == 0 -> [(Text.pack "up to " <> Prose.cardinal (toInteger most) <> Text.pack " " <> many, Filter.Plural)]
  SlotCount.Printed (TargetCount.MkTargetCount 0 Nothing) -> [(Text.pack "any number of " <> many, Filter.Plural)]
  SlotCount.AnnouncedX -> [(Text.pack "X " <> many, Filter.Plural)]
  _ -> []

-- | The noun a description of permanents falls back to.
permanent :: Filter.Noun
permanent = Filter.MkNoun (Text.pack "permanent") (Just (Text.pack "permanents"))
