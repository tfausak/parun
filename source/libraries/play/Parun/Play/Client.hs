-- | The text client: a person answering request lines at a terminal. It reads
-- only the decoded line and the card data, never the game, so anything it
-- cannot show is a gap in the protocol.
module Parun.Play.Client where

import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Char as Char
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Either as Either
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Codec.CombatDamageOption as Codec.CombatDamageOption
import qualified Parun.Codec.Cost as Codec.Cost
import qualified Parun.Codec.CostComponent as Codec.CostComponent
import qualified Parun.Codec.Keyword as Codec.Keyword
import qualified Parun.Codec.ManaCost as Codec.ManaCost
import qualified Parun.Codec.ManaType as Codec.ManaType
import qualified Parun.Codec.ManaUnit as Codec.ManaUnit
import qualified Parun.Codec.NumberFloor as Codec.NumberFloor
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Codec.Request as Codec.Request
import qualified Parun.Codec.Zone as Codec.Zone
import qualified Parun.Engine.PlayerView as PlayerView.Engine
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Oracle.Cost as Oracle.Cost
import qualified Parun.Oracle.Keyword as Oracle.Keyword
import qualified Parun.Play.Render as Render
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CombatDamageOption as CombatDamageOption
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Hotseat as Hotseat
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Mana as Mana
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaRetention as ManaRetention
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.NumberFloor as NumberFloor
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectView as ObjectView
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView
import qualified Parun.Types.ProductionTag as ProductionTag
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Request as Request
import qualified Parun.Types.SeatView as SeatView
import qualified Parun.Types.Terminal as Terminal
import qualified Parun.Types.Undoing as Undoing
import qualified Text.Read as Read

-- | The client's monad: what it keeps between lines, and why play stopped.
type Client m = State.StateT Hotseat.Hotseat (Except.ExceptT Text.Text m)

-- | Answers one request line with a reply line, asking the person at the
-- terminal. A seat change first clears the screen and waits for the next
-- player. Fails with why play stopped: the end of input, or "quit".
--
-- CR 104.3a: a seat concedes by typing "concede" at any question, and the
-- client answers the engine's next Concede prompt for that seat with it. A
-- card's printed text comes from the card data, by a name the view shows, and
-- card data that cannot be read stops play, saying why.
respond :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> Text.Text -> Client m Text.Text
respond terminal lookUp line = do
  request <- either (stop . (Text.pack "unreadable request: " <>)) pure (Common.parse line >>= Codec.decode Codec.Request.codec)
  let question = Request.question request
      seat = Question.seat question
  -- The hotseat asks CR 103.1's play or draw at the terminal itself
  -- (Parun.Play.Game.playOrDraw), so every request it reads has a view.
  view <- maybe (stop (Text.pack "a request with no view")) pure (Request.view request)
  collect view
  Monad.when (Question.kind question == Text.pack "ChooseAction") (undone seat view)
  Monad.when (Question.kind question `elem` fmap Text.pack ["DeclareAttackers", "DeclareBlockers"]) (redeclaring seat question view)
  fmap (Common.render . Codec.Reply.toValue) $
    if Question.kind question == Text.pack "Concede"
      then do
        conceding <- State.gets (Set.member seat . Hotseat.conceding)
        pure (R.Text (Text.pack (if conceding then "Concedes" else "Continues")))
      else do
        (said, automatic) <- unasked view request
        case automatic of
          Nothing -> do
            mapM_ (say terminal) said
            reply <- asked terminal lookUp view request
            attempt seat view question reply
            pure reply
          Just reply -> do
            -- Only the seat the screen faces is shown its news unasked.
            facing <- State.gets Hotseat.facing
            news <- if facing == Just seat then tell False seat else pure []
            mapM_ (say terminal) (news <> said)
            pure reply

-- | Remembers a cast or an activation the seat chose, so its next priority
-- can tell it whether the action was undone.
attempt :: (Monad m) => PlayerId.PlayerId -> PlayerView.PlayerView -> Question.Question -> R.Reply -> Client m ()
attempt seat view question reply = case reply of
  R.Number i
    | Question.kind question == Text.pack "ChooseAction",
      Just option <- arrayOf (Question.offer question) >>= Maybe.listToMaybe . List.genericDrop i,
      Just kind <- field "action" option >>= textOf,
      kind `elem` [Text.pack "Cast", Text.pack "Activate"] ->
        let mark = (PlayerView.game view, PlayerView.turn view, Natural.length (PlayerView.witnessed view))
         in State.modify' (\h -> h {Hotseat.attempted = Map.insert seat (mark, actionName view option) (Hotseat.attempted h)})
  _ -> pure ()

-- | CR 734.1: at the seat's priority after a cast or an activation it chose,
-- a line of news saying it was undone when its view has logged no spell cast
-- and no ability activated since, and why where the view says
-- (PlayerView.undone).
undone :: (Monad m) => PlayerId.PlayerId -> PlayerView.PlayerView -> Client m ()
undone seat view = do
  tried <- State.gets (Map.lookup seat . Hotseat.attempted)
  State.modify' (\h -> h {Hotseat.attempted = Map.delete seat (Hotseat.attempted h)})
  case tried of
    Just ((game, turn, n), action)
      | game == PlayerView.game view,
        turn == PlayerView.turn view,
        not (any (completes . LoggedEvent.event) (List.genericDrop n (PlayerView.witnessed view))) ->
          tellUndone seat action (PlayerView.undone view)
    _ -> pure ()
  where
    completes e = case e of
      GameEvent.SpellCast {} -> True
      GameEvent.AbilityActivated {} -> True
      _ -> False

-- | CR 734.1 with CR 508.1 / 509.1's preambles: at a declaration of attackers
-- or blockers, a line of news saying the seat's last one was undone when its
-- view says why (PlayerView.undone), which the engine notes only for a
-- declaration it asks again.
redeclaring :: (Monad m) => PlayerId.PlayerId -> Question.Question -> PlayerView.PlayerView -> Client m ()
redeclaring seat question view = Monad.forM_ (PlayerView.undone view) $ \why ->
  tellUndone seat (Text.pack (if Question.kind question == Text.pack "DeclareAttackers" then "The declaration of attackers" else "The declaration of blockers")) (Just why)

-- | The line of news saying `action` was undone, and why where the view says.
tellUndone :: (Monad m) => PlayerId.PlayerId -> Text.Text -> Maybe Undoing.Undoing -> Client m ()
tellUndone seat action why =
  let line = Text.pack "Undone: " <> action <> Text.pack " could not be completed" <> foldMap because why <> Text.pack ", so it was reversed and its payments canceled."
   in State.modify' (\h -> h {Hotseat.news = Map.insertWith (flip (<>)) seat (Seq.singleton line) (Hotseat.news h)})
  where
    because reason = Text.pack $ case reason of
      Undoing.IllegalProposal -> " (a choice announced for it was illegal)"
      Undoing.UnpaidCost -> " (its cost was not paid)"
      Undoing.IllegalDeclaration -> " (it broke a restriction or requirement on attacking or blocking)"
      Undoing.RepeatedLoop -> " (it would repeat a loop, so a different choice is needed)"

