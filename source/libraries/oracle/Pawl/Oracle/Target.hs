-- What an instruction is about, as Oracle text names it: target slots (CR
-- 115), the objects and players a reference names, and the numbers it reads.
module Pawl.Oracle.Target where

import qualified Control.Monad as Monad
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Types.AgainstSlot as AgainstSlot
import qualified Pawl.Types.Aggregation as Aggregation
import qualified Pawl.Types.Arithmetic as Arithmetic
import qualified Pawl.Types.ChosenPermanents as ChosenPermanents
import qualified Pawl.Types.Count as Count
import qualified Pawl.Types.EachCardInGraveyard as EachCardInGraveyard
import qualified Pawl.Types.Filter as Filter.Type
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.InZone as InZone
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Measure as Measure
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.Scope as Scope
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot
import qualified Pawl.Types.Times as Times
import qualified Pawl.Types.Together as Together
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneScope as ZoneScope

-- | What a renderer needs from around the instruction: what the card calls
-- itself, the mode's target slots, and how to print a keyword a filter names.
data Context = MkContext
  { self :: Text.Text,
    slots :: Map.Map SlotName.SlotName TargetSlot.TargetSlot,
    keyword :: Keyword.Keyword -> [Text.Text],
    -- | What may separate two sentences of one ability: a space, and for a
    -- spell's instructions a paragraph break too, since all of them are one
    -- spell ability (CR 113.3a). Anywhere else a paragraph break starts
    -- another ability (CR 113.2c). Free in a spell: one paragraph (Dark
    -- Offering) or two (Bargain).
    breaks :: [Text.Text],
    -- | What the instruction calls the object its trigger event made, if
    -- anything: "it" after "When this creature dies" (CR 400.7, CR 603.10a).
    became :: Maybe Text.Text
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
-- dealt to "each creature" and destruction is of "all creatures". A
-- continuous effect's objects read "all" only when described by their noun
-- alone: "All creatures get -1/-1" (Night of Souls' Betrayal), "All Sliver
-- creatures have frenzy 1", but "Black creatures get +1/+1" (Bad Moon) and
-- "Creatures you control get +1/+1" (Glorious Anthem).
data Determiner
  = Each
  | All
  | Affected
  deriving (Eq, Show)

-- | The slot the engine binds the object an instruction is on to, which CR
-- 201.5 names "this" or the card's name; the slot names are
-- Pawl.Engine.Binding's, which this library cannot import.
selfSlot :: SlotName.SlotName
selfSlot = SlotName.MkSlotName (Text.pack "self")

-- | The slot the engine binds the object a zone change made to (CR 400.7).
becameSlot :: SlotName.SlotName
becameSlot = SlotName.MkSlotName (Text.pack "became")

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

-- | A number as an instruction states it, with the target slots its words
-- name.
data Amount = MkAmount
  { reading :: Reading,
    names :: [SlotName.SlotName]
  }
  deriving (Eq, Show)

-- | How an amount reads.
data Reading
  = -- | A number in its place: "3 damage", "X cards".
    Stated Quantity.Quantity
  | -- | So many for each object counted, which reads in the singular: (2,
    -- "creature you control") in "gain 2 life for each creature you control".
    ForEach Integer Text.Text
  | -- | What the number equals: "the number of Mountains you control", "its
    -- power".
    EqualTo Text.Text
  deriving (Eq, Show)

-- | The ways a quantity reads. A count (CR 608.2h) of objects reads "for
-- each" of them or "equal to the number of" them, and which of those an
-- instruction offers, and first, is the instruction's. A characteristic
-- reads as an object's (CR 208.1): the source's, or a target's, which a mode
-- names once (CR 601.2c), so "its power" when the target is named already
-- (Swords to Plowshares) and "the power of target creature you control" when
-- it is not (Soul's Majesty).
amounts :: Context -> Quantity.Quantity -> [Amount]
amounts context q = case q of
  Quantity.Count c -> do
    (one, many, ms) <- counting context c
    [MkAmount (ForEach 1 one) ms, MkAmount (EqualTo (Text.pack "the number of " <> many)) ms]
  Quantity.Arithmetic (Arithmetic.Times (Times.MkTimes f (Quantity.Count c)))
    | f > 1 -> do
        (one, _, ms) <- counting context c
        [MkAmount (ForEach (toInteger f) one) ms]
  Quantity.Measure m -> do
    word <- measure m
    [MkAmount (EqualTo (possessive (self context) <> Text.pack " " <> word)) []]
  Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot s (Quantity.Measure m)) -> do
    word <- measure m
    whose <- target context s
    Monad.guard (number whose == Filter.Singular)
    [MkAmount (EqualTo (Text.pack "its " <> word)) [], MkAmount (EqualTo (Text.pack "the " <> word <> Text.pack " of " <> wording whose)) (mentions whose)]
  _ -> [MkAmount (Stated q) [] | not (null (amount q))]

-- | A characteristic's name (CR 208.1, CR 202.3).
measure :: Measure.Measure -> [Text.Text]
measure m = case m of
  Measure.Power -> [Text.pack "power"]
  Measure.Toughness -> [Text.pack "toughness"]
  Measure.ManaValue -> [Text.pack "mana value"]
  Measure.ColorCount -> []

-- | What a name or pronoun owns: "its", "Spark's".
possessive :: Text.Text -> Text.Text
possessive word
  | word == Text.pack "it" = Text.pack "its"
  | otherwise = word <> Text.pack "'s"

-- | The objects a count counts (CR 608.2h), in both numbers, and the target
-- slots the words name: ("Mountain you control", "Mountains you control"),
-- ("card in your hand", "cards in your hand"). Permanents nothing else places
-- are "on the battlefield" (Fruition). Only a count of members of a zone is
-- spelled out here.
counting :: Context -> Count.Count Quantity.Quantity -> [(Text.Text, Text.Text, [SlotName.SlotName])]
counting context c = case (Count.aggregation c, Count.scope c) of
  (Aggregation.Members, Scope.InZone (InZone.MkInZone zone whose)) -> do
    let conjuncts = case Count.filter c of
          Filter.Type.And fs -> fs
          f -> [f]
        controls f = case f of
          Filter.Type.ControlledByBound _ -> True
          Filter.Type.ControlledByRecipient -> True
          _ -> False
        (controllers, rest) = (filter controls conjuncts, filter (not . controls) conjuncts)
    p <- Filter.phrase (Filter.Type.And rest) (keyword context)
    (placed, fallback, ms) <- case (zone, whose, controllers) of
      (Zone.Battlefield, PlayerRef.Relative PlayerRelation.AnyPlayer, []) ->
        let nowhere = null (Filter.qualifiers p)
         in [(Filter.merge p (Filter.MkPhrase [] [] [Filter.MkQualifier (Text.pack "on the battlefield") (Text.pack "on the battlefield") | nowhere]), permanent, [])]
      (Zone.Battlefield, PlayerRef.Relative PlayerRelation.AnyPlayer, [controller]) -> do
        (controls', ms) <- controllerOf controller
        [(Filter.merge p (Filter.MkPhrase [] [] [Filter.MkQualifier controls' controls']), permanent, ms)]
      (_, _, []) -> do
        place <- zoneOf zone whose
        [(Filter.merge p (Filter.MkPhrase [] [card] [Filter.MkQualifier place place]), card, [])]
      _ -> []
    one <- Filter.describe Filter.Singular fallback placed
    many <- Filter.describe Filter.Plural fallback placed
    [(one, many, ms)]
  (Aggregation.Members, Scope.OverPlayers (PlayerRef.Relative PlayerRelation.Opponent))
    | Count.filter c == Filter.Type.And [] -> [(Text.pack "opponent you have", Text.pack "opponents you have", [])]
  _ -> []
  where
    -- A player a slot names is named there (Theft of Dreams) or, named
    -- already, "that player"; the mode keeps the one naming it once.
    controllerOf f = case f of
      Filter.Type.ControlledByBound s -> [(Text.pack "that player controls", [])] <> fmap (\r -> (wording r <> Text.pack " controls", mentions r)) (target context s)
      Filter.Type.ControlledByRecipient -> [(Text.pack "they control", [])]
      _ -> []

-- | A zone of a player's that cards are counted in: "in your hand", "in their
-- graveyard" for the player an instruction is applied to (Nature's
-- Resurgence), "in that player's hand" for one a slot names (Sudden Impact).
zoneOf :: Zone.Zone -> PlayerRef.PlayerRef -> [Text.Text]
zoneOf zone whose = do
  name <- case zone of
    Zone.Hand -> [Text.pack "hand"]
    Zone.Graveyard -> [Text.pack "graveyard"]
    _ -> []
  case whose of
    PlayerRef.Relative PlayerRelation.You -> [Text.pack "in your " <> name]
    PlayerRef.Candidate -> [Text.pack "in their " <> name]
    PlayerRef.InSlot _ -> [Text.pack "in that player's " <> name]
    _ -> []

-- | The objects or players a reference names, with the given determiner for a
-- description of many: damage is dealt to "each of two target creatures"
-- (Jagged Lightning), and two target lands are destroyed.
object :: Context -> Determiner -> ObjectRef.ObjectRef -> [Reference]
object context determiner ref = case ref of
  ObjectRef.InSlot s
    | s == selfSlot -> [MkReference (self context) [] Filter.Singular]
    | s == youSlot -> [MkReference (Text.pack "you") [] Filter.Singular]
    | s == becameSlot, Just it <- became context -> [MkReference it [] Filter.Singular]
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
      Affected -> do
        text <- Filter.describe Filter.Plural permanent p
        let bare = null (Filter.adjectives p) && null (Filter.qualifiers p)
        [MkReference (if bare then Text.pack "all " <> text else text) [] Filter.Plural]
  ObjectRef.EachCardInGraveyard e
    | determiner == All -> do
        p <- Filter.phrase (EachCardInGraveyard.filter e) (keyword context)
        from <- graveyard (EachCardInGraveyard.graveyards e) Nothing
        text <- Filter.describe Filter.Plural permanent (Filter.merge p (Filter.MkPhrase [] [card] [from]))
        [MkReference (Text.pack "all " <> text) [] Filter.Plural]
  ObjectRef.ChosenPermanents c
    | ChosenPermanents.chooser c == PlayerRef.Relative PlayerRelation.You -> do
        p <- Filter.phrase (ChosenPermanents.filter c) (keyword context)
        one <- Filter.describe Filter.Singular permanent p
        many <- Filter.describe Filter.Plural permanent p
        case ChosenPermanents.count c of
          HowMany.Exactly (Quantity.Literal 1) -> [MkReference (Prose.article one <> Text.pack " " <> one) [] Filter.Singular]
          HowMany.Exactly (Quantity.Literal n) | n > 1 -> [MkReference (Prose.cardinal n <> Text.pack " " <> many) [] Filter.Plural]
          HowMany.UpTo (Just (Quantity.Literal 1)) -> [MkReference (Text.pack "up to one " <> one) [] Filter.Singular]
          HowMany.UpTo (Just (Quantity.Literal n)) | n > 1 -> [MkReference (Text.pack "up to " <> Prose.cardinal n <> Text.pack " " <> many) [] Filter.Plural]
          _ -> []
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
-- "target creatures"), ("another target creature", "other target
-- creatures"), or ("any target", "targets") for CR 115.4's phrase.
heads :: Context -> TargetSlot.TargetSlot -> [(Text.Text, Text.Text)]
heads context slot = case (TargetSlot.pool slot, TargetSlot.filter slot) of
  (Pool.AnyTarget, Nothing) -> [(Text.pack "any target", Text.pack "targets")]
  (Pool.PlayersAndPlaneswalkers, Nothing) -> [(Text.pack "target player or planeswalker", Text.pack "target players and/or planeswalkers")]
  _ -> fmap (Bifunctor.bimap (targeted (Text.pack "another target ")) (targeted (Text.pack "other target "))) (described context slot)
  where
    -- "other" stands before "target", as "another" in the singular.
    targeted other text = maybe (Text.pack "target " <> text) (other <>) (Text.stripPrefix (Text.pack "other ") text)

-- | What a slot's objects are, in both numbers and without "target":
-- ("creature", "creatures"), as an Aura's enchant ability names them too
-- ("Enchant creature", CR 702.5a). Only cards in a graveyard are described
-- as all in one zone ("from a single graveyard").
described :: Context -> TargetSlot.TargetSlot -> [(Text.Text, Text.Text)]
described context slot =
  let both fallback p = do
        one <- Filter.describe Filter.Singular fallback p
        many <- Filter.describe Filter.Plural fallback p
        [(one, many)]
      filtered = case TargetSlot.filter slot of
        Nothing -> [Filter.empty]
        Just f -> Filter.phrase f (keyword context)
      noun s = Filter.MkNoun (Text.pack s) (Just (Text.pack (s <> "s")))
   in case (TargetSlot.pool slot, TargetSlot.filter slot) of
        (Pool.CardsInGraveyard scope, _) -> do
          p <- filtered
          from <- graveyard scope (TargetSlot.together slot)
          both card (Filter.merge p (Filter.MkPhrase [] [card] [from]))
        _ | Maybe.isJust (TargetSlot.together slot) -> []
        (Pool.AnyTarget, Just _) -> filtered >>= both (Filter.MkNoun Text.empty Nothing)
        (Pool.Creatures, _) -> filtered >>= both (noun "creature") . (\p -> Filter.merge p (Filter.MkPhrase [] [noun "creature"] []))
        (Pool.Players, _) -> filtered >>= both (noun "player")
        (Pool.Permanents, _) -> filtered >>= both (noun "permanent")
        (Pool.Spells, _) -> filtered >>= both (noun "spell") . (\p -> Filter.merge p (Filter.MkPhrase [] [noun "spell"] []))
        _ -> []

-- | A slot's count before its head: one target reads singular, a fixed number
-- or a range plural ("up to three target creatures", "one or two target
-- creatures").
counted :: SlotCount.SlotCount -> Text.Text -> Text.Text -> [(Text.Text, Filter.Number)]
counted c one many = case c of
  SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 1)) -> [(one, Filter.Singular)]
  SlotCount.Printed (TargetCount.MkTargetCount 0 (Just 1)) -> [(Text.pack "up to one " <> one, Filter.Singular)]
  SlotCount.Printed (TargetCount.MkTargetCount least (Just most))
    | least == most -> [(Prose.cardinal (toInteger most) <> Text.pack " " <> many, Filter.Plural)]
    | least == 0 -> [(Text.pack "up to " <> Prose.cardinal (toInteger most) <> Text.pack " " <> many, Filter.Plural)]
    | least == 1 -> [(Prose.listing "or" (fmap (Prose.cardinal . toInteger) [1 .. most]) <> Text.pack " " <> many, Filter.Plural)]
  SlotCount.Printed (TargetCount.MkTargetCount 0 Nothing) -> [(Text.pack "any number of " <> many, Filter.Plural)]
  SlotCount.AnnouncedX -> [(Text.pack "X " <> many, Filter.Plural)]
  _ -> []

-- | Which graveyards cards are in, as words after their noun: "from your
-- graveyard", "from a graveyard" or "from graveyards", "from a single
-- graveyard" for cards all in one (CR 601.2c, Carrion Beetles), "from an
-- opponent's graveyard". Cards a count reads in a graveyard are described by
-- 'zoneOf'.
graveyard :: ZoneScope.ZoneScope -> Maybe Together.Together -> [Filter.Qualifier]
graveyard scope together = case scope of
  ZoneScope.Scoped (PlayerScope.Related PlayerRelation.You) -> [Filter.MkQualifier (Text.pack "from your graveyard") (Text.pack "from your graveyard")]
  ZoneScope.Scoped (PlayerScope.Related PlayerRelation.AnyPlayer)
    | Just Together.InOneZone <- together -> [Filter.MkQualifier (Text.pack "from a single graveyard") (Text.pack "from a single graveyard")]
    | otherwise -> [Filter.MkQualifier (Text.pack "from a graveyard") (Text.pack "from graveyards")]
  ZoneScope.Scoped (PlayerScope.Related PlayerRelation.Opponent) -> [Filter.MkQualifier (Text.pack "from an opponent's graveyard") (Text.pack "from an opponent's graveyard")]
  _ -> []

-- | The noun a description of cards ends in.
card :: Filter.Noun
card = Filter.MkNoun (Text.pack "card") (Just (Text.pack "cards"))

-- | The noun a description of permanents falls back to.
permanent :: Filter.Noun
permanent = Filter.MkNoun (Text.pack "permanent") (Just (Text.pack "permanents"))
