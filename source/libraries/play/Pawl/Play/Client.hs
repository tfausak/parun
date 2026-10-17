-- | The text client: a person answering request lines at a terminal. It reads
-- only the decoded line, never the game, so anything it cannot show is a gap
-- in the protocol.
module Pawl.Play.Client where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Codec.Reply as Codec.Reply
import qualified Pawl.Codec.Request as Codec.Request
import qualified Pawl.Extra.Integer as Integer
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Play.Render as Render
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.Question as Question
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.Request as Request
import qualified Pawl.Types.Terminal as Terminal
import qualified Text.Read as Read

-- | The client's monad: what it keeps between lines, and why play stopped.
type Client m = State.StateT Hotseat.Hotseat (Except.ExceptT Text.Text m)

-- | Answers one request line with a reply line, asking the person at the
-- terminal. A seat change first clears the screen and waits for the next
-- player. Fails with why play stopped: the end of input, or "quit".
--
-- CR 104.3a: a seat concedes by typing "concede" at any question, and the
-- client answers the engine's next Concede prompt for that seat with it.
respond :: (Monad m) => Terminal.Terminal m -> Text.Text -> Client m Text.Text
respond terminal line = do
  request <- either (stop . (Text.pack "unreadable request: " <>)) pure (Common.parse line >>= Codec.decode Codec.Request.codec)
  let question = Request.question request
      view = Request.view request
      seat = Question.seat question
  fmap (Common.render . Codec.Reply.toValue) $
    if Question.kind question == Text.pack "Concede"
      then do
        conceding <- State.gets (Set.member seat . Hotseat.conceding)
        pure (R.Text (Text.pack (if conceding then "Concedes" else "Continues")))
      else do
        handOff terminal seat
        news <- unseen view
        mapM_ (say terminal) $
          [Text.empty]
            <> Render.board view
            <> [Text.pack "Since you last looked: " <> Text.intercalate (Text.pack "; ") news | not (null news)]
            <> Render.hand view
            <> foldMap (\p -> [Text.pack "That answer was refused: " <> p]) (Request.problem request)
        answer terminal seat view question

-- | CR 104.3a's concession and quitting are typed at any question; everything
-- else is read by the question's own reader until it reads.
answer :: (Monad m) => Terminal.Terminal m -> PlayerId.PlayerId -> PlayerView.PlayerView -> Question.Question -> Client m R.Reply
answer terminal seat view question = case (Question.kind question, slotsOf question) of
  (kind, Just (source, slots)) | kind == Text.pack "ChooseTargets" -> fmap R.Array (mapM (target source) slots)
  _ -> ask (choice view question)
  where
    ask (shown, reader) = do
      mapM_ (say terminal) shown
      let loop = do
            typed <- fmap Text.strip (listen terminal)
            case Text.unpack typed of
              "quit" -> stop (Text.pack "quit")
              "concede" -> do
                State.modify' (\h -> h {Hotseat.conceding = Set.insert seat (Hotseat.conceding h)})
                say terminal (Text.pack "You concede at your next priority. Answer this question first.")
                loop
              _ -> either (\problem -> say terminal problem >> loop) pure (reader typed)
      loop
    target source (slot, wanted, legal) = do
      let n = min wanted (Natural.length legal)
          shown =
            Text.concat [Text.pack "Choose ", Render.count n "target", Text.pack " for ", objectName view source, Text.pack " (", slotName slot, Text.pack "):"]
              : numbered (fmap (recipientName view) legal)
      picked <- ask (shown, exactly n legal)
      pure (R.Array [slot, R.Array picked])

