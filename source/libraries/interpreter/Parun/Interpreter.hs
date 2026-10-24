{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}

-- The far side of Parun.Engine.Engine.runGameAsked: what an answerer needs that
-- the rules engine deliberately cannot supply itself.
--
-- The engine's dependency list has no parun:registry edge, so nothing inside it
-- can answer "what card is this name?"; it asks Prompt.LookUpCard instead. An
-- interpreter holds a registry by construction, which is why a question about
-- the Oracle card reference is settled here rather than there: this module
-- depends on both halves, and neither half depends on it.
module Parun.Interpreter where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.Registry as Registry
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prompt as Prompt

-- CR 201.4: is this a name in the Oracle card reference, and -- CR 201.4a --
-- does the card it names match the characteristics the effect asked for?
--
-- The registry IS the reference the rule speaks of: a name it does not answer to
-- is not a name a player may choose. That makes the answer a claim about the
-- pool a caller pointed the registry at, the same posture Parun.Registry's own
-- header takes about what a registry is for.
--
-- Answered by the registry AND by the card it hands back, which is not one
-- question but two: a file registry looks a name up by its SLUG
-- (Parun.Registry.slugFor), so "goblin-piker" and "GOBLIN PIKER" both fetch the
-- Goblin Piker, and neither is a name in the reference. Card.faceNamed is the
-- exact comparison that refuses them -- the same comparison
-- Parun.Engine.Filter's HasChosenName makes later, so a name this admits is one
-- the rest of the engine can act on rather than one it silently ignores.
--
-- That face IS the judgement's subject, which is CR 201.4b and CR 201.4d in one
-- step: a split card's half and a double-faced card's back face are each keyed
-- in Parun.Registry.index under their own name, and rule 201.4a is put to "only
-- that half's" or "only the back face's" characteristics. The alternative names
-- CR 201.4c and CR 201.4f allow are judged the same way. Nothing here reaches CR
-- 709.4a's combined view, which is a name the card has without being any one
-- face's and so is not choosable at all (CR 201.4b's "but not both").
--
-- Matched through Parun.Engine.Projection.View.viewOfCard off the printed face,
-- Parun.Engine.Companion.fulfilled's posture and for its reason: a card outside
-- the game has no object to project (CR 400.11), and rule 201.4a asks about
-- Oracle text rather than about anything on the board. The chooser is the
-- context's perspective, since they are the player the restriction is put to.
--
-- A lookup reaching a card file the registry cannot use goes to `failed`, the
-- host's answer to a broken corpus, rather than reading as no such card.
legalCardName ::
  (Monad m) =>
  Registry.Registry m ->
  (forall r. InvalidCorpus.InvalidCorpus -> m r) ->
  GameState.GameState ->
  PlayerId.PlayerId ->
  Filter.Type.Filter Keyword.Keyword ->
  CardName.CardName ->
  m Bool
legalCardName registry failed gs chooser restriction name = do
  found <- fetched failed (Registry.fetchCard registry name)
  pure $ case found of
    Nothing -> False
    Just card -> case Card.faceNamed name card of
      Nothing -> False
      Just face ->
        Filter.matches
          (Filter.contextIn gs (Just chooser) Nothing)
          (Projection.viewOfCard face)
          restriction