-- | Asks the seat, handing the screen to it first.
asked :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerView.PlayerView -> Request.Request -> Client m R.Reply
asked terminal lookUp view request = do
  let question = Request.question request
      seat = Question.seat question
  handed <- handOff terminal seat
  first <- State.gets (Set.notMember seat . Hotseat.greeted)
  State.modify' (\h -> h {Hotseat.greeted = Set.insert seat (Hotseat.greeted h)})
  news <- tell handed seat
  mapM_ (say terminal) $
    [Text.empty]
      <> Render.board (Question.kind question `notElem` fmap Text.pack beforeFirstTurn) view
      <> news
      <> Render.hand view
      <> [Text.pack "Type card and a number from a list, or a card's name, to read that card." | first]
      <> foldMap (\p -> [Text.pack "That answer was refused: " <> p]) (Request.problem request)
  answer terminal lookUp seat view question

-- | CR 103.5-103.6: the questions asked before the first turn (CR 103.8).
beforeFirstTurn :: [String]
beforeFirstTurn = ["DeclareMulligan", "Bottom", "MulliganAction", "OpeningHandAction"]

-- | CR 104.3a's concession, quitting and reading a card are typed at any
-- question, and "auto" or an empty line at a mana source; everything else is
-- read by the question's own reader until it reads.
answer :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerId.PlayerId -> PlayerView.PlayerView -> Question.Question -> Client m R.Reply
answer terminal lookUp seat view question = case (Question.kind question, slotsOf question) of
  (kind, Just (source, slots)) | kind == Text.pack "ChooseTargets" -> fmap R.Array (mapM (target source (length slots > 1)) slots)
  _ -> ask (listedObjects view (Question.offer question)) (choice view question)
  where
    ask listed (shown, reader) = do
      mapM_ (say terminal) shown
      let loop = do
            typed <- fmap Text.strip (listen terminal)
            case Text.unpack typed of
              "quit" -> stop (Text.pack "quit")
              "concede" -> do
                State.modify' (\h -> h {Hotseat.conceding = Set.insert seat (Hotseat.conceding h)})
                say terminal (Text.pack "You concede at your next priority. Answer this question first.")
                loop
              _
                | Just wanted <- Text.stripPrefix (Text.pack "card") typed,
                  maybe True (Char.isSpace . fst) (Text.uncons wanted) -> do
                    either (stop . Text.pack . Exception.displayException) (mapM_ (say terminal)) (reading lookUp view listed (Text.strip wanted))
                    loop
              -- The rest of this payment, by autoSource.
              word
                | word `elem` ["auto", ""],
                  Question.kind question == Text.pack "ChooseManaSource" ->
                    autoPay seat view (Question.offer question) >>= \paid -> case paid of
                      Just (said, reply) -> say terminal said >> pure reply
                      Nothing -> refuse (Text.pack "Auto can't pay the rest of this cost. Choose a source.")
              _ -> case reader typed of
                Right reply -> pure reply
                Left problem -> do
                  -- A card's name the answer does not read shows that card.
                  found <- either (stop . Text.pack . Exception.displayException) pure (readingByName lookUp view typed)
                  if null found then refuse problem else mapM_ (say terminal) found >> loop
          refuse problem = mapM_ (say terminal) (problem : shown) >> loop
      loop
    -- A slot is named only to tell it from the spell's or ability's others.
    target source several (slot, wanted, offered) = do
      let legal = bySeat view offered
          n = min wanted (Natural.length legal)
          named = if several then foldMap (\t -> Text.pack " (" <> Render.spaced t <> Text.pack ")") (textOf slot) else Text.empty
          shown =
            Text.concat [Text.pack "Choose ", Render.count n "target", Text.pack " for ", objectName view source, named, Text.pack ":"]
              : numbered (fmap (recipientName view) legal)
      picked <- ask (fmap recipientObject legal) (shown, fmap R.Array . exactly n legal)
      pure (R.Array [slot, picked])

