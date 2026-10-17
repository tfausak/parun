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
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.LearnMode as LearnMode
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Reply as R

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s _ = Spec.describe s "Reply" $ do
  Spec.it s "an action is answered by its position in the offer" $ do
    Spec.assertEqWith s "decoded" (done (Reply.decode (Reply.shapeOf choose) (R.Number 1))) (Just tap)
    Spec.assertEqWith s "encoded" (Reply.encode (Reply.shapeOf choose) unnamed tap) (R.Number 1)
  Spec.it s "an index past the offer fails rather than wrapping" $
    Spec.assertEqWith s "failed" (failure (Reply.decode (Reply.shapeOf choose) (R.Number 2))) (Just (Text.pack "expected an index below 2"))
  Spec.it s "a learn mode may be declined with null" $
    Spec.assertEqWith s "declined" (done (Reply.decode (Reply.shapeOf learn) R.Null)) (Just Nothing)

choose :: Prompt.Prompt Action.Action
choose = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass, tap]

tap :: Action.Action
tap = Action.ActivateManaAbility (ObjectId.MkObjectId 7)

learn :: Prompt.Prompt (Maybe LearnMode.LearnMode)
learn = Prompt.ChooseLearn (Decider.MkDecider S.alice) S.alice (ObjectId.MkObjectId 7) (minBound NonEmpty.:| [maxBound])

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
