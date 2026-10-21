-- | The text client: a person answering request lines at a terminal. It reads
-- only the decoded line and the card data, never the game, so anything it
-- cannot show is a gap in the protocol.
module Pawl.Play.Client where

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
import qualified Pawl.Codec.ManaCost as Codec.ManaCost
import qualified Pawl.Codec.ManaType as Codec.ManaType
import qualified Pawl.Codec.Reply as Codec.Reply
import qualified Pawl.Codec.Request as Codec.Request
import qualified Pawl.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Pawl.Extra.Integer as Integer
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Play.Render as Render
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.Mana as Mana
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.ManaUnit as ManaUnit
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.Question as Question
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.Request as Request
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.Terminal as Terminal
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
  -- (Pawl.Play.Game.playOrDraw), so every request it reads has a view.
  view <- maybe (stop (Text.pack "a request with no view")) pure (Request.view request)
  collect view
  fmap (Common.render . Codec.Reply.toValue) $
    if Question.kind question == Text.pack "Concede"
      then do
        conceding <- State.gets (Set.member seat . Hotseat.conceding)
        pure (R.Text (Text.pack (if conceding then "Concedes" else "Continues")))
      else do
        (said, automatic) <- unasked view request
        case automatic of
          Nothing -> mapM_ (say terminal) said >> asked terminal lookUp view request
          Just reply -> do
            -- Only the seat the screen faces is shown its news unasked.
            facing <- State.gets Hotseat.facing
            news <- if facing == Just seat then tell False seat else pure []
            mapM_ (say terminal) (news <> said)
            pure reply

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
      <> Render.board view
      <> news
      <> Render.hand view
      <> [Text.pack "Type card and a number from a list, or a card's name, to read that card." | first]
      <> foldMap (\p -> [Text.pack "That answer was refused: " <> p]) (Request.problem request)
  answer terminal lookUp seat view question