-- | What a question shows, and how a typed line is read into its answer.
choice :: PlayerView.PlayerView -> Question.Question -> ([Text.Text], Text.Text -> Either Text.Text R.Reply)
choice view question = Maybe.fromMaybe generic $ case Text.unpack (Question.kind question) of
  "ChooseAction" -> do
    shown <- fmap (distinct view) (arrayOf offer)
    let pass = List.find ((== Just (Text.pack "Pass")) . (field "action" Monad.>=> textOf) . snd) shown
    pure
      ( Text.pack (if Maybe.isJust pass then "Choose an action, or press Enter to pass:" else "Choose an action:") : numbered (fmap (actionName view . snd) shown),
        \typed -> case pass of
          Just (i, _) | Text.null typed -> Right (R.Number i)
          _ -> fmap (\i -> R.Number (maybe 0 fst (Maybe.listToMaybe (List.genericDrop (i - 1) shown)))) (one (Natural.length shown) typed)
      )
  "DeclareMulligan" -> do
    bottom <- field "bottom" offer >>= naturalOf
    pure
      ( [ Text.pack "Keep this hand, or mulligan? A mulligan puts " <> Render.count bottom "card" <> Text.pack " on the bottom.",
          Text.pack "  1. Keep",
          Text.pack "  2. Mulligan"
        ],
        fmap (\i -> R.Text (Text.pack (if i == 1 then "Keep" else "Mulligan"))) . one 2
      )
  "Bottom" -> pickCount "to put on the bottom of your library"
  -- CR 404.3: every card of the batch, top first; Enter keeps the order shown.
  "ArrangeGraveyardArrivals" -> do
    from <- field "from" offer >>= arrayOf
    let size = Natural.length from
        wrong = Text.pack ("Type each number from 1 to " <> show size <> " once, or press Enter.")
    pure
      ( Text.pack "These cards go to your graveyard together. Type their numbers from the new top down, separated by spaces, or press Enter to keep this order (top first):" : numbered (fmap (listedName view) from),
        \typed -> case numbers typed of
          Right [] -> Right R.Null
          Right picked | List.sort picked == [1 .. size] -> Right (R.Array (fmap (R.Number . toInteger . subtract 1) picked))
          _ -> Left wrong
      )
  "ChooseDiscard" -> pickCount "to discard"
  "DeclareAttackers" -> do
    attackers <- arrayOf offer
    pure
      ( Text.pack "Choose attackers by number or range such as 1-3, separated by spaces, all, or press Enter for none:" : numbered (fmap (listedName view) attackers),
        fmap R.Array . some attackers
      )
  "DeclareBlockers" -> do
    blockers <- field "blockers" offer >>= arrayOf
    attackers <- field "attackers" offer >>= arrayOf
    pure
      ( [Text.pack "Attacking:"]
          <> numbered (fmap (listedName view) attackers)
          <> [Text.pack "Your creatures that can block:"]
          <> numbered (fmap (listedName view) blockers)
          <> [Text.pack "Type blocker:attacker pairs, such as 1:2, separated by spaces, or press Enter for no blocks:"],
        blocks blockers attackers
      )
  "ChooseManaSource" -> do
    cost <- field "cost" offer >>= decoded Codec.ManaCost.codec
    let pool = foldMap (fmap ManaUnit.manaType . Mana.unwrap . SeatView.manaPool) (payerSeat view offer)
        held = foldMap (\t -> Text.pack "{" <> Render.manaType t <> Text.pack "}") pool
        left = foldMap (\(colored, rest) -> Text.pack ", leaving " <> Render.manaCost (ManaCost.MkManaCost ([ManaSymbol.Generic rest | rest > 0] <> fmap ManaSymbol.OfType colored))) (owing view offer)
        progress = if null pool then Text.empty else Text.pack " with " <> held <> Text.pack " in the pool" <> left
        substitutes = foldMap (Foldable.foldMap (Maybe.maybeToList . Maybe.listToMaybe . Oracle.Keyword.keywordWord Text.empty)) (field "substitutes" offer >>= decoded (Common.list Codec.Keyword.codec))
        -- CR 601.2g-h: the substitution is asked once the mana window closes.
        later = if null substitutes then Text.empty else Text.pack ". After the mana, " <> Text.intercalate (Text.pack " or ") substitutes <> Text.pack " can pay part of it"
    sourcePick (Text.pack "Paying " <> Render.manaCost cost <> progress <> later <> Text.pack ". Choose a source to pay with, stop to stop paying, or auto (or press Enter) to pay the rest:") (Text.pack "stop") (Text.pack ", stop, or auto")
  -- CR 601.2g: mana abilities are activated before the cost is paid.
  "ChooseExtraManaSource" -> sourcePick (Text.pack "The cost is covered. Choose another source to activate, or press Enter to pay now:") Text.empty (Text.pack ", or press Enter to pay now")
  -- CR 734.1: whether the mana abilities of one activation are reversed too.
  "ReverseManaAbilities" -> do
    sources <- field "sources" offer >>= arrayOf
    pure
      ( [Text.pack "That action was reversed. Reverse the mana ability of " <> Text.intercalate (Text.pack " and ") (fmap (listedName view) sources) <> Text.pack " too?", Text.pack "  1. Yes", Text.pack "  2. No"],
        fmap (\i -> optionalDecision (if i == 1 then OptionalDecision.Exercises else OptionalDecision.Declines)) . one 2
      )
  -- CR 601.2b / 702.51a: each candidate as Oracle text prints its cost.
  "ChooseCost" -> do
    source <- field "source" offer
    costs <- field "costs" offer >>= arrayOf
    let self = objectName view source
    pure
      ( Text.pack "Choose how to pay for " <> self <> Text.pack ":" : numbered (fmap (candidateName self) costs),
        fmap (R.Number . toInteger . subtract 1) . one (Natural.length costs)
      )
  -- CR 201.4: any card's name, typed in full; one the rules refuse is asked
  -- again (Parun.Play.Game.consulting).
  "ChooseCardName" ->
    pure
      ( [Text.pack "Choose a card name: type the name of a card."],
        \typed -> if Text.null typed then Left (Text.pack "Type the name of a card.") else Right (R.Text typed)
      )
  "ChooseManaYield" -> do
    source <- field "source" offer
    yields <- field "yields" offer >>= decoded (Common.list (Common.list Codec.ManaType.codec))
    pure
      ( Text.pack "Choose the mana " <> objectName view source <> Text.pack " makes:" : numbered (fmap (foldMap Render.manaType) yields),
        fmap (R.Number . toInteger . subtract 1) . one (Natural.length yields)
      )
  "ChooseManaSpentOnX" -> do
    source <- field "source" offer
    shares <- field "shares" offer >>= decoded (Common.list (Common.list Codec.ManaType.codec))
    pure
      ( Text.pack "Choose the mana you spent on X for " <> objectName view source <> Text.pack ":" : numbered (fmap (foldMap Render.manaType) shares),
        fmap (R.Number . toInteger . subtract 1) . one (Natural.length shares)
      )
  "ChooseX" -> do
    source <- field "source" offer
    variable <- field "variable" offer >>= textOf
    least <- field "least" offer >>= naturalOf
    greatest <- field "greatest" offer >>= naturalOf
    pure (ranged (Text.concat [Text.pack "Choose ", variable, Text.pack " for ", objectName view source]) least Text.empty (Just greatest))
  -- CR 608.2d: a bid's least is the high bid, which answering declines to top.
  "ChooseNumber" -> do
    source <- field "source" offer
    least <- field "least" offer >>= naturalOf
    meaning <- field "floor" offer >>= decoded Codec.NumberFloor.codec
    let note = if meaning == NumberFloor.HighBid then Text.pack ("; " <> show least <> " lets the high bid stand") else Text.empty
    pure (ranged (Text.pack "Choose a number for " <> objectName view source) least note (field "greatest" offer >>= naturalOf))
  "ChooseOptional" -> do
    source <- field "source" offer
    pure
      ( [objectName view source <> Text.pack ": use its optional effect?", Text.pack "  1. Yes", Text.pack "  2. No"],
        fmap (\i -> optionalDecision (if i == 1 then OptionalDecision.Exercises else OptionalDecision.Declines)) . one 2
      )
  -- CR 116.2c / 605.3a: Channel's life for mana, inside a payment.
  "PayLifeForMana" -> do
    life <- field "life" offer >>= naturalOf
    mana <- field "mana" offer >>= decoded Codec.ManaType.codec
    pure
      ( [Text.pack ("Pay " <> show life <> " life to add ") <> Render.manaType mana <> Text.pack "?", Text.pack "  1. Yes", Text.pack "  2. No"],
        fmap (\i -> optionalDecision (if i == 1 then OptionalDecision.Exercises else OptionalDecision.Declines)) . one 2
      )
  -- CR 510.1b-c: whether the creature assigns its damage as its option allows.
  "ChooseCombatDamageOption" -> do
    source <- field "source" offer
    option <- field "option" offer >>= decoded Codec.CombatDamageOption.codec
    let wording = if option == CombatDamageOption.AsThoughUnblocked then Text.pack ": assign its combat damage as though it weren't blocked?" else Text.pack ": assign its combat damage to a creature the defending player controls?"
    pure
      ( [objectName view source <> wording, Text.pack "  1. Yes", Text.pack "  2. No"],
        fmap (\i -> optionalDecision (if i == 1 then OptionalDecision.Exercises else OptionalDecision.Declines)) . one 2
      )
  -- CR 510.1c-d: one amount per recipient, in the order offered.
  "AssignCombatDamage" -> do
    source <- field "source" offer
    lethal <- field "lethal" offer >>= arrayOf >>= mapM entryOf
    total <- field "total" offer >>= naturalOf
    let needs threshold = if threshold > 0 then Text.pack (" (lethal " <> show threshold <> ")") else Text.empty
        wrong = Text.pack ("Type " <> show (length lethal) <> " amounts that add up to " <> show total <> ".")
    pure
      ( Text.concat [Text.pack "Divide ", objectName view source, Text.pack ("'s " <> show total <> " damage, one amount each, separated by spaces:")]
          : numbered (fmap (\(recipient, threshold) -> recipientName view recipient <> needs threshold) lethal),
        \typed -> case numbers typed of
          Right amounts
            | length amounts == length lethal && sum amounts == total ->
                Right (R.Array [R.Array [recipient, R.Number (toInteger amount)] | ((recipient, _), amount) <- zip lethal amounts, amount > 0])
          _ -> Left wrong
      )
  -- CR 601.2d / 115.7f: one amount per target, in the order offered.
  "ChooseDivision" -> do
    source <- field "source" offer
    targets <- field "targets" offer >>= arrayOf
    let fixed = field "parts" offer >>= arrayOf >>= mapM naturalOf
    total <- maybe (field "total" offer >>= naturalOf) (Just . sum) fixed
    let wrong = Text.pack ("Type " <> show (length targets) <> " amounts of at least 1 that add up to " <> show total <> maybe "" (\parts -> ", using exactly " <> unwords (fmap show parts)) fixed <> ".")
        fits amounts = length amounts == length targets && all (>= 1) amounts && sum amounts == total && all ((== List.sort amounts) . List.sort) fixed
    pure
      ( Text.concat [Text.pack "Divide ", objectName view source, Text.pack ("'s " <> show total <> ", one amount per target, separated by spaces:")]
          : numbered (fmap (recipientName view) targets),
        \typed -> case numbers typed of
          Right amounts | fits amounts -> Right (R.Array [R.Array [recipient, R.Number (toInteger amount)] | (recipient, amount) <- zip targets amounts])
          _ -> Left wrong
      )
  -- CR 603.3b / 101.4c: first to last, the first named going on the stack
  -- first; Enter keeps the order shown.
  "OrderTriggers" -> do
    entries <- arrayOf offer
    pure (ordered (Text.pack "Order your triggered abilities: type their numbers first to last, separated by spaces, or press Enter to keep this order. On the stack, the last resolves first:") (fmap (triggerName view) entries))
  -- CR 601.2h: each component as Oracle text prints it, the first paid first.
  "OrderCostComponents" -> do
    source <- field "source" offer
    components <- field "order" offer >>= arrayOf
    let self = objectName view source
    pure (ordered (orderHeading (Text.pack " for " <> self) (Text.pack "the first is paid first")) (fmap (componentName self) components))
  -- CR 601.2h: the pool's unit that pays the next symbol, sent back whole.
  "ChooseManaToSpend" -> do
    units <- arrayOf offer
    shown <- mapM (decoded Codec.ManaUnit.codec) units
    pure
      ( Text.pack "Choose the mana to spend:" : numbered (fmap unitName shown),
        fmap (pickFrom units) . one (Natural.length units)
      )
  -- CR 701.23b: up to the count, which may be none.
  "Search" -> do
    from <- field "from" offer >>= arrayOf
    names <- field "names" offer >>= arrayOf >>= mapM textOf
    wanted <- field "count" offer >>= naturalOf
    let n = min wanted (Natural.length from)
    pure
      ( Text.pack "Choose up to " <> Render.count n "card" <> Text.pack " to find, by number or range such as 1-3, separated by spaces, or press Enter for none:" : numbered names,
        \typed -> do
          picked <- some from typed
          if Natural.length picked <= n then Right (R.Array picked) else Left (Text.pack ("Choose at most " <> show n <> "."))
      )
  -- An order over what the offer lists, sent back as a permutation of its
  -- indices.
  _
    | Just items <- field "order" offer >>= arrayOf ->
        pure (ordered (orderHeading (foldMap (\source -> Text.pack " for " <> objectName view source) (field "source" offer)) (orderNote (Question.kind question) offer)) (fmap (optionName view) items))
  -- One of what the offer lists, sent back as the answer it already is.
  _ -> do
    (options, name) <- Monad.mplus (fmap (\o -> (o, optionName view)) (field "options" offer >>= arrayOf)) (fmap (\o -> (o, playerName)) (field "players" offer >>= arrayOf))
    pure
      ( kindHeading <> foldMap (\source -> Text.pack " for " <> objectName view source) (field "source" offer) <> Text.pack ":" : numbered (fmap name options),
        fmap (pickFrom options) . one (Natural.length options)
      )
  where
    offer = Question.offer question
    -- A number from least to greatest, or from least up with no greatest.
    ranged heading least note greatest =
      let range = maybe ("at least " <> show least) (\most -> "from " <> show least <> " to " <> show most) greatest
       in ( [heading <> Text.pack (", " <> range) <> note <> Text.pack ":"],
            \typed -> case Read.readMaybe (Text.unpack (Text.strip typed)) of
              Just n | least <= n && all (n <=) greatest -> Right (R.Number (toInteger n))
              _ -> Left (Text.pack ("Type a number " <> maybe "of " (const "") greatest <> range <> "."))
          )
    -- A source by number, or the line `none` for no source.
    sourcePick heading none others = do
      offered <- field "sources" offer >>= arrayOf >>= mapM manaSource
      let sources = fmap fst offered
          makes yields = if null yields then Text.empty else Text.pack " (makes " <> Text.intercalate (Text.pack " or ") (fmap (foldMap Render.manaType) yields) <> Text.pack ")"
      pure
        ( heading : numbered (fmap (\(source, yields) -> listedName view source <> makes yields) offered),
          \typed ->
            if Text.toCaseFold typed == none
              then Right R.Null
              else either (const (Left (Text.pack ("Type one number from 1 to " <> show (Natural.length sources)) <> others <> Text.pack "."))) (Right . pickFrom sources) (one (Natural.length sources) typed)
        )
    -- The prompt's kind as words, capitalized.
    kindHeading = case Text.uncons (Render.spaced (Question.kind question)) of
      Just (c, rest) -> Text.cons (Char.toUpper c) rest
      Nothing -> Text.empty
    orderHeading for note = Text.concat [kindHeading, for, Text.pack ": type their numbers first to last, separated by spaces, or press Enter to keep this order; ", note, Text.pack ":"]
    pickCount purpose = do
      from <- field "from" offer >>= arrayOf
      wanted <- field "count" offer >>= naturalOf
      let n = min wanted (Natural.length from)
      pure
        ( Text.pack "Choose " <> Render.count n "card" <> Text.pack (" " <> purpose <> ", by number or range such as 1-3, separated by spaces:") : numbered (fmap (listedName view) from),
          fmap R.Array . exactly n from
        )
    generic =
      ( [Render.spaced (Question.kind question) <> Text.pack ":"]
          <> [Common.render (Codec.Reply.toValue offer) | offer /= R.Null]
          <> [Text.pack "Type the answer as JSON:"],
        Common.parse Monad.>=> Codec.Reply.fromValue
      )

