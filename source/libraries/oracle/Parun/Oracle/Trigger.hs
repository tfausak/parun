-- Trigger events (CR 603.1, CR 603.2) as the words that open a triggered
-- ability, and the intervening "if" clauses that follow them (CR 603.4).
module Parun.Oracle.Trigger where

import qualified Control.Monad as Monad
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Parun.Oracle.Filter as Filter
import qualified Parun.Oracle.Prose as Prose
import qualified Parun.Oracle.Target as Target
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | A trigger event as the ability's opening words say it: "When Spark
-- enters", "At the beginning of your upkeep". Whether those words name the
-- ability's source, which the rest of the ability then calls "it" (Fire Imp),
-- and the words the rest calls each object or player the event names with
-- (CR 603.2): "defending player", "that creature".
data Event = MkEvent
  { opening :: Text.Text,
    named :: Bool,
    bound :: Map.Map SlotName.SlotName Text.Text,
    -- | The slots naming a card the ability's controller is known to own
    -- ('Target.owned').
    owned :: [SlotName.SlotName]
  }
  deriving (Eq, Show)

-- | The trigger event's wordings, given what the card calls itself and
-- whether it is a creature. "At" opens a step or phase beginning (CR
-- 603.1). Several events of the source's own read as one: "When this
-- creature enters or dies". Only the events below render yet.
event :: Target.Context -> Bool -> TriggerCondition.TriggerCondition -> [Event]
event context creature c = case c of
  -- One description of the creature for both: "blocks or becomes blocked by
  -- a creature" (Inferno Elemental).
  TriggerCondition.AnyOf [TriggerCondition.SelfBlocksCreature f, TriggerCondition.SelfBecomesBlockedBy g] | f == g -> do
    (one, that) <- described context f
    itself recurring (Text.pack ("blocks or becomes blocked by " <> one)) [(thatAttacker, that), (thatBlocker, that)] []
  TriggerCondition.AnyOf cs@(_ : _ : _) -> do
    parts <- traverse (selfEvent context creature) cs
    let openings = if all ((== ["When"]) . fst3) parts then ["When"] else recurring
    itself openings (Prose.listing "or" (fmap (Text.pack . snd3) parts)) (concatMap thd3 parts) (concatMap ownership cs)
  _ | own@(_ : _) <- selfEvent context creature c -> do
    (openings, happens, slots) <- own
    itself openings (Text.pack happens) slots (ownership c)
  TriggerCondition.PermanentEnters f -> do
    (one, that) <- described context f
    -- Free: the entrant is "it" (Aether Flash) or "that creature" (Agent's
    -- Toolkit).
    word <- ["it", that]
    subject <- also one
    -- Landfall is the ability word (CR 207.2c) Oracle text prints before
    -- this event and no other (Sporemound).
    opening' <- case one of
      "a land you control" -> ["Landfall \8212 "]
      _ -> [""]
    [other (opening' <> "Whenever " <> subject <> " enters") [(becameSlot, word)]]
  TriggerCondition.PermanentDies f -> do
    (one, that) <- described context f
    word <- ["it", that]
    subject <- also one
    [other ("Whenever " <> subject <> " dies") [(becameSlot, word), (departedPermanent, word)]]
  TriggerCondition.PermanentDealsCombatDamageToPlayer p -> do
    (one, that) <- described context (PermanentDealsCombatDamageToPlayer.filter p)
    (whom, player') <- player (PermanentDealsCombatDamageToPlayer.recipient p)
    [other ("Whenever " <> one <> " deals combat damage to " <> whom) [(thatPlayer, player'), (combatDamager, that)]]
  TriggerCondition.IsDealtDamage (ActingPermanent.Matching f) -> do
    (one, _) <- described context f
    [other ("Whenever " <> one <> " is dealt damage") [(becameSlot, "it")]]
  TriggerCondition.DealsCombatDamage (ActingPermanent.Matching f) -> do
    (one, that) <- described context f
    [other ("Whenever " <> one <> " deals combat damage") [(combatDamager, that)]]
  TriggerCondition.PlayerAttacks relation -> do
    who <- case relation of
      PlayerRelation.You -> ["you attack"]
      PlayerRelation.Opponent -> ["an opponent attacks"]
      PlayerRelation.AnyPlayer -> ["a player attacks"]
      _ -> []
    [other ("Whenever " <> who) [(attackingPlayer, "that player")]]
  TriggerCondition.StepBegins s -> do
    when <- step s
    [other ("At the beginning of " <> when) [(thatPlayer, "that player")]]
  -- CR 601.2i: who casts the spell is its controller (CR 112.2), which the
  -- filter names among the spell's other qualities.
  TriggerCondition.SpellCast (SpellCast.MkSpellCast f TurnScope.EachTurn Nothing Nothing Nothing False) -> do
    let caster g = case g of
          Filter.Type.ControlledBy _ -> True
          _ -> False
        (casters, rest) = List.partition caster (case f of Filter.Type.And fs -> fs; _ -> [f])
    who <- case casters of
      [] -> ["a player casts"]
      [Filter.Type.ControlledBy PlayerRelation.You] -> ["you cast"]
      [Filter.Type.ControlledBy PlayerRelation.Opponent] -> ["an opponent casts"]
      _ -> []
    let spell = Filter.noun (Text.pack "spell") (Just (Text.pack "spells"))
    -- A disjunction of kinds of spell shares the noun, "an instant or
    -- sorcery spell" (Young Pyromancer), unless one kind is described
    -- further: "a Doctor spell or creature spell with doctor's companion"
    -- (Rose Noble).
    p <- case rest of
      [Filter.Type.Or gs] -> do
        ps <- traverse (\g -> Filter.phrase g (Target.keyword context)) gs
        let described' q = not (null (Filter.adjectives q) && null (Filter.qualifiers q))
        if not (any (null . Filter.nouns) ps) && any described' ps then Filter.disjunction (fmap (`Filter.merge` spell) ps) else fmap (`Filter.merge` spell) (Filter.phrase (Filter.Type.Or gs) (Target.keyword context))
      _ -> fmap (`Filter.merge` spell) (Filter.phrase (Filter.Type.And rest) (Target.keyword context))
    plain <- Filter.describe Filter.Singular Target.permanent p
    -- Free for a disjunction of colours: "a spell that's white, blue, black,
    -- or red" (Quirion Dryad).
    let coloured g = case g of
          Filter.Type.HasColor _ -> True
          _ -> False
        thats = case rest of
          [Filter.Type.Or gs] | all coloured gs -> [Text.pack "spell that's " <> adjectives | Just adjectives <- [Text.stripSuffix (Text.pack " spell") plain]]
          _ -> []
    one <- plain : thats
    opening' <- recurring
    [other (opening' <> " " <> who <> " " <> Text.unpack (Prose.article one) <> " " <> Text.unpack one) [(thatPlayer, "that player"), (castSpell, "it")]]
  _ -> []
  where
    self = Text.unpack (Target.self context)
    itself openings happens slots mine = [MkEvent (Text.pack (word <> " " <> self <> " ") <> happens) True (slotted slots) mine | word <- openings]
    other happens slots = MkEvent (Text.pack happens) False (slotted slots) []
    fst3 (a, _, _) = a
    snd3 (_, b, _) = b
    thd3 (_, _, x) = x
    slotted :: [(SlotName.SlotName, String)] -> Map.Map SlotName.SlotName Text.Text
    slotted = Map.fromList . fmap (fmap Text.pack)
    -- Free for a creature's event on objects it may be one of: they are named
    -- alone (Promise of Tomorrow) or after the source (Zulaport Cutthroat's
    -- "this creature or another creature you control"), as the source is one
    -- of them or not, which is not read here.
    also one = case words one of
      article : rest | creature, article /= "another" -> [one, self <> " or another " <> unwords rest]
      _ -> [one]

-- | What the source's own event says after its name, the words opening it
-- ("When", or "Whenever" for one that can recur), and the words the rest
-- names the objects and players it binds with. A creature "dies"; any other
-- permanent "is put into a graveyard from the battlefield", the same event
-- (CR 700.4) in the words Oracle text keeps for it (Chromatic Star).
selfEvent :: Target.Context -> Bool -> TriggerCondition.TriggerCondition -> [([String], String, [(SlotName.SlotName, String)])]
selfEvent context creature c = case c of
  TriggerCondition.SelfEnters -> [(["When"], "enters", [])]
  TriggerCondition.SelfDies
    | creature -> [(["When"], "dies", [(becameSlot, "it")])]
    | otherwise -> [(["When"], "is put into a graveyard from the battlefield", [(becameSlot, "it")])]
  TriggerCondition.SelfLeavesTheBattlefield -> [(["When"], "leaves the battlefield", [(becameSlot, "it")])]
  TriggerCondition.SelfPutFromBattlefieldInto (OwnedZone.MkOwnedZone Zone.Graveyard PlayerRelation.You) -> [(["When"], "is put into your graveyard from the battlefield", [(becameSlot, "it")])]
  TriggerCondition.SelfPutFromBattlefieldInto (OwnedZone.MkOwnedZone Zone.Exile PlayerRelation.AnyPlayer) -> [(["When"], "is put into exile from the battlefield", [(becameSlot, "it")])]
  TriggerCondition.SelfAttacks TriggerFrequency.EveryTime -> [(recurring, "attacks", [(thatPlayer, "defending player")])]
  TriggerCondition.SelfAttacks TriggerFrequency.FirstTimeEachTurn -> [(recurring, "attacks for the first time each turn", [(thatPlayer, "defending player")])]
  TriggerCondition.SelfAttacksWhileSaddled -> [(recurring, "attacks while saddled", [])]
  TriggerCondition.CreatureAttacksAlone Filter.Type.IsSource -> [(recurring, "attacks alone", [(attackingCreature, "it")])]
  TriggerCondition.SelfAttacksUnblocked -> [(recurring, "attacks and isn't blocked", [(thatPlayer, "defending player")])]
  TriggerCondition.SelfBlocks -> [(recurring, "blocks", [])]
  TriggerCondition.SelfBecomesBlocked -> [(recurring, "becomes blocked", [(thatPlayer, "defending player")])]
  TriggerCondition.SelfBlocksCreature f -> do
    (one, that) <- described context f
    [(recurring, "blocks " <> one, [(thatAttacker, that)])]
  TriggerCondition.SelfBecomesBlockedBy f -> do
    (one, that) <- described context f
    [(recurring, "becomes blocked by " <> one, [(thatBlocker, that)])]
  -- Free: the ability word enrage (CR 207.2c) printed (Ripjaw Raptor) or
  -- not (Stuffy Doll).
  TriggerCondition.IsDealtDamage ActingPermanent.Self -> [(recurring <> ["Enrage \8212 Whenever"], "is dealt damage", [])]
  TriggerCondition.DealsDamage ActingPermanent.Self -> [(recurring, "deals damage", [])]
  TriggerCondition.DealsCombatDamage ActingPermanent.Self -> [(recurring, "deals combat damage", [])]
  TriggerCondition.SelfDealsCombatDamageToPlayer relation -> do
    (whom, that) <- player relation
    [(recurring, "deals combat damage to " <> whom, [(thatPlayer, that)])]
  TriggerCondition.DealsDamageToPlayer (DealsDamageToPlayer.MkDealsDamageToPlayer ActingPermanent.Self relation) -> do
    (whom, that) <- player relation
    [(recurring, "deals damage to " <> whom, [(thatPlayer, that)])]
  _ -> []

-- | The slots of the source's own event naming a card its controller is
-- known to own: what it became in "your graveyard" (CR 404.1).
ownership :: TriggerCondition.TriggerCondition -> [SlotName.SlotName]
ownership c = case c of
  TriggerCondition.SelfPutFromBattlefieldInto (OwnedZone.MkOwnedZone Zone.Graveyard PlayerRelation.You) -> [becameSlot]
  _ -> []

-- | Free for an event that can recur: "Whenever" (Wall of Dust) or "When"
-- (Loyal Sentry, which destroys itself).
recurring :: [String]
recurring = ["Whenever", "When"]

-- | A filter as the object an event is about, with its article ("a
-- creature", "another creature"), and the noun "that" names it by afterwards
-- ("that creature").
described :: Target.Context -> Filter.Type.Filter Keyword.Keyword -> [(String, String)]
described context f = do
  p <- Filter.phrase f (Target.keyword context)
  one <- Filter.describe Filter.Singular Target.permanent p
  that <- Filter.describe Filter.Singular Target.permanent p {Filter.adjectives = [], Filter.qualifiers = []}
  let article = maybe (Prose.article one <> Text.pack " " <> one) (Text.pack "another " <>) (Text.stripPrefix (Text.pack "other ") one)
  [(Text.unpack article, "that " <> Text.unpack that)]

-- | A player an event names, and what the rest calls them. Free for an
-- opponent: "that player" (Wei Night Raiders) or "that opponent" (Zhang Liao,
-- Hero of Hefei).
player :: PlayerRelation.PlayerRelation -> [(String, String)]
player relation = case relation of
  PlayerRelation.AnyPlayer -> [("a player", "that player")]
  PlayerRelation.Opponent -> [("an opponent", "that player"), ("an opponent", "that opponent")]
  PlayerRelation.You -> [("you", "that player")]
  _ -> []

-- | Whether the event is a draw step beginning, whose ability's draw comes
-- after CR 504.1's own and so is "an additional card" (Howling Mine).
drawStep :: TriggerCondition.TriggerCondition -> Bool
drawStep c = case c of
  TriggerCondition.StepBegins s -> StepBegins.phase s == Phase.Beginning BeginningStep.DrawStep
  _ -> False

-- | Which step's or phase's beginning, and in whose turns (CR 603.2b): "your
-- upkeep", "each player's upkeep", "combat on your turn", "your second main
-- phase" (CR 505.1). The end step of every turn is free: "each end step"
-- (Khabal Ghoul), "the end step" (Lightning Skelemental) or "each player's
-- end step" (Mana Cache).
step :: StepBegins.StepBegins -> [String]
step s = case (StepBegins.phase s, StepBegins.ordinal s, StepBegins.scope s) of
  (Phase.Beginning b, Nothing, scope) -> do
    name <- case b of
      BeginningStep.Upkeep -> ["upkeep"]
      BeginningStep.DrawStep -> ["draw step"]
      BeginningStep.Untap -> []
    case scope of
      TurnScope.ControllersTurn -> ["your " <> name]
      -- Free: "each player's upkeep" (Elkin Lair) or "each upkeep" (Worms
      -- of the Earth).
      TurnScope.EachTurn -> ["each player's " <> name] <> ["each " <> name | b == BeginningStep.Upkeep]
      TurnScope.OpponentsTurn -> ["each opponent's " <> name]
      TurnScope.PlayersTurn ref -> namedPlayers name ref
  (Phase.Combat CombatStep.BeginningOfCombat, Nothing, scope) -> case scope of
    TurnScope.ControllersTurn -> ["combat on your turn"]
    TurnScope.EachTurn -> ["each combat"]
    TurnScope.OpponentsTurn -> ["combat on each opponent's turn"]
    TurnScope.PlayersTurn _ -> []
  (Phase.Ending EndingStep.EndStep, Nothing, scope) -> case scope of
    TurnScope.ControllersTurn -> ["your end step"]
    TurnScope.EachTurn -> ["each end step", "the end step", "each player's end step"]
    TurnScope.OpponentsTurn -> ["each opponent's end step"]
    TurnScope.PlayersTurn ref -> namedPlayers "end step" ref
  (Phase.PostcombatMain, Just 2, TurnScope.ControllersTurn) -> ["your second main phase"]
  (Phase.PostcombatMain, Nothing, TurnScope.ControllersTurn) -> ["each of your postcombat main phases"]
  _ -> []

-- | A step of a named player's turn: Soul Bleed's "the upkeep of enchanted
-- creature's controller", over the source slot.
namedPlayers :: String -> PlayerRef.PlayerRef -> [String]
namedPlayers name ref = case ref of
  PlayerRef.HolderOfBound Holder.Controller Hop.Host slot | slot == Target.selfSlot -> ["the " <> name <> " of enchanted creature's controller"]
  _ -> []

-- | The slots Parun.Engine.Binding binds a trigger event's objects and players
-- to, which this library cannot import.
becameSlot, thatPlayer, thatAttacker, thatBlocker, departedPermanent, combatDamager, attackingPlayer, attackingCreature, castSpell :: SlotName.SlotName
becameSlot = Target.becameSlot
thatPlayer = SlotName.MkSlotName (Text.pack "thatPlayer")
thatAttacker = SlotName.MkSlotName (Text.pack "thatAttacker")
thatBlocker = SlotName.MkSlotName (Text.pack "thatBlocker")
departedPermanent = SlotName.MkSlotName (Text.pack "thatDepartedPermanent")
combatDamager = SlotName.MkSlotName (Text.pack "thatDamager")
attackingPlayer = SlotName.MkSlotName (Text.pack "thatAttackingPlayer")
attackingCreature = SlotName.MkSlotName (Text.pack "thatAttackingCreature")
castSpell = SlotName.MkSlotName (Text.pack "thatSpell")

-- | An intervening "if" clause's condition (CR 603.4): a count of cards in
-- a hand ("you have no cards in hand"), of permanents ("you control no
-- creatures", "there are no Zombies on the battlefield"), the source's own
-- status ("this artifact is untapped"), a player's life, monarchy or attack
-- this turn, or whose turn it is. Any other condition is not spelled out here.
condition :: Target.Context -> Condition.Condition -> [Text.Text]
condition context c = case c of
  Condition.Compares (Compares.MkCompares measured comparison threshold) -> case (measured, threshold) of
    (Quantity.Count n, Quantity.Literal k) | Count.aggregation n == Aggregation.Members -> counted context n comparison k
    (Quantity.LifeTotal who, Quantity.Literal k) -> do
      (subject, have) <- holder context who
      bound' <- case comparison of
        Comparison.AtLeast -> [Text.pack (show k <> " or more")]
        Comparison.AtMost -> [Text.pack (show k <> " or less")]
        _ -> []
      [subject <> Text.pack " " <> have <> Text.pack " " <> bound' <> Text.pack " life"]
    (Quantity.IsMonarch who, Quantity.Literal 1) | comparison == Comparison.AtLeast -> do
      (subject, _) <- holder context who
      [subject <> (if subject == Text.pack "you" then Text.pack " are" else Text.pack " is") <> Text.pack " the monarch"]
    -- CR 102.1, as Oracle text writes it (Blood Burglar).
    (Quantity.IsActivePlayer (PlayerRef.Relative PlayerRelation.You), Quantity.Literal 1) | comparison == Comparison.Exactly -> [Text.pack "it's your turn"]
    (Quantity.AttackersDeclaredThisTurn who, Quantity.Literal 1) | comparison == Comparison.AtLeast -> do
      (subject, _) <- holder context who
      [subject <> Text.pack " attacked this turn"]
    _ -> []
  _ -> []

-- | The ability word (CR 207.2c) Oracle text may print before an ability
-- whose condition this is. Free for hellbent: printed (Slaughterhouse
-- Bouncer) or not (Academy at Tolaria West). Free for raid: printed (Mardu
-- Skullhunter) or not (Trynn, Champion of Freedom). Free for threshold:
-- printed (Anurid Barkripper) or not (Illuminate History).
abilityWord :: Text.Text -> [Text.Text]
abilityWord words' = [Text.empty] <> [Text.pack "Hellbent \8212 " | words' == Text.pack "you have no cards in hand"] <> [Text.pack "Raid \8212 " | words' == Text.pack "you attacked this turn"] <> [Text.pack "Threshold \8212 " | words' == Text.pack "there are seven or more cards in your graveyard"]

-- | Whether the condition is the source's own status ("this creature is
-- attacking"), as 'counted' reads it, after which the source is "it".
aboutSource :: Condition.Condition -> Bool
aboutSource c = case c of
  Condition.Compares (Compares.MkCompares (Quantity.Count n) _ _)
    | Scope.InZone (InZone.MkInZone Zone.Battlefield _) <- Count.scope n -> elem Filter.Type.IsSource (case Count.filter n of Filter.Type.And fs -> fs; f -> [f])
  _ -> False

-- | A player as the subject of a condition, with the verb "have" agreeing:
-- ("you", "have"), ("that player", "has").
holder :: Target.Context -> PlayerRef.PlayerRef -> [(Text.Text, Text.Text)]
holder context who = case who of
  PlayerRef.Relative PlayerRelation.You -> [(Text.pack "you", Text.pack "have")]
  PlayerRef.Relative PlayerRelation.Opponent -> [(Text.pack "an opponent", Text.pack "has")]
  PlayerRef.InSlot s | Just word <- Map.lookup s (Target.bound context) -> [(word, Text.pack "has")]
  _ -> []

-- | A count compared with a number, as words before a noun and the noun's
-- number: "no" creatures, "a" card, "seven or more" cards, "two or fewer"
-- cards.
quantifier :: Comparison.Comparison -> Integer -> [(Text.Text -> Text.Text, Filter.Number)]
quantifier comparison k = case comparison of
  _ | k == 0, elem comparison [Comparison.Exactly, Comparison.AtMost] -> [(const (Text.pack "no"), Filter.Plural)]
  Comparison.AtLeast
    | k == 1 -> [(Prose.article, Filter.Singular)]
    | k > 1 -> [(const (Prose.cardinal k <> Text.pack " or more"), Filter.Plural)]
  Comparison.AtMost | k > 0 -> [(const (Prose.cardinal k <> Text.pack " or fewer"), Filter.Plural)]
  _ -> []

-- | A count of members of a zone compared with a number: cards in a hand or
-- in your graveyard, permanents a player controls or on the battlefield, or
-- the source alone, whose status the condition is.
counted :: Target.Context -> Count.Count Quantity.Quantity -> Comparison.Comparison -> Integer -> [Text.Text]
counted context n comparison k = case Count.scope n of
  -- "there are seven or more cards in your graveyard" (CR 404.1).
  Scope.InZone (InZone.MkInZone Zone.Graveyard who@(PlayerRef.Relative PlayerRelation.You)) -> do
    p <- Filter.phrase (Count.filter n) (Target.keyword context)
    (before, number) <- quantifier comparison k
    noun <- Filter.describe number Target.card (Filter.merge p (Filter.MkPhrase [] [Target.card] []))
    place <- Target.zoneOf Zone.Graveyard who
    let be = if number == Filter.Singular then Text.pack "is" else Text.pack "are"
    [Text.pack "there " <> be <> Text.pack " " <> before noun <> Text.pack " " <> noun <> Text.pack " " <> place]
  Scope.InZone (InZone.MkInZone Zone.Hand who)
    | Count.filter n == Filter.Type.And [] -> do
        (subject, have) <- holder context who
        (before, number) <- quantifier comparison k
        let cards = if number == Filter.Singular then Text.pack "card" else Text.pack "cards"
        [subject <> Text.pack " " <> have <> Text.pack " " <> before cards <> Text.pack " " <> cards <> Text.pack " in hand"]
  Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)) -> do
    let conjuncts = case Count.filter n of
          Filter.Type.And fs -> fs
          f -> [f]
    case (filter (== Filter.Type.IsSource) conjuncts, filter (/= Filter.Type.IsSource) conjuncts) of
      -- The source's status: "this creature is tapped" (Acrobatic
      -- Cheerleader).
      ([_], rest)
        | comparison == Comparison.AtLeast,
          k == 1 -> do
            p <- Filter.phrase (Filter.Type.And rest) (Target.keyword context)
            Monad.guard (null (Filter.nouns p) && null (Filter.qualifiers p) && not (null (Filter.adjectives p)))
            status <- Filter.describe Filter.Singular (Filter.MkNoun Text.empty Nothing) p
            [Target.self context <> Text.pack " is " <> status]
      ([], _) -> do
        let controls f = case f of
              Filter.Type.ControlledBy PlayerRelation.You -> True
              Filter.Type.ControlledBy PlayerRelation.Opponent -> True
              Filter.Type.HeldByBound Holder.Controller _ -> True
              _ -> False
            (controllers, rest) = (filter controls conjuncts, filter (not . controls) conjuncts)
        p <- Filter.phrase (Filter.Type.And rest) (Target.keyword context)
        (before, number) <- quantifier comparison k
        noun <- Filter.describe number Target.permanent p
        let some = maybe (before noun <> Text.pack " " <> noun) (Text.pack "another " <>) (Monad.guard (number == Filter.Singular) >> Text.stripPrefix (Text.pack "other ") noun)
        case controllers of
          [Filter.Type.ControlledBy PlayerRelation.You] -> [Text.pack "you control " <> some]
          [Filter.Type.ControlledBy PlayerRelation.Opponent] -> [Text.pack "an opponent controls " <> some]
          [Filter.Type.HeldByBound Holder.Controller s] | Just word <- Map.lookup s (Target.bound context) -> [word <> Text.pack " controls " <> some]
          -- Free: "there are no Zombies on the battlefield" (Sarcomancy) or
          -- "no creatures are on the battlefield" (Pestilence, Sixth Edition),
          -- and for one or more "any player controls a black permanent"
          -- (Knight of Grace).
          [] ->
            let be = if number == Filter.Singular then Text.pack "is" else Text.pack "are"
             in [Text.pack "there " <> be <> Text.pack " " <> some <> Text.pack " on the battlefield", some <> Text.pack " " <> be <> Text.pack " on the battlefield"] <> [Text.pack "any player controls " <> some | comparison == Comparison.AtLeast, k == 1]
          _ -> []
      _ -> []
  _ -> []