-- | What a question shows, and how a typed line is read into its answer.
choice :: PlayerView.PlayerView -> Question.Question -> ([Text.Text], Text.Text -> Either Text.Text R.Reply)
choice view question = Maybe.fromMaybe generic $ case Text.unpack (Question.kind question) of
  "ChooseAction" -> do
    actions <- arrayOf offer
    pure
      ( Text.pack "Choose an action:" : numbered (fmap (actionName view) actions),
        fmap (R.Number . toInteger . subtract 1) . one (Natural.length actions)
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
      ( Text.pack "Choose attackers by number, separated by spaces, or press Enter for none:" : numbered (fmap (objectName view) attackers),
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
  "ChooseManaSource" -> sourcePick "Choose a source to pay with, or 0 to stop paying:"
  "ChooseExtraManaSource" -> sourcePick "The cost is covered. Choose another source to activate, or 0 to pay now:"
  "ChooseX" -> do
    source <- field "source" offer
    least <- field "least" offer >>= naturalOf
    greatest <- field "greatest" offer >>= naturalOf
    pure
      ( [Text.concat [Text.pack "Choose X for ", objectName view source, Text.pack (", from " <> show least <> " to " <> show greatest <> ":")]],
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
  _ -> Nothing
  where
    offer = Question.offer question
    sourcePick heading = do
      sources <- arrayOf offer
      pure
        ( Text.pack heading : numbered (fmap (objectName view) sources),
          \typed -> if Text.strip typed == Text.pack "0" then Right R.Null else fmap (pickFrom sources) (one (Natural.length sources) typed)
        )
    pickCount purpose = do
      from <- field "from" offer >>= arrayOf
      wanted <- field "count" offer >>= naturalOf
      let n = min wanted (Natural.length from)
      pure
        ( Text.pack "Choose " <> Render.count n "card" <> Text.pack (" " <> purpose <> ", by number separated by spaces:") : numbered (fmap (objectName view) from),
          fmap R.Array . exactly n from
        )
    generic =
      ( [Render.spaced (Question.kind question) <> Text.pack ":"]
          <> [Common.render (Codec.Reply.toValue offer) | offer /= R.Null]
          <> [Text.pack "Type the answer as JSON:"],
        Common.parse Monad.>=> Codec.Reply.fromValue
      )

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

-- | Any number of different options, by number.
some :: [R.Reply] -> Text.Text -> Either Text.Text [R.Reply]
some options typed = do
  is <- numbers typed
  let size = Natural.length options
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
        "Activate" -> Text.pack "Activate an ability of " <> subject
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

textOf :: R.Reply -> Maybe Text.Text
textOf reply = case reply of
  R.Text t -> Just t
  _ -> Nothing

naturalOf :: R.Reply -> Maybe Natural
naturalOf reply = case reply of
  R.Number n -> Integer.toNatural n
  _ -> Nothing

-- | No seat may read another's screen, so a change of seat clears it and
-- waits for the next player to say they are there.
handOff :: (Monad m) => Terminal.Terminal m -> PlayerId.PlayerId -> Client m ()
handOff terminal seat = do
  facing <- State.gets Hotseat.facing
  Monad.unless (facing == Just seat) $ do
    lift2 (Terminal.clear terminal)
    say terminal (Text.pack "Pass to " <> Render.player seat <> Text.pack ", then press Enter.")
    _ <- listen terminal
    lift2 (Terminal.clear terminal)
    State.modify' (\h -> h {Hotseat.facing = Just seat})

-- | The seat's witnessed entries it has not been shown this turn.
unseen :: (Monad m) => PlayerView.PlayerView -> Client m [Text.Text]
unseen view = do
  let seat = PlayerView.viewer view
      turn = PlayerView.turn view
      entries = PlayerView.witnessed view
  before <- State.gets (Map.lookup seat . Hotseat.shown)
  State.modify' (\h -> h {Hotseat.shown = Map.insert seat (turn, Natural.length entries) (Hotseat.shown h)})
  let skipped = case before of
        Just (t, n) | t == turn -> n
        _ -> 0
  pure (fmap Render.event (List.genericDrop skipped entries))

say :: (Monad m) => Terminal.Terminal m -> Text.Text -> Client m ()
say terminal = lift2 . Terminal.say terminal

listen :: (Monad m) => Terminal.Terminal m -> Client m Text.Text
listen terminal = lift2 (Terminal.listen terminal) >>= maybe (stop (Text.pack "end of input")) pure

stop :: (Monad m) => Text.Text -> Client m a
stop = Trans.lift . Except.throwE

lift2 :: (Monad m) => m a -> Client m a
lift2 = Trans.lift . Trans.lift