-- CR 201.4's "the player must choose the name of a card", enforced over an
-- interpreter's own answerer: an illegal name is not recorded, the same question
-- is put again, and only a legal answer reaches the engine.
--
-- ASKED AGAIN rather than replaced, which is the one posture available here.
-- Prompt.ChooseCardName offers no candidate list -- rule 201.4's offer is every
-- card in the reference -- so there is nothing to fall back to the way
-- Parun.Engine.Target.drawFromPiles falls back to the first card of a pile, and
-- picking a legal name on the answerer's behalf would be making a player's
-- choice. An answerer that never answers legally never returns, which is the
-- contract a client's own prompt loop already has --
-- Parun.Engine.Replay.defaultAnswer is the one answerer in the tree that must not
-- be wrapped, its own arm saying why it answers rule 201.4 illegally on purpose.
--
-- A wrapper an interpreter installs rather than a check inside the engine: the
-- engine holds no reference to judge a name against, and asks one
-- (Prompt.LookUpCard) only for the card behind a name already chosen. Both
-- roads to a chosen name --
-- Parun.Engine.Resolve's Effect.ChooseCardName arm (CR 608.2c) and
-- Parun.Engine.Event's EntryRewrite.ChooseCardNames arm (CR 614.1c) -- raise this
-- one Prompt, so covering the Prompt covers both.
--
-- Over Asked rather than Prompt because rule 201.4a's match needs the asking
-- game's teams for its Filter context, and Asked is where that state is.
--
-- Parun.CastProhibitionSpec's "CR 201.4 a name no card has is refused and the
-- chooser is asked again", "CR 201.4 a slug the registry answers to is not a
-- card's name" and "CR 201.4a a real card the restriction forbids is refused and
-- the chooser is asked again" are what prove it.
policingCardNames ::
  (Monad m) =>
  Registry.Registry m ->
  (forall r. InvalidCorpus.InvalidCorpus -> m r) ->
  (forall r. Asked.Asked r -> m r) ->
  Asked.Asked a ->
  m a
policingCardNames registry failed answer asked = case Asked.prompt asked of
  Prompt.ChooseCardName _ chooser _ restriction _ ->
    let again = do
          name <- answer asked
          legal <- legalCardName registry failed (Asked.game asked) chooser restriction name
          if legal then pure name else again
     in again
  _ -> answer asked

-- CR 108.1: Prompt.LookUpCard, Prompt.ReferenceCards and Prompt.ReferenceNames
-- answered from the registry, the reference an interpreter holds; every other
-- prompt goes to the answerer beneath. Installed beside policingCardNames, whose
-- registry it shares.
--
-- A reference card is named by its FIRST face, which is the name
-- Prompt.LookUpCard then fetches it back by. The pick among the names is not
-- made here: the engine asks it of the answerer beneath, as randomness.
-- Prompt.ReferenceNames asks about every NAME instead, each judged by the view
-- Card.referenceViews pairs it with.
--
-- Parun.CastProhibitionSpec's Spy Kit case, where Runed Halo names a card in
-- no zone, is what proves the lookup; Parun.ConjureSpec's Fear of Change case
-- proves the enumeration; Parun.DamageSpec's two legendary Spy Kit hosts prove
-- the face names, a back face's among them.
--
-- A registry that reaches a card file it cannot use is answered by `failed`,
-- the host's decision; the engine only ever sees a card or none.
-- Parun.CastProhibitionSpec's "CR 108.1 a lookup the registry cannot answer goes
-- to the host's handler" is what proves it.
lookingUpCards ::
  (Monad m) =>
  Registry.Registry m ->
  (forall r. InvalidCorpus.InvalidCorpus -> m r) ->
  (forall r. Asked.Asked r -> m r) ->
  Asked.Asked a ->
  m a
lookingUpCards registry failed answer asked = case Asked.prompt asked of
  Prompt.LookUpCard name -> fetched failed (Registry.fetchCard registry name)
  Prompt.ReferenceCards predicate amount ->
    fmap
      (fmap (Face.name . NonEmpty.head . Card.Type.faces) . filter (Projection.referenceAdmits (Game.teams (Asked.game asked)) amount predicate))
      (fetched failed (Registry.cards registry))
  Prompt.ReferenceNames predicate ->
    let context = Filter.contextIn (Asked.game asked) Nothing Nothing
        admitted face = Filter.matches context (Projection.viewOfCard face) predicate
     in fmap (concatMap (fmap fst . filter (admitted . snd) . Card.referenceViews)) (fetched failed (Registry.cards registry))
  _ -> answer asked

-- A registry's answer, its failure handed to the host's handler.
fetched :: (Monad m) => (InvalidCorpus.InvalidCorpus -> m a) -> m (Either InvalidCorpus.InvalidCorpus a) -> m a
fetched failed answering = answering >>= either failed pure
