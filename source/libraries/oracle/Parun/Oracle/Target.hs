-- What an instruction is about, as Oracle text names it: target slots (CR
-- 115), the objects and players a reference names, and the numbers it reads.
module Parun.Oracle.Target where

import qualified Control.Monad as Monad
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Parun.Oracle.Filter as Filter
import qualified Parun.Oracle.Prose as Prose
import qualified Parun.Types.AgainstSlot as AgainstSlot
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Arithmetic as Arithmetic
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.Count as Count
import qualified Parun.Types.EachCardInGraveyard as EachCardInGraveyard
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetCount as TargetCount
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.Times as Times
import qualified Parun.Types.Together as Together
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneScope as ZoneScope

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
    -- | What the instruction calls the objects and players its trigger event
    -- names (CR 603.2): "it" for the card a dying creature became (CR 400.7,
    -- CR 603.10a), "defending player" for the player an attacker attacks.
    bound :: Map.Map SlotName.SlotName Text.Text,
    -- | The slots naming a card the instruction's controller is known to
    -- own: what the source became once put into "your graveyard" (CR 404.1),
    -- which returns to "your hand" (Zodiac Dragon).
    owned :: [SlotName.SlotName],
    -- | The objects an earlier instruction of the mode has named, which a
    -- later one calls "it": "Put a +1/+1 counter on Silvar. It gains
    -- indestructible until end of turn."
    earlier :: [ObjectRef.ObjectRef],
    -- | The objects an earlier instruction of the mode changed the power and
    -- toughness of, whose next change is "an additional" one (Wild Might).
    pumped :: [ObjectRef.ObjectRef],
    -- | What the instructions call the object the source is attached to (CR
    -- 303.4b, CR 301.5a): "enchanted creature", "equipped creature", or
    -- nothing for a source that attaches to nothing.
    host :: [Text.Text]
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
-- alone, and may drop it then: "All creatures get -1/-1" (Night of Souls'
-- Betrayal), "Soldier creatures have vigilance" (Mobilization), but "Black
-- creatures get +1/+1" (Bad Moon) and "Creatures you control get +1/+1"
-- (Glorious Anthem).
data Determiner
  = Each
  | All
  | Affected
  deriving (Eq, Show)

-- | The slot the engine binds the object an instruction is on to, which CR
-- 201.5 names "this" or the card's name; the slot names are
-- Parun.Engine.Binding's, which this library cannot import.
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

-- | The slot the engine binds the amount a trigger event carried to (CR
-- 603.2), "that much".
thatMuchSlot :: SlotName.SlotName
thatMuchSlot = SlotName.MkSlotName (Text.pack "thatMuch")

-- | A number as digits ("3 damage", "4 life"), X, or the amount a trigger
-- event carried ("that much damage").
amount :: Quantity.Quantity -> [Text.Text]
amount q = case q of
  Quantity.Literal n | n >= 0 -> [Text.pack (show n)]
  Quantity.InSlot s
    | s == xSlot -> [Text.pack "X"]
    | s == thatMuchSlot -> [Text.pack "that much"]
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
-- Resurgence), "in that player's hand" for one a slot names.
zoneOf :: Zone.Zone -> PlayerRef.PlayerRef -> [Text.Text]
zoneOf zone whose = do
  name <- case zone of
    Zone.Hand -> [Text.pack "hand"]
    Zone.Graveyard -> [Text.pack "graveyard"]
    _ -> []
  case whose of
    PlayerRef.Relative PlayerRelation.You -> [Text.pack "in your " <> name]
    PlayerRef.Candidate -> [Text.pack "in their " <> name]
    -- Free: "that player's" (Sudden Impact) or "their" after naming them
    -- (Guiltfeeder).
    PlayerRef.InSlot _ -> [Text.pack "in that player's " <> name, Text.pack "in their " <> name]
    _ -> []

