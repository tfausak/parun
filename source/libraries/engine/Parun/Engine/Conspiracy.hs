-- | CR 315, conspiracy cards: which objects and faces are conspiracies, the
-- classification CR 315.2's placement, CR 315.3's hold on the command zone and
-- CR 113.6p's functioning there all read; and CR 702.106's hidden agenda, which
-- puts one there face down.
--
-- A card type and not a format, Parun.Engine.Vanguard's posture: every rule in
-- CR 315 is stated of a conspiracy CARD, so no GameSettings field says "this is a
-- Conspiracy Draft game".
--
-- WHAT IS NOT IMPLEMENTED:
--
--   * CR 702.106f's double agenda (#5014).
module Parun.Engine.Conspiracy where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Chosen as Chosen
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter
import Parun.Types.Game (Game)
import Parun.Types.GameState (GameState)
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.TypeLine as TypeLine
import qualified Parun.Types.Zone as Zone

-- | CR 205.2a: does this face print the conspiracy card type? A classification
-- over the printed type line, never a case on which card it is.
isConspiracyFace :: Face.Face Card.Card -> Bool
isConspiracyFace face = Set.member CardType.Conspiracy (TypeLine.types (Face.typeLine face))

-- | CR 315.3: is this object a conspiracy card? Read off the card behind it
-- (Game.faceUpFaceOf): CR 315.5b leaves a face-down one with no
-- characteristics, yet it is still a conspiracy card that CR 315.3 holds in the
-- command zone, where nothing can copy it or change its type.
isConspiracy :: ObjectId -> GameState -> Bool
isConspiracy oid gs = maybe False isConspiracyFace (Game.faceUpFaceOf oid gs)

-- | CR 315.5b / 315.7: is this a conspiracy card lying face down?
isFaceDownConspiracy :: ObjectId -> GameState -> Bool
isFaceDownConspiracy oid gs =
  isConspiracy oid gs && maybe False (Facing.isFaceDown . Object.facing) (Game.lookupObject oid gs)

-- | CR 702.106a / 702.106b: "as you put this conspiracy card into the command
-- zone, turn it face down and secretly choose a card name", for a conspiracy
-- its owner has just put there (CR 315.2). The name is written to
-- Object.chosenNames, which Filter.HasChosenName reads off the source, so CR
-- 702.106d's linked ability sees this choice and no other.
--
-- Not implemented: the name is written where every answerer can read it, and a
-- later chooser's answerer sees an earlier player's name (#5418).
hideAgenda :: PlayerId -> ObjectId -> Game ()
hideAgenda pid oid = do
  gs <- State.get
  Monad.when (maybe False (Map.member Keyword.HiddenAgenda . Face.keywords) (Game.faceOf oid gs)) $ do
    State.modify' (Game.turnFacing (Facing.faceDown FaceDownReason.HiddenAgenda) oid)
    name <- Game.choose (Prompt.ChooseCardName (Decide.deciderFor pid gs) pid oid (Filter.And []) Seq.empty) >>= Game.lookUpChosenName
    State.modify' $ \g -> Game.recordChoice Chosen.Names (Game.acquisitionOf oid g) (const (Just (Map.singleton pid name))) oid g

-- | CR 702.106c / 116.2j: the face-down conspiracies this player may turn face
-- up now. CR 315.6 makes the owner the controller, so the owner-indexed command
-- zone is the controller's; the timing is any time they have priority, which
-- Parun.Engine.Action.legalActions being asked only of the priority holder is.
turnable :: PlayerId -> GameState -> [ObjectId]
turnable pid gs = filter (`isFaceDownConspiracy` gs) (Game.zoneMembers Zone.Command pid gs)

-- | CR 702.106c: turn a face-down conspiracy this player controls face up,
-- revealing its chosen name. No cost and no stack (CR 116.2j). Not CR 116.2b's
-- turning a permanent face up, so it records no GameEvent.TurnedFaceUp: a
-- conspiracy is never a permanent (CR 315.3). Game.turnFacing gives it CR
-- 613.7j's new timestamp.
turnFaceUp :: PlayerId -> ObjectId -> Game ()
turnFaceUp pid oid = do
  gs <- State.get
  Monad.when (oid `elem` turnable pid gs) (State.modify' (Game.turnFacing Facing.FaceUp oid))