-- | What "card" followed by a number from the question's list, or by a name,
-- shows: each object of the view it names, in full. Only what the view shows
-- is read, so a card the seat may not see is never found. Left when the card
-- data could not say, which stops play.
reading :: (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerView.PlayerView -> [Maybe ObjectId.ObjectId] -> Text.Text -> Either InvalidCorpus.InvalidCorpus [Text.Text]
reading lookUp view listed wanted
  | Text.null wanted = Right [Text.pack "Type card and a number from a list, or a card's name."]
  | Right [i] <- numbers wanted = case Monad.join (Maybe.listToMaybe (List.genericDrop (pred (max 1 i)) listed)) >>= (`Map.lookup` Render.objects view) of
      Just o | i >= 1 -> Render.details lookUp view o
      _ -> Right [Text.pack ("Number " <> show i <> " in this list is not a card you can see.")]
  | otherwise =
      flip fmap (readingByName lookUp view wanted) $ \found ->
        if null found then [Text.pack "No card you can see is named " <> wanted <> Text.pack "."] else found

-- | Each object of the view named this, ignoring case, in full; none when
-- no card the seat can see is.
readingByName :: (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerView.PlayerView -> Text.Text -> Either InvalidCorpus.InvalidCorpus [Text.Text]
readingByName lookUp view wanted =
  fmap (List.intercalate [Text.empty] . ListUtils.nubOrd) (traverse (Render.details lookUp view) (filter matches (Map.elems (Render.objects view))))
  where
    matches = any ((== Text.toCaseFold (Text.strip wanted)) . Text.toCaseFold . CardName.unwrap) . Set.toList . Render.cardNames

-- | The object behind each numbered option of an offer, where it names one:
-- the offer's own list, the cards, sources or options it chooses from, or
-- what it orders.
listedObjects :: PlayerView.PlayerView -> R.Reply -> [Maybe ObjectId.ObjectId]
listedObjects view offer = foldMap (fmap optionObject) (Monad.msum [fmap (fmap snd . distinct view) (arrayOf offer), field "from" offer >>= arrayOf, field "sources" offer >>= arrayOf, field "options" offer >>= arrayOf, field "order" offer >>= arrayOf])
  where
    optionObject option = Monad.msum [objectOf option, field "object" option >>= objectOf, field "source" option >>= objectOf]

-- | A list's options as shown, each beside its index in the list: an option
-- is dropped when an earlier one plays or casts a card in the seat's hand
-- that the view shows exactly as it shows this one's, bar its id. Other
-- actions never merge, since an offer may leave out what tells two apart
-- (#5225), and neither do cards elsewhere, which a permission may tell
-- apart.
distinct :: PlayerView.PlayerView -> [R.Reply] -> [(Integer, R.Reply)]
distinct view = reverse . snd . List.foldl' keep ([], []) . zip [0 ..]
  where
    keep (keys, kept) (i, option) = case key option of
      Just k | k `elem` keys -> (keys, kept)
      k -> (maybe keys (: keys) k, (i, option) : kept)
    held = Map.fromList [(ObjectView.object o, o) | s <- PlayerView.seats view, SeatView.player s == PlayerView.viewer view, o <- SeatView.hand s]
    key option = do
      kind <- field "action" option >>= textOf
      Monad.guard (kind `elem` [Text.pack "Play", Text.pack "Cast"])
      o <- field "object" option >>= objectOf >>= (`Map.lookup` held)
      R.Object pairs <- Just option
      pure (filter ((/= Text.pack "object") . fst) pairs, o {ObjectView.object = ObjectId.MkObjectId 0})

-- | Recipients grouped by seat, the deciding seat's first, each seat's
-- player ahead of its objects, and otherwise in the offer's order.
bySeat :: PlayerView.PlayerView -> [R.Reply] -> [R.Reply]
bySeat view = List.sortOn key
  where
    key reply =
      let pid = maybe (recipientPlayer reply) (Render.seatOf view) (recipientObject reply)
       in (Maybe.isNothing pid, fmap (\p -> (p /= PlayerView.viewer view, p)) pid, Maybe.isJust (recipientObject reply))

-- | The player a recipient names, if it is one.
recipientPlayer :: R.Reply -> Maybe PlayerId.PlayerId
recipientPlayer reply = case reply of
  R.Array [R.Text tag, R.Text x] | tag == Text.pack "Player" -> fmap PlayerId.MkPlayerId (Read.readMaybe (Text.unpack x))
  _ -> Nothing

-- | The object a recipient names, if it is not a player.
recipientObject :: R.Reply -> Maybe ObjectId.ObjectId
recipientObject reply = case reply of
  R.Array [R.Text tag, x] | tag /= Text.pack "Player" -> objectOf x
  _ -> Nothing

-- | What to say, and the answer the seat opted into ahead of the question,
-- if any: passing a priority that offers nothing but passing and
-- mana abilities, and the rest of a payment the seat chose auto at. A
-- payment's other prompts and a refused answer end "auto", and a refused
-- answer is always asked. A priority is passed for only the seat the screen
-- faces: another seat is handed the screen and asked, whatever it holds, so
-- neither a hand-off nor a line tells the table it had nothing else to do.
unasked :: (Monad m) => PlayerView.PlayerView -> Request.Request -> Client m ([Text.Text], Maybe R.Reply)
unasked view request = do
  let question = Request.question request
      seat = Question.seat question
      offer = Question.offer question
      kind = Text.unpack (Question.kind question)
      refused = Maybe.isJust (Request.problem request)
  hotseat <- State.get
  let paying = Map.lookup seat (Hotseat.paying hotseat)
  Monad.when (refused || kind `notElem` ["ChooseManaSource", "ChooseExtraManaSource", "PayLifeForMana", "ChooseManaYield", "ChooseManaToSpend"]) (stopPaying seat)
  case kind of
    _ | refused -> pure ([], Nothing)
    "ChooseAction"
      | Hotseat.autoPass hotseat,
        Hotseat.facing hotseat == Just seat,
        Just pass <- onlyPass offer ->
          let active = PlayerView.active view
              whose = if active == seat then Text.pack "their " else Render.player active <> Text.pack "'s "
           in pure ([Render.player seat <> Text.pack " passes in " <> whose <> Render.phase (PlayerView.phase view) <> Text.pack " (no other actions)."], Just (R.Number pass))
    "ChooseManaSource"
      | Maybe.isJust paying ->
          autoPay seat view offer >>= \paid -> case paid of
            Just (said, reply) -> pure ([said], Just reply)
            Nothing -> stopPaying seat >> pure ([Text.pack "Auto can't pay the rest of this cost."], Nothing)
    -- CR 605.3b: the mana the source was tapped for.
    "ChooseManaYield"
      | Just wanted <- paying,
        Just yields <- field "yields" offer >>= decoded (Common.list (Common.list Codec.ManaType.codec)),
        (i, yield) : _ <- filter (\(_, yield) -> Set.null wanted || not (Set.disjoint wanted (Set.fromList yield))) (zip [0 :: Integer ..] yields) ->
          pure ([Text.pack "Auto takes " <> foldMap Render.manaType yield <> Text.pack "."], Just (R.Number i))
    -- CR 116.2c: auto taps sources; it never spends the seat's life.
    "PayLifeForMana" | Maybe.isJust paying -> pure ([], Just (optionalDecision OptionalDecision.Declines))
    -- CR 605.3a: auto never floats mana past the cost.
    "ChooseExtraManaSource" | Maybe.isJust paying -> stopPaying seat >> pure ([], Just R.Null)
    _ -> pure ([], Nothing)

-- | Auto's next source for the seat, and the line saying so, remembering the
-- colors the source is tapped for.
autoPay :: (Monad m) => PlayerId.PlayerId -> PlayerView.PlayerView -> R.Reply -> Client m (Maybe (Text.Text, R.Reply))
autoPay seat view offer = case autoSource view offer of
  Nothing -> pure Nothing
  Just (source, wanted) -> do
    State.modify' (\h -> h {Hotseat.paying = Map.insert seat wanted (Hotseat.paying h)})
    pure (Just (Text.pack "Auto pays with " <> objectName view source <> Text.pack ".", source))

stopPaying :: (Monad m) => PlayerId.PlayerId -> Client m ()
stopPaying seat = State.modify' (\h -> h {Hotseat.paying = Map.delete seat (Hotseat.paying h)})

-- | Where Pass sits in a ChooseAction offer whose every other action is a
-- mana ability (CR 605.3a), which the text client does not ask about.
onlyPass :: R.Reply -> Maybe Integer
onlyPass offer = do
  kinds <- arrayOf offer >>= mapM (field "action" Monad.>=> textOf)
  Monad.guard (all (`elem` [Text.pack "Pass", Text.pack "ActivateManaAbility"]) kinds)
  fmap toInteger (List.elemIndex (Text.pack "Pass") kinds)

-- | CR 601.2g: the next source auto taps, and the colors it is tapped for
-- (none for generic mana). The payer's pool goes first against the cost; then
-- each colored symbol still owed is paid from the source that makes the
-- fewest of the colors still owed, then generic mana from the source that
-- makes the fewest types. Nothing when the cost holds a symbol other than
-- generic or one type of mana, when the pool already covers it, or when no
-- source makes what is still owed.
autoSource :: PlayerView.PlayerView -> R.Reply -> Maybe (R.Reply, Set.Set ManaType.ManaType)
autoSource view offer = do
  (colored, generic) <- owing view offer
  sources <- field "sources" offer >>= arrayOf >>= mapM manaSource
  let wanted = Set.fromList colored
      makes (_, yields) = Set.fromList (concat yields)
      fewest by = Maybe.listToMaybe . List.sortOn by
  source <-
    if not (Set.null wanted)
      then fewest (\s -> (Set.size (Set.intersection wanted (makes s)), Set.size (makes s))) (filter (not . Set.disjoint wanted . makes) sources)
      else
        if generic > 0
          then fewest (Set.size . makes) (filter (not . Set.null . makes) sources)
          else Nothing
  pure (fst source, Set.intersection wanted (makes source))

-- | CR 601.2g-h: what of a ChooseManaSource offer's cost the payer's pool leaves
-- owed: each colored symbol the pool cannot pay, the generic mana the rest of
-- the pool does not cover. Nothing when the cost holds a symbol other than
-- generic or one type of mana.
owing :: PlayerView.PlayerView -> R.Reply -> Maybe ([ManaType.ManaType], Natural)
owing view offer = do
  cost <- field "cost" offer >>= decoded Codec.ManaCost.codec
  owed <- mapM owedOf (ManaCost.unwrap cost)
  let pool = foldMap (fmap ManaUnit.manaType . Mana.unwrap . SeatView.manaPool) (payerSeat view offer)
      (colored, unspent) = List.foldl' spendOne ([], pool) (Either.rights owed)
      generic = sum (Either.lefts owed)
  pure (colored, generic - min generic (Natural.length unspent))
  where
    owedOf symbol = case symbol of
      ManaSymbol.Generic n -> Just (Left n)
      ManaSymbol.OfType t -> Just (Right t)
      _ -> Nothing
    spendOne (still, pool) t = case List.elemIndex t pool of
      Just i -> (still, take i pool <> drop (i + 1) pool)
      Nothing -> (still <> [t], pool)

-- | The seat of a payment offer's payer.
payerSeat :: PlayerView.PlayerView -> R.Reply -> Maybe SeatView.SeatView
payerSeat view offer = do
  payer <- field "payer" offer >>= textOf >>= Read.readMaybe . Text.unpack
  List.find ((== PlayerId.MkPlayerId payer) . SeatView.player) (PlayerView.seats view)

-- | A ChooseCost candidate's cost as Oracle text prints it (Oracle.Cost.cost),
-- or the offer itself where it does not print.
candidateName :: Text.Text -> R.Reply -> Text.Text
candidateName self candidate =
  Maybe.fromMaybe (Common.render (Codec.Reply.toValue candidate)) (decoded (Codec.Cost.codec Codec.Keyword.codec) candidate >>= Maybe.listToMaybe . Oracle.Cost.cost self (Oracle.Keyword.keywordWord self))

-- | An order over the items shown, answered by their numbers first to last,
-- each once, or by Enter for the order shown; sent back as a permutation of
-- their indices (Parun.Engine.Game.permute).
ordered :: Text.Text -> [Text.Text] -> ([Text.Text], Text.Text -> Either Text.Text R.Reply)
ordered heading names =
  ( heading : numbered names,
    \typed -> case numbers typed of
      Right [] -> Right (R.Array (fmap (R.Number . toInteger) [0 .. size - 1]))
      Right picked | List.sort picked == [1 .. size] -> Right (R.Array (fmap (R.Number . toInteger . subtract 1) picked))
      _ -> Left (Text.pack ("Type each number from 1 to " <> show size <> " once, or press Enter."))
  )
  where
    size = Natural.length names

-- | What the first item of an order is, by the prompt's kind and what its
-- offer tells.
orderNote :: Text.Text -> R.Reply -> Text.Text
orderNote kind offer = case Text.unpack kind of
  -- CR 401.4: from the top inward.
  "ArrangeLibraryCards" -> Text.pack "the first goes on top"
  "ArrangeLibraryArrivals" -> case field "end" offer of
    Just (R.Text end) | end == Text.pack "Top" -> Text.pack "the first goes on top"
    _ -> Text.pack "the first goes on the bottom"
  -- CR 613.7m.
  "OrderTimestamps" -> Text.pack "the first gets the earliest timestamp"
  "OrderManaActivations" -> Text.pack "the first is activated first"
  "OrderCombatTolls" -> Text.pack "the first is paid first"
  -- CR 713.8a.
  "OrderComponentCards" -> Text.pack "the first goes into " <> maybe (Text.pack "the zone") Render.zone (field "zone" offer >>= decoded Codec.Zone.codec) <> Text.pack " first"
  _ -> Text.pack "the first goes first"

-- | A cost component as Oracle text prints it (Oracle.Cost.component), or the
-- offer itself where it does not print.
componentName :: Text.Text -> R.Reply -> Text.Text
componentName self component =
  Maybe.fromMaybe (Common.render (Codec.Reply.toValue component)) (decoded (Codec.CostComponent.codec Codec.Keyword.codec) component >>= Maybe.listToMaybe . Oracle.Cost.component self (Oracle.Keyword.keywordWord self))

-- | A trigger ordering's entry: its source, and its Oracle text where the
-- offer carries it.
triggerName :: PlayerView.PlayerView -> R.Reply -> Text.Text
triggerName view entry =
  let source = maybe (Text.pack "A rule") (objectName view) (Monad.mfilter (/= R.Null) (field "source" entry))
   in maybe (source <> Text.pack "'s triggered ability") (\text -> source <> Text.pack ": " <> text) (field "text" entry >>= textOf)

-- | A unit of mana in the pool: its type, and what sets it apart from others
-- of its type (CR 106.6, 106.4, 107.4h).
unitName :: ManaUnit.ManaUnit -> Text.Text
unitName unit =
  let notes =
        [Text.pack "from a snow source" | Set.member ProductionTag.Snow (ManaUnit.tags unit)]
          <> [Text.pack "from a Treasure" | Set.member ProductionTag.Treasure (ManaUnit.tags unit)]
          <> [Text.pack "from an artifact" | Set.member ProductionTag.Artifact (ManaUnit.tags unit)]
          <> [Text.pack "kept until end of turn" | ManaUnit.retention unit == ManaRetention.UntilEndOfTurn]
          <> [Text.pack "kept until end of combat" | ManaUnit.retention unit == ManaRetention.UntilEndOfCombat]
          <> [Text.pack "restricted" | Maybe.isJust (ManaUnit.restriction unit)]
          <> [Text.pack "with an effect when spent" | Maybe.isJust (ManaUnit.rider unit) || Maybe.isJust (ManaUnit.spendTrigger unit)]
   in Text.pack "{" <> Render.manaType (ManaUnit.manaType unit) <> Text.pack "}" <> (if null notes then Text.empty else Text.pack " (" <> Text.intercalate (Text.pack ", ") notes <> Text.pack ")")

-- | A mana source as an offer names it, beside the mana types of each yield.
manaSource :: R.Reply -> Maybe (R.Reply, [[ManaType.ManaType]])
manaSource reply = do
  source <- field "source" reply
  makes <- field "makes" reply >>= decoded (Common.list (Common.list Codec.ManaType.codec))
  pure (source, makes)

-- | An optional prompt's answer, a bare tag (Parun.JsonCodec.Arm.enum).
optionalDecision :: OptionalDecision.OptionalDecision -> R.Reply
optionalDecision = R.Text . Text.pack . show

decoded :: Codec.Codec a -> R.Reply -> Maybe a
decoded codec = either (const Nothing) Just . Codec.decode codec . Codec.Reply.toValue

-- | One number from 1 to n.
one :: Natural -> Text.Text -> Either Text.Text Natural
one n typed = case numbers typed of
  Right [i] | i >= 1 && i <= n -> Right i
  _ -> Left (Text.pack ("Type one number from 1 to " <> show n <> "."))

-- | Exactly n different options, by number.
exactly :: Natural -> [R.Reply] -> Text.Text -> Either Text.Text [R.Reply]
exactly n options typed = do
  picked <- some options typed
  if Natural.length picked == n then Right picked else Left (Text.pack ("Choose exactly " <> show n <> "."))

-- | Any number of different options, by number, by a range such as 1-3, or
-- all of them.
some :: [R.Reply] -> Text.Text -> Either Text.Text [R.Reply]
some options typed = do
  let size = Natural.length options
      range word = case Text.splitOn (Text.pack "-") word of
        _ | Text.toCaseFold word == Text.pack "all" -> Just [1 .. size]
        [from, to] -> do
          a <- digits from
          b <- digits to
          Monad.guard (a <= b)
          pure [a .. b]
        _ -> fmap pure (digits word)
      digits t = if not (Text.null t) && Text.all Char.isDigit t then Read.readMaybe (Text.unpack t) else Nothing
  is <- maybe (Left (Text.pack "Type numbers or ranges such as 1-3, separated by spaces, or all.")) (Right . concat) (mapM range (Text.words typed))
  Monad.unless (all (\i -> i >= 1 && i <= size) is) (Left (Text.pack ("Each number must be from 1 to " <> show size <> ".")))
  Monad.unless (ListUtils.nubOrd is == is) (Left (Text.pack "Choose each one at most once."))
  pure (fmap (pickFrom options) is)

-- | CR 509.1a: blocker:attacker pairs, a blocker naming each attacker it blocks.
blocks :: [R.Reply] -> [R.Reply] -> Text.Text -> Either Text.Text R.Reply
blocks blockers attackers typed = do
  pairs <- mapM pairOf (Text.words typed)
  let grouped = Map.fromListWith (flip (<>)) (fmap (\(b, a) -> (b, [a])) pairs)
  pure (R.Array (fmap (\(b, as) -> R.Array [pickFrom blockers b, R.Array (fmap (pickFrom attackers) (ListUtils.nubOrd as))]) (Map.toList grouped)))
  where
    pairOf word = case Text.splitOn (Text.pack ":") word of
      [b, a]
        | Right [bi] <- numbers b,
          Right [ai] <- numbers a,
          bi >= 1 && bi <= Natural.length blockers && ai >= 1 && ai <= Natural.length attackers ->
            Right (bi, ai)
      _ -> Left (Text.pack "Type each block as blocker:attacker, such as 1:2.")

numbers :: Text.Text -> Either Text.Text [Natural]
numbers typed = maybe (Left (Text.pack "Type numbers separated by spaces.")) Right (mapM (Read.readMaybe . Text.unpack) (Text.words typed))

pickFrom :: [R.Reply] -> Natural -> R.Reply
pickFrom options i = Maybe.fromMaybe R.Null (Maybe.listToMaybe (List.genericDrop (i - 1) options))

numbered :: [Text.Text] -> [Text.Text]
numbered = zipWith (\i t -> Text.pack ("  " <> show i <> ". ") <> t) [1 :: Natural ..]

-- | An action as the offer names it.
actionName :: PlayerView.PlayerView -> R.Reply -> Text.Text
actionName view action =
  let object = fmap (objectName view) (field "object" action)
      name = field "name" action >>= textOf
      subject = Maybe.fromMaybe Text.empty (Monad.mplus name object)
   in case maybe "" Text.unpack (field "action" action >>= textOf) of
        "Pass" -> Text.pack "Pass"
        "Play" -> Text.pack "Play " <> subject
        "Cast" -> Text.pack "Cast " <> subject
        "Activate" -> maybe (Text.pack "Activate an ability of ") (\i -> Text.pack ("Activate ability " <> show (i + 1) <> " of ")) (field "ability" action >>= naturalOf) <> subject
        "ActivateManaAbility" -> Text.pack "Activate a mana ability of " <> subject
        kind -> Render.spaced (Text.pack kind) <> maybe Text.empty (Text.pack " " <>) object

-- | An object the offer spells @"$7"@, named as the view shows it.
objectName :: PlayerView.PlayerView -> R.Reply -> Text.Text
objectName view reply = maybe (Text.pack "something") (Render.named view) (objectOf reply)

-- | An object an offer lists, told apart from others of its name.
listedName :: PlayerView.PlayerView -> R.Reply -> Text.Text
listedName view reply = maybe (Text.pack "something") (Render.choosable view) (objectOf reply)

-- | An option of a listed offer: an object as listedName names it, a
-- recipient or attack target as recipientName does, declining as None, and a
-- word or number as itself.
optionName :: PlayerView.PlayerView -> R.Reply -> Text.Text
optionName view reply = case reply of
  R.Null -> Text.pack "None"
  R.Number n -> Text.pack (show n)
  R.Text t -> if Maybe.isJust (objectOf reply) then listedName view reply else t
  R.Array [R.Text tag, _] | tag `elem` fmap Text.pack ["Player", "Planeswalker", "Battle"] -> recipientName view reply
  R.Array xs -> Text.intercalate (Text.pack ", ") (fmap (optionName view) xs)
  -- A damage event (Parun.Play.Protocol.damageEvent).
  R.Object _
    | Just source <- field "source" reply,
      Just target <- field "target" reply,
      Just amount <- field "amount" reply >>= naturalOf ->
        Text.concat [objectName view source, Text.pack (" deals " <> show amount <> " damage to "), recipientName view target]
  _ -> Common.render (Codec.Reply.toValue reply)

-- | A seat a listed offer names by its bare id, or declining as None.
playerName :: R.Reply -> Text.Text
playerName reply = case reply of
  R.Text x -> maybe x (Render.player . PlayerId.MkPlayerId) (Read.readMaybe (Text.unpack x))
  _ -> Text.pack "None"

recipientName :: PlayerView.PlayerView -> R.Reply -> Text.Text
recipientName view reply = case reply of
  R.Array [R.Text tag, R.Text x]
    | tag == Text.pack "Player" -> maybe x (Render.player . PlayerId.MkPlayerId) (Read.readMaybe (Text.unpack x))
    | otherwise -> listedName view (R.Text x)
  _ -> Text.pack "something"

objectOf :: R.Reply -> Maybe ObjectId.ObjectId
objectOf reply = do
  t <- textOf reply
  digits <- Text.stripPrefix (Text.pack "$") t
  fmap ObjectId.MkObjectId (Read.readMaybe (Text.unpack digits))

-- | A ChooseTargets offer's source and its slots: name, how many, and the
-- legal recipients.
slotsOf :: Question.Question -> Maybe (R.Reply, [(R.Reply, Natural, [R.Reply])])
slotsOf question = do
  let offer = Question.offer question
  source <- field "source" offer
  slots <- field "slots" offer >>= arrayOf
  parsed <- Monad.forM slots $ \slot -> case slot of
    R.Array [name, R.Array [wanted, R.Array legal]] -> fmap (\n -> (name, n, legal)) (naturalOf wanted)
    _ -> Nothing
  pure (source, parsed)

field :: String -> R.Reply -> Maybe R.Reply
field key reply = case reply of
  R.Object pairs -> List.lookup (Text.pack key) pairs
  _ -> Nothing

arrayOf :: R.Reply -> Maybe [R.Reply]
arrayOf reply = case reply of
  R.Array xs -> Just xs
  _ -> Nothing

-- | A map's entry, as the line protocol writes one.
entryOf :: R.Reply -> Maybe (R.Reply, Natural)
entryOf reply = case reply of
  R.Array [key, value] -> fmap ((,) key) (naturalOf value)
  _ -> Nothing

textOf :: R.Reply -> Maybe Text.Text
textOf reply = case reply of
  R.Text t -> Just t
  _ -> Nothing

naturalOf :: R.Reply -> Maybe Natural
naturalOf reply = case reply of
  R.Number n -> Integer.toNatural n
  _ -> Nothing

-- | No seat may read another's screen, so a change of seat clears it and
-- waits for the next player to say they are there; whether it did. A seat
-- that has lines left to read says when it is done first.
handOff :: (Monad m) => Terminal.Terminal m -> PlayerId.PlayerId -> Client m Bool
handOff terminal seat = do
  facing <- State.gets Hotseat.facing
  let handing = facing /= Just seat
  Monad.when handing $ do
    unread <- State.gets Hotseat.unread
    Monad.when (Maybe.isJust facing && unread) $ do
      say terminal (Text.pack "Press Enter to pass the screen on.")
      Monad.void (listen terminal)
    lift2 (Terminal.clear terminal)
    say terminal (Text.pack "Pass to " <> Render.player seat <> Text.pack ", then press Enter.")
    _ <- listen terminal
    lift2 (Terminal.clear terminal)
    State.modify' (\h -> h {Hotseat.facing = Just seat})
  pure handing

-- | Adds the view's witnessed entries the client has not read yet to its
-- seat's news: the rest of the previous turn's, where the seat last looked
-- during it, and this turn's. Every request's view is read, answered
-- automatically or not, since the view holds only those two turns' entries.
-- A seat is sent a request every turn, even one it is controlled for: each
-- priority asks the seat itself whether it concedes (CR 104.3a, 724.6). The
-- mark is kept per game, since a subgame's and a restarted game's turns are
-- numbered from 1 again (CR 728.1, 730.1a).
collect :: (Monad m) => PlayerView.PlayerView -> Client m ()
collect view = do
  let seat = PlayerView.viewer view
      mark = (seat, PlayerView.game view)
      turn = PlayerView.turn view
      entries = PlayerView.witnessed view
  before <- State.gets (Map.lookup mark . Hotseat.seen)
  let missed = case before of
        Just (t, n)
          | t == turn -> List.genericDrop n entries
          | t + 1 == turn -> List.genericDrop n (PlayerView.witnessedLastTurn view) <> entries
        _ -> entries
      unread = Seq.fromList (Render.events view missed)
  State.modify' $ \h ->
    h
      { Hotseat.seen = Map.insert mark (turn, Natural.length entries) (Hotseat.seen h),
        Hotseat.news = Map.insertWith (flip (<>)) seat unread (Hotseat.news h)
      }

-- | The lines showing the seat its news, emptying it: one line saying what
-- happened since it last looked, where the screen was just handed to it,
-- and otherwise a line each, for a seat that never stopped looking.
tell :: (Monad m) => Bool -> PlayerId.PlayerId -> Client m [Text.Text]
tell handed seat = do
  news <- State.gets (foldMap Foldable.toList . Map.lookup seat . Hotseat.news)
  State.modify' (\h -> h {Hotseat.news = Map.delete seat (Hotseat.news h)})
  pure $
    if handed
      then [Text.pack "Since you last looked: " <> Text.unwords news | not (null news)]
      else news

-- | At the game's end, each person seat's news it was not yet shown (the
-- entries after its last question: the killing blow, say), the seat the
-- screen faces first and any other handed the screen only if it has news.
ending :: (Monad m) => Terminal.Terminal m -> [PlayerId.PlayerId] -> GameState.GameState -> Client m ()
ending terminal people gs = do
  facing <- State.gets Hotseat.facing
  Monad.forM_ (List.sortOn ((/= facing) . Just) people) $ \seat -> do
    collect (PlayerView.Engine.viewFor seat gs)
    pending <- State.gets (maybe False (not . null) . Map.lookup seat . Hotseat.news)
    Monad.when pending $ do
      handed <- handOff terminal seat
      mapM_ (say terminal) =<< tell handed seat

say :: (Monad m) => Terminal.Terminal m -> Text.Text -> Client m ()
say terminal line = do
  lift2 (Terminal.say terminal line)
  State.modify' (\h -> h {Hotseat.unread = True})

listen :: (Monad m) => Terminal.Terminal m -> Client m Text.Text
listen terminal = do
  typed <- lift2 (Terminal.listen terminal)
  State.modify' (\h -> h {Hotseat.unread = False})
  maybe (stop (Text.pack "end of input")) pure typed

stop :: (Monad m) => Text.Text -> Client m a
stop = Trans.lift . Except.throwE

lift2 :: (Monad m) => m a -> Client m a
lift2 = Trans.lift . Trans.lift