-- | The objects or players a reference names, with the given determiner for a
-- description of many: damage is dealt to "each of two target creatures"
-- (Jagged Lightning), and two target lands are destroyed.
object :: Context -> Determiner -> ObjectRef.ObjectRef -> [Reference]
object context determiner ref = case ref of
  _
    | elem ref (earlier context) -> case ref of
        ObjectRef.InSlot s
          | s == selfSlot -> [MkReference (Text.pack "it") [] Filter.Singular]
          | Just slot <- Map.lookup s (slots context),
            fmap number (target context s) == [Filter.Singular] -> case (TargetSlot.pool slot, pooled slot) of
              (Pool.Players, _) -> [MkReference (Text.pack "that player") [] Filter.Singular]
              -- Free: "it" (Cryogenic Stasis) or "that creature" (Burning
              -- Cloak).
              (_, nouns@(_ : _)) -> MkReference (Text.pack "it") [] Filter.Singular : fmap (\noun -> MkReference (Text.pack "that " <> noun) [] Filter.Singular) nouns
              -- A target that may be a player or an object named again is
              -- not spelled out here.
              _ -> []
        -- Objects a continuous effect changes again: "They get an
        -- additional +0/+2" (Rhystic Shield). Several objects named again
        -- anywhere else are not spelled out here.
        _
          | determiner == Affected,
            [MkReference _ _ Filter.Plural] <- object context {earlier = []} determiner ref ->
              [MkReference (Text.pack "they") [] Filter.Plural]
        _ -> []
  ObjectRef.InSlot s
    | s == selfSlot -> [MkReference (self context) [] Filter.Singular]
    | s == youSlot -> [MkReference (Text.pack "you") [] Filter.Singular]
    | Just word <- Map.lookup s (bound context) -> [MkReference word [] Filter.Singular]
    | otherwise -> do
        named <- target context s
        case (determiner, number named) of
          (Each, Filter.Plural) -> [named {wording = Text.pack "each of " <> wording named}]
          _ -> [named]
  ObjectRef.EachMatching Filter.Type.IsHostOfSource -> fmap (\h -> MkReference h [] Filter.Singular) (host context)
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
        [MkReference w [] Filter.Plural | w <- if bare then [Text.pack "all " <> text, text] else [text]]
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
  PlayerRef.InSlot s
    | s == youSlot -> [(MkReference (Text.pack "you") [] Filter.Singular, Second)]
    | Just word <- Map.lookup s (bound context) -> [(MkReference word [] Filter.Singular, Third)]
    | otherwise -> fmap (\r -> (r, Third)) (target context s)
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

-- | The noun a slot's pool names its objects by, which "that" names one of
-- again: "that creature", "that permanent".
pooled :: TargetSlot.TargetSlot -> [Text.Text]
pooled slot = case TargetSlot.pool slot of
  Pool.Creatures -> [Text.pack "creature"]
  Pool.Permanents -> [Text.pack "permanent"]
  Pool.Spells -> [Text.pack "spell"]
  Pool.CardsInGraveyard _ -> [Text.pack "card"]
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
        (Pool.Creatures, _) -> filtered >>= creature >>= both (noun "creature")
        (Pool.Players, _) -> filtered >>= both (noun "player")
        (Pool.Permanents, _) -> filtered >>= both (noun "permanent")
        (Pool.Spells, _) -> filtered >>= both (noun "spell") . (\p -> Filter.merge p (Filter.MkPhrase [] [noun "spell"] []))
        _ -> []

-- | A description of creatures, ending in "creature": "target artifact
-- creature". Free when a creature type names them: "target attacking Goblin
-- you control" (Boggart Prankster) or "target Merfolk creature" (Merfolk
-- Sovereign).
creature :: Filter.Phrase -> [Filter.Phrase]
creature p
  | any ((== Text.pack "creature") . Filter.singular) (Filter.nouns p) = [p]
  | not (all Filter.kind (Filter.nouns p)) = [p, withCreature]
  | otherwise = [withCreature]
  where
    withCreature = Filter.merge p (Filter.MkPhrase [] [Filter.MkNoun (Text.pack "creature") (Just (Text.pack "creatures"))] [])

-- | A slot's count before its head: one target reads singular, a fixed number
-- or a range plural ("up to three target creatures", "one or two target
-- creatures").
counted :: SlotCount.SlotCount -> Text.Text -> Text.Text -> [(Text.Text, Filter.Number)]
counted c one many = case c of
  SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 1)) -> [(one, Filter.Singular)]
  -- "up to one other target creature" (Sunpearl Kirin), as "other" reads
  -- after a number.
  SlotCount.Printed (TargetCount.MkTargetCount 0 (Just 1)) -> [(Text.pack "up to one " <> maybe one (Text.pack "other " <>) (Text.stripPrefix (Text.pack "another ") one), Filter.Singular)]
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
