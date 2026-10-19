{-# LANGUAGE GADTs #-}

-- Covers Pawl.Scenario.Reply: the answer shapes a prompt's answer decodes
-- through and encodes back to.
module Pawl.ReplySpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario.Reply as Reply
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.BallotChoice as BallotChoice
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.LearnMode as LearnMode
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Reference as Reference
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s _ = Spec.describe s "Reply" $ do
  Spec.it s "an action is answered by its position in the offer" $ do
    Spec.assertEqWith s "decoded" (done (Reply.decode (Reply.shapeOf choose) (R.Number 1))) (Just tap)
    Spec.assertEqWith s "encoded" (Reply.encode (Reply.shapeOf choose) unnamed tap) (R.Number 1)
  Spec.it s "an index past the offer fails rather than wrapping" $
    Spec.assertEqWith s "failed" (failure (Reply.decode (Reply.shapeOf choose) (R.Number 2))) (Just (Text.pack "expected an index below 2"))
  Spec.it s "a learn mode may be declined with null" $
    Spec.assertEqWith s "declined" (done (Reply.decode (Reply.shapeOf learn) R.Null)) (Just Nothing)
  -- One Prompt.ChooseVote over each kind of listed choice, its answer spelled
  -- as that kind's own: a word as itself, a player as a seat label, an object
  -- as a reference.
  Spec.it s "a vote's choice is answered as its kind's own answer, both ways" $ do
    let time = BallotChoice.ForWord (SlotName.MkSlotName (Text.pack "time"))
        knowledge = BallotChoice.ForWord (SlotName.MkSlotName (Text.pack "knowledge"))
        bob = BallotChoice.ForPlayer S.bob
        carol = BallotChoice.ForPlayer S.carol
        wall = BallotChoice.ForObject (ObjectId.MkObjectId 3)
        piker = BallotChoice.ForObject (ObjectId.MkObjectId 7)
        trip offered choice = resolving (Reply.decode (Reply.shapeOf (vote offered)) (Reply.encode (Reply.shapeOf (vote offered)) naming choice))
    Spec.assertEqWith s "a word is spelled as itself" (Reply.encode (Reply.shapeOf (vote (time NonEmpty.:| [knowledge]))) naming knowledge) (R.Text (Text.pack "knowledge"))
    Spec.assertEqWith s "a player is spelled as their seat label" (Reply.encode (Reply.shapeOf (vote (bob NonEmpty.:| [carol]))) naming carol) (R.Text (Text.pack "seat2"))
    Spec.assertEqWith s "each kind decodes back to the choice it encoded" (fmap (uncurry trip) [(time NonEmpty.:| [knowledge], knowledge), (bob NonEmpty.:| [carol], carol), (wall NonEmpty.:| [piker], piker)]) [Just knowledge, Just carol, Just piker]

choose :: Prompt.Prompt Action.Action
choose = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass, tap]

tap :: Action.Action
tap = Action.ActivateManaAbility (ObjectId.MkObjectId 7)

learn :: Prompt.Prompt (Maybe LearnMode.LearnMode)
learn = Prompt.ChooseLearn (Decider.MkDecider S.alice) S.alice (ObjectId.MkObjectId 7) (minBound NonEmpty.:| [maxBound])

vote :: NonEmpty.NonEmpty (BallotChoice.BallotChoice ObjectId.ObjectId) -> Prompt.Prompt (BallotChoice.BallotChoice ObjectId.ObjectId)
vote = Prompt.ChooseVote (Decider.MkDecider S.alice) S.alice (ObjectId.MkObjectId 9)

-- Names a seat "seat" plus its index and an object by a label of its id, and
-- resolves both back, as a run would.
naming :: Reply.Namer
naming =
  Reply.MkNamer
    (Reference.Labelled . Label.MkLabel . Text.pack . ("object" <>) . show . ObjectId.unwrap)
    (Label.MkLabel . Text.pack . ("seat" <>) . show . PlayerId.unwrap)

resolving :: Reply.Needs a -> Maybe a
resolving needs = case needs of
  Reply.Done a -> Just a
  Reply.Failed _ -> Nothing
  Reply.NeedObject (Reference.Labelled label) k -> resolving (k (ObjectId.MkObjectId (read (drop 6 (Text.unpack (Label.unwrap label))))))
  Reply.NeedObject _ _ -> Nothing
  Reply.NeedPlayer label k -> resolving (k (PlayerId.MkPlayerId (read (drop 4 (Text.unpack (Label.unwrap label))))))

unnamed :: Reply.Namer
unnamed = Reply.MkNamer (const (error "no object")) (const (error "no player"))

done :: Reply.Needs a -> Maybe a
done needs = case needs of
  Reply.Done a -> Just a
  _ -> Nothing

failure :: Reply.Needs a -> Maybe Text.Text
failure needs = case needs of
  Reply.Failed problem -> Just problem
  _ -> Nothing