-- | CR 104.3a's concession, quitting and reading a card are typed at any
-- question, and "auto" or an empty line at a mana source; everything else is
-- read by the question's own reader until it reads.
answer :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerId.PlayerId -> PlayerView.PlayerView -> Question.Question -> Client m R.Reply
answer terminal lookUp seat view question = case (Question.kind question, slotsOf question) of
  (kind, Just (source, slots)) | kind == Text.pack "ChooseTargets" -> fmap R.Array (mapM (target source) slots)
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
                      Nothing -> say terminal (Text.pack "Auto can't pay the rest of this cost. Choose a source.") >> loop
              _ -> either (\problem -> say terminal problem >> loop) pure (reader typed)
      loop
    target source (slot, wanted, legal) = do
      let n = min wanted (Natural.length legal)
          shown =
            Text.concat [Text.pack "Choose ", Render.count n "target", Text.pack " for ", objectName view source, Text.pack " (", slotName slot, Text.pack "):"]
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
  "ChooseDiscard" -> pickCount "to discard"
  "DeclareAttackers" -> do
    attackers <- arrayOf offer
    pure
      ( Text.pack "Choose attackers by number or range such as 1-3, separated by spaces, all, or press Enter for none:" : numbered (fmap (objectName view) attackers),
        fmap R.Array . some attackers
      )
  "DeclareBlockers" -> do
    blockers <- field "blockers" offer >>= arrayOf
    attackers <- field "attackers" offer >>= arrayOf
    pure
      ( [Text.pack "Attacking:"]
          <> numbered (fmap (objectName view) attackers)
          <> [Text.pack "Your creatures that can block:"]
          <> numbered (fmap (objectName view) blockers)
          <> [Text.pack "Type blocker:attacker pairs, such as 1:2, separated by spaces, or press Enter for no blocks:"],
        blocks blockers attackers
      )
  "ChooseManaSource" -> do
    cost <- field "cost" offer >>= decoded Codec.ManaCost.codec
    sourcePick (Text.pack "Paying " <> Render.manaCost cost <> Text.pack ". Choose a source to pay with, stop to stop paying, or auto (or press Enter) to pay the rest:") (Text.pack "stop") (Text.pack ", stop, or auto")
  -- CR 601.2g: mana abilities are activated before the cost is paid.
  "ChooseExtraManaSource" -> sourcePick (Text.pack "The cost is covered. Choose another source to activate, or press Enter to pay now:") Text.empty (Text.pack ", or press Enter to pay now")
  "ChooseManaYield" -> do
    source <- field "source" offer
    yields <- field "yields" offer >>= decoded (Common.list (Common.list Codec.ManaType.codec))
    pure
      ( Text.pack "Choose the mana " <> objectName view source <> Text.pack " makes:" : numbered (fmap (foldMap Render.manaType) yields),
        fmap (R.Number . toInteger . subtract 1) . one (Natural.length yields)
      )
  "ChooseX" -> do
    source <- field "source" offer
    variable <- field "variable" offer >>= textOf
    least <- field "least" offer >>= naturalOf
    greatest <- field "greatest" offer >>= naturalOf
    pure
      ( [Text.concat [Text.pack "Choose ", variable, Text.pack " for ", objectName view source, Text.pack (", from " <> show least <> " to " <> show greatest <> ":")]],
        \typed -> case Read.readMaybe (Text.unpack (Text.strip typed)) of
          Just n | least <= n && n <= greatest -> Right (R.Number (toInteger n))
          _ -> Left (Text.pack ("Type a number from " <> show least <> " to " <> show greatest <> "."))
      )
  "ChooseOptional" -> do
    source <- field "source" offer
    pure
      ( [objectName view source <> Text.pack ": use its optional effect?", Text.pack "  1. Yes", Text.pack "  2. No"],
        fmap (\i -> R.Object [(Text.pack "type", R.Text (Text.pack (if i == 1 then "Exercises" else "Declines")))]) . one 2
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
  _ -> Nothing
  where
    offer = Question.offer question
    -- A source by number, or the line `none` for no source.
    sourcePick heading none others = do
      offered <- field "sources" offer >>= arrayOf >>= mapM manaSource
      let sources = fmap fst offered
          makes yields = if null yields then Text.empty else Text.pack " (makes " <> Text.intercalate (Text.pack " or ") (fmap (foldMap Render.manaType) yields) <> Text.pack ")"
      pure
        ( heading : numbered (fmap (\(source, yields) -> objectName view source <> makes yields) offered),
          \typed ->
            if Text.toCaseFold typed == none
              then Right R.Null
              else either (const (Left (Text.pack ("Type one number from 1 to " <> show (Natural.length sources)) <> others <> Text.pack "."))) (Right . pickFrom sources) (one (Natural.length sources) typed)
        )
    pickCount purpose = do
      from <- field "from" offer >>= arrayOf
      wanted <- field "count" offer >>= naturalOf
      let n = min wanted (Natural.length from)
      pure
        ( Text.pack "Choose " <> Render.count n "card" <> Text.pack (" " <> purpose <> ", by number or range such as 1-3, separated by spaces:") : numbered (fmap (objectName view) from),
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
      flip fmap (traverse (Render.details lookUp view) (filter matches (Map.elems (Render.objects view)))) $ \shown -> case ListUtils.nubOrd shown of
        [] -> [Text.pack "No card you can see is named " <> wanted <> Text.pack "."]
        found -> List.intercalate [Text.empty] found
  where
    matches = any ((== Text.toCaseFold wanted) . Text.toCaseFold . CardName.unwrap) . Set.toList . Render.cardNames

-- | The object behind each numbered option of an offer, where it names one:
-- the offer's own list, or the cards or sources it chooses from.
listedObjects :: PlayerView.PlayerView -> R.Reply -> [Maybe ObjectId.ObjectId]
listedObjects view offer = foldMap (fmap optionObject) (Monad.msum [fmap (fmap snd . distinct view) (arrayOf offer), field "from" offer >>= arrayOf, field "sources" offer >>= arrayOf])
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

-- | The object a recipient names, if it is not a player.
recipientObject :: R.Reply -> Maybe ObjectId.ObjectId
recipientObject reply = case reply of
  R.Array [R.Text tag, x] | tag /= Text.pack "Player" -> objectOf x
  _ -> Nothing

-- | What to say, and the answer the seat opted into ahead of the question,
-- if any: passing a priority that offers nothing but passing and
-- mana abilities, and the rest of a payment the seat chose auto at. A
-- payment's other prompts and a refused answer end "auto", and a refused
-- answer is always asked.
unasked :: (Monad m) => PlayerView.PlayerView -> Request.Request -> Client m ([Text.Text], Maybe R.Reply)
unasked view request = do
  let question = Request.question request
      seat = Question.seat question
      offer = Question.offer question
      kind = Text.unpack (Question.kind question)
      refused = Maybe.isJust (Request.problem request)
  hotseat <- State.get
  let paying = Map.lookup seat (Hotseat.paying hotseat)
  Monad.when (refused || kind `notElem` ["ChooseManaSource", "ChooseExtraManaSource", "ChooseManaYield", "ChooseManaToSpend"]) (stopPaying seat)
  case kind of
    _ | refused -> pure ([], Nothing)
    "ChooseAction"
      | Hotseat.autoPass hotseat,
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
  payer <- field "payer" offer >>= textOf >>= Read.readMaybe . Text.unpack
  cost <- field "cost" offer >>= decoded Codec.ManaCost.codec
  owed <- mapM owedOf (ManaCost.unwrap cost)
  sources <- field "sources" offer >>= arrayOf >>= mapM manaSource
  let pool = foldMap (fmap ManaUnit.manaType . Mana.unwrap . SeatView.manaPool) (List.find ((== PlayerId.MkPlayerId payer) . SeatView.player) (PlayerView.seats view))
      (colored, unspent) = List.foldl' spendOne ([], pool) (Either.rights owed)
      generic = sum (Either.lefts owed)
      wanted = Set.fromList colored
      makes (_, yields) = Set.fromList (concat yields)
      fewest by = Maybe.listToMaybe . List.sortOn by
  source <-
    if not (Set.null wanted)
      then fewest (\s -> (Set.size (Set.intersection wanted (makes s)), Set.size (makes s))) (filter (not . Set.disjoint wanted . makes) sources)
      else
        if generic > Natural.length unspent
          then fewest (Set.size . makes) (filter (not . Set.null . makes) sources)
          else Nothing
  pure (fst source, Set.intersection wanted (makes source))
  where
    owedOf symbol = case symbol of
      ManaSymbol.Generic n -> Just (Left n)
      ManaSymbol.OfType t -> Just (Right t)
      _ -> Nothing
    spendOne (still, pool) t = case List.elemIndex t pool of
      Just i -> (still, take i pool <> drop (i + 1) pool)
      Nothing -> (still <> [t], pool)

-- | A mana source as an offer names it, beside the mana types of each yield.
manaSource :: R.Reply -> Maybe (R.Reply, [[ManaType.ManaType]])
manaSource reply = do
  source <- field "source" reply
  makes <- field "makes" reply >>= decoded (Common.list (Common.list Codec.ManaType.codec))
  pure (source, makes)

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

recipientName :: PlayerView.PlayerView -> R.Reply -> Text.Text
recipientName view reply = case reply of
  R.Array [R.Text tag, R.Text x]
    | tag == Text.pack "Player" -> maybe x (Render.player . PlayerId.MkPlayerId) (Read.readMaybe (Text.unpack x))
    | otherwise -> objectName view (R.Text x)
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

slotName :: R.Reply -> Text.Text
slotName = Common.render . Codec.Reply.toValue

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
-- priority asks the seat itself whether it concedes (CR 104.3a, 723.6).
--
-- Not implemented: telling a subgame's or a restarted game's turns from the
-- parent's or the old game's, whose turn numbers the mark shares (#5369).
collect :: (Monad m) => PlayerView.PlayerView -> Client m ()
collect view = do
  let seat = PlayerView.viewer view
      turn = PlayerView.turn view
      entries = PlayerView.witnessed view
  before <- State.gets (Map.lookup seat . Hotseat.seen)
  let missed = case before of
        Just (t, n)
          | t == turn -> List.genericDrop n entries
          | t + 1 == turn -> List.genericDrop n (PlayerView.witnessedLastTurn view) <> entries
        _ -> entries
      unread = Seq.fromList (Render.events view missed)
  State.modify' $ \h ->
    h
      { Hotseat.seen = Map.insert seat (turn, Natural.length entries) (Hotseat.seen h),
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
      then [Text.pack "Since you last looked: " <> Text.intercalate (Text.pack "; ") news | not (null news)]
      else news

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
