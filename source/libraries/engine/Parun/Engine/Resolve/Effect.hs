-- Carrying out one effect (CR 608.2): applyOneEffect, the sole casing on
-- Effect at resolution, with the prevention riders, hand actions and mana
-- abilities that share its recursion. Split out of Parun.Engine.Resolve for
-- size; the spell and ability resolution that drives it stays there, and both
-- are imported by callers under the same Resolve alias. Each arm's body is a
-- function in Parun.Engine.Resolve.Arms, handed the recursion below that it
-- calls back into; the helpers that never recurse into resolving an effect are
-- Parun.Engine.Resolve.Common.
module Parun.Engine.Resolve.Effect where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Activatable as Activatable
import qualified Parun.Engine.ActivationRestriction as ActivationRestriction
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Cast as Cast
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Dice as Dice
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Event.Trigger as Trigger
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Loyalty as Loyalty
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Replacement as Replacement
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Arms.Counters as Counters
import qualified Parun.Engine.Resolve.Arms.Damage as Damage
import qualified Parun.Engine.Resolve.Arms.Objects as Objects
import qualified Parun.Engine.Resolve.Arms.Zones as Zones
import qualified Parun.Engine.Resolve.Common as Common
import Parun.Engine.Resolve.Slots (boundSlots, resolvingAbilityName, slotBindings)
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction.Type
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.CandidateCost as CandidateCost
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CastObligation as CastObligation
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.CastRepetition as CastRepetition
import Parun.Types.ClauseIndex (ClauseIndex)
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.DieResult as DieResult
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ExileLink as ExileLink
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownCharacteristics as FaceDownCharacteristics
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.FaceDownState as FaceDownState
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter.Type
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HandActionPerformer as HandActionPerformer
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.ManaAbilityPerformer as ManaAbilityPerformer
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSpending as ManaSpending
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Modal as Modal.Type
import Parun.Types.ModeIndex (ModeIndex)
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation
import qualified Parun.Types.PayOffer as PayOffer
import qualified Parun.Types.Payment as Payment
import qualified Parun.Types.PaymentDecision as PaymentDecision
import qualified Parun.Types.PaymentMoment as PaymentMoment
import qualified Parun.Types.PaymentSubject as PaymentSubject
import qualified Parun.Types.PendingEntryEffect as PendingEntryEffect
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.PendingTrigger as PendingTrigger
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerControl as PlayerControl
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Prevention as Prevention
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Quantity as Quantity.Type
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Response as Response
import Parun.Types.Result (Result)
import qualified Parun.Types.RollAdjustment as RollAdjustment
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.Throw as Throw
import qualified Parun.Types.ThrowKind as ThrowKind
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.Zone as Zone

-- CR 608.2g: make the offer Effect.OfferCast carries, once or over again.
--
-- CR 601.3's choice among the named cards is `offerCastOnce` below; this is the
-- repetition Parun.Types.CastRepetition names -- Fevered Suspicion's "you may cast
-- ANY NUMBER of spells from among those nonland cards", where Shell of the Last
-- Kappa's "cast A SPELL from among cards exiled with Shell of the Last Kappa"
-- stops after one. CR 608.2g's own "which may include casting other spells this
-- way" is what admits the repeat.
--
-- The card a round took is dropped from the next round's candidates rather than
-- the round re-reading the whole set: CR 400.7 has already made the cast card a
-- new object, so it would be dropped anyway, and dropping it HERE is what bounds
-- the recursion -- a round that somehow left its card where it was cannot offer
-- it for ever.
--
-- A DECLINE ENDS IT, and no reachable board can tell that from a decline that
-- skipped one card and went on: the caster names which card they are declining by
-- picking it at Prompt.ChooseOfferedCastSpell, so every card they wanted was
-- reachable before they said no.
--
-- Mandatory repeats too, and terminates for the same reason: each round casts a
-- different card, and a card the rules will not let them cast never reaches the
-- offer (question 4 below).
-- CR 707.12's copy is minted BEFORE the first round rather than at the cast, and
-- once for the whole offer rather than once per round: rule 707.12a's "an effect
-- that creates multiple copies and says a player 'may cast' those objects" makes
-- the creation one act and the casting a decision per object, so a repeated
-- offer asks about the same copies over again. A copy nobody casts is left where
-- it was made, for CR 704.5e to sweep at the next check (Parun.Engine.Sba).
--
-- Rod of Absorption's total is the repeat with a budget: each round offers
-- only a half whose mana value fits what is left (CR 202.3d, through
-- CastOffer.restriction's per-face match, so a split card's half is measured
-- as the spell it becomes -- unobserved, no board casting a split card this
-- way), and the cast spell's mana value is spent from it.
-- `evaluate` reads the budget's Quantity once, before the first round (CR
-- 608.2h).
--
-- Answers the spells the offer's casts put on the stack, for CR 400.7h's
-- OfferCast.slot.
offerCast :: Game Result -> Filter.Context -> (Quantity.Type.Quantity -> Maybe Integer) -> [ObjectId] -> PlayerId -> CastObligation.CastObligation -> PermissionVerb.PermissionVerb -> Maybe PlayerId -> CastRepetition.CastRepetition -> Bool -> CastOffer.CastOffer -> Game [ObjectId]
offerCast runSubgame context evaluate named caster optionality verb retake repetition copied offer = do
  subjects <- if copied then Maybe.catMaybes <$> traverse (Common.castableCopy caster) named else pure named
  case repetition of
    CastRepetition.Once -> foldMap (Maybe.maybeToList . snd) <$> offerCastOnce runSubgame context subjects caster optionality verb retake offer
    CastRepetition.AnyNumber -> again Nothing subjects
    CastRepetition.WithinTotalManaValue quantity -> again (Just (Maybe.fromMaybe 0 (evaluate quantity))) subjects
  where
    again budget remaining = do
      let capped total = offer {CastOffer.restriction = Just (maybe (Filter.Type.Measures (Measures.MkMeasures Measure.ManaValue Comparison.AtMost (Operand.Literal total))) (\r -> Filter.Type.And [r, Filter.Type.Measures (Measures.MkMeasures Measure.ManaValue Comparison.AtMost (Operand.Literal total))]) (CastOffer.restriction offer))}
      taken <- offerCastOnce runSubgame context remaining caster optionality verb retake (maybe offer capped budget)
      case taken of
        Nothing -> pure []
        Just (oid, spell) -> do
          gs <- State.get
          let spent = Maybe.fromMaybe 0 (spell >>= Projection.fullView gs >>= Filter.manaValue)
          (Maybe.maybeToList spell <>) <$> again (fmap (subtract spent) budget) (filter (/= oid) remaining)

-- CR 707.13 / 707.14: offer the cast of a copy of this printing created outside
-- the game (Event.mintOutside), bracketing `offerCast` with the mint and the
-- discard. An uncast copy is deleted as the offer returns: CR 109.1 and CR
-- 400.11c leave nothing able to observe it afterwards, and it bounds
-- Object.zone's placeholder to one resolution, in which no player gets priority
-- and no SBA is checked.
offerOutsideCopy :: Game Result -> Filter.Context -> PlayerId -> PrintingId.PrintingId -> CastOffer.CastOffer -> Game ()
offerOutsideCopy runSubgame context caster printingId offer = do
  copyId <- State.state (Event.mintOutside caster printingId)
  Monad.void (offerCast runSubgame context (const Nothing) [copyId] caster CastObligation.Optional PermissionVerb.Cast Nothing CastRepetition.Once False offer)
  State.modify' $ \g ->
    if Set.member copyId (GameState.outsideCopies g)
      then g {GameState.objects = Map.delete copyId (GameState.objects g), GameState.outsideCopies = Set.delete copyId (GameState.outsideCopies g)}
      else g

-- One round of the offer above: CR 601.3's choice among the cards `named` still
-- holds, and the cast if it is taken. Answers the id of the card that was cast,
-- which is what tells the caller whether to go round again, beside the spell
-- CR 601.2a put on the stack, which a land play and CR 601.2e's reversal lack.
--
-- The four questions, in the order the rules ask them:
--
--   1. IS THERE ANYTHING TO OFFER -- an id the reference named (CR 400.7) may no
--      longer resolve to an object (CR 603.7c).
--   2. WHICH FACE: CR 712.11a for the `transformed` rider, otherwise
--      Game.castableFacesOf (CR 709.3, CR 712.11b, CR 715.3, CR 720.3) plus CR
--      702.102a's fused face for a fuse card in the caster's hand, less the face
--      CR 702.162a's or CR 702.146a's alternative cost is the only road to, when
--      this offer states an alternative cost of its own (CR 118.9a).
--   3. WHAT IT COSTS (CR 118.9): `withoutPayingManaCost` or a stated
--      `payingInstead` (CR 702.94a); otherwise CR 601.2b's own candidates, and
--      how mana may be spent toward it (CR 118.14's `spending`).
--   4. MAY IT BE CAST AT ALL -- Cast.castableWhenOffered, asked BEFORE the
--      prompt so no cast is offered that the announcement would reverse, and
--      beside it whatever quality the offer's own CastOffer.restriction states of
--      the resulting spell (CR 702.85a).
--
-- Questions 3 and 4 are asked of EACH half of EACH named card separately (CR
-- 709.3a, CR 712.11c); where more than one survives, CR 601.3's choice is put to
-- the caster before
-- the "may" below, since CR 118.8c's excuse is a property of the spell being
-- cast. At CastObligation.Mandatory the cast is not a decision, so
-- Prompt.OfferedCast is elided; question 4 is what a printed "if able" comes to
-- (CR 601.3, CR 609.3). CR 118.8c is the exception: `excused` turns the
-- mandatory branch back into a may, classified by Cost.statesHiddenQuality.
--
-- The caster is a parameter and not the resolving controller: CR 608.2g says "a
-- player". Everything above is a CLASSIFICATION carried by the opcode's
-- CastOffer and its CastObligation; nothing here asks which card is offered.
--
-- Under PermissionVerb.Play a named land is offered too, as CR 305.2a's land
-- play during a resolution (CR 601.1a's "play"), under the special action's
-- per-player limits (Cast.landDropOpen: CR 305.2b, 305.3) and CR 305.1's
-- prohibitions, and not its phase or empty stack, which an instruction lifts.
-- Parun.GameSpec's "CR 305.2a gameplay: Word of Command makes bob play a land
-- on his turn" proves it.
--
-- `retake` is CR 723.2's second span: the player who controls the caster while
-- the spell this cast makes resolves (Word of Command). Keyed to the spell's
-- own id, which is the one object CR 608.2g puts on top of the stack.
offerCastOnce :: Game Result -> Filter.Context -> [ObjectId] -> PlayerId -> CastObligation.CastObligation -> PermissionVerb.PermissionVerb -> Maybe PlayerId -> CastOffer.CastOffer -> Game (Maybe (ObjectId, Maybe ObjectId))
offerCastOnce runSubgame context named caster optionality verb retake offer = do
  gs <- State.get
  let -- Whether this offer states CR 118.9's alternative cost, in either of the
      -- two wordings `applied` below reads. NOT `transformed`, which is CR
      -- 712.11a's rider about which face goes on the stack and says nothing about
      -- payment.
      alternative = CastOffer.withoutPayingManaCost offer || Maybe.isJust (CastOffer.payingInstead offer)
      -- CR 712.11a for the transformed rider; CR 709.3, CR 712.11b, CR 715.3 and
      -- CR 720.3 otherwise, via Game.castableFacesOf. Nothing for a card with no back face
      -- (CR 712.14a): an offer that cannot be made is not made.
      --
      -- Less Card.convertedFace under an alternative, which is CR 118.9a: a spell
      -- takes one alternative cost, and that face is on the list only because CR
      -- 702.162a's or CR 702.146a's alternative cost put it there, so an offer
      -- spending the spell's one alternative on something else cannot also reach
      -- it. CR 712.11's default -- the front face -- is then the whole answer.
      --
      -- Unobserved for rule 702.146a's half: no board in the pool offers a cast
      -- of a disturb card under an alternative cost of the offer's own, so only
      -- rule 702.162a's limb is driven (Parun.InvestigateSpec's "CR 118.9a a free
      -- offer does not also offer the converted face").
      --
      -- Game.castableFacesOf carries the HALVES and never Card.fusedFace, so rule
      -- 702.102a's third offer is added here, beside them and never instead of
      -- them: "if a player casts a split card with fuse FROM THEIR HAND, the
      -- player may choose to cast both halves of that split card rather than
      -- choose one half". CR 608.2g's offer is a permission about a zone, so it
      -- reaches that cast exactly as the ordinary action does; which of the three
      -- is taken stays the caster's choice below.
      --
      -- THE ZONE is the rule's own -- fuse "applies while the card with fuse is in
      -- a player's hand" -- and so is the SEAT: "from their hand", which CR 400.3
      -- makes the owner's, the seat Game.zoneMembers indexes a hand by. So an
      -- offer letting a player cast out of somebody ELSE'S hand (Sen Triplets,
      -- see #2169) offers that card's halves alone -- the rule's own narrowing
      -- and not an elision. Parun.Engine.Cast.castableSpells'
      -- fusedProposals is this same offer on the ordinary-action road, and the two
      -- read the same zone for the same reason.
      --
      -- FACE UP alone, that road's other narrowing: `faces` below offers a
      -- face-down cast its one proposal before this is asked.
      fusedFaces oid
        | elem oid (Game.zoneMembers Zone.Hand caster gs) = Maybe.maybeToList (Cast.fusedFaceOf oid gs)
        | otherwise = []
      -- CR 708.4: CastOffer.faceDown's cast is turned face down before it is put
      -- onto the stack, as CR 708.2a's 2/2 under the offer's own reason and with
      -- the events the offer turns it face up before; every other offer is cast
      -- face up.
      facing = case CastOffer.faceDown offer of
        Nothing -> Facing.FaceUp
        Just events -> Facing.FaceDown FaceDownState.MkFaceDownState {FaceDownState.reason = FaceDownReason.CastFaceDown, FaceDownState.listed = FaceDownCharacteristics.defaultValue, FaceDownState.turnsUpBefore = events}
      faces oid card
        -- A face-down spell has no halves to choose among (CR 708.2 leaves it
        -- the listed characteristics alone), so the card is proposed once,
        -- under its front face's name -- the face it shows when turned up.
        | Facing.isFaceDown facing = Just [Card.frontFace card]
        | CastOffer.transformed offer = fmap pure (Card.backFace card)
        | alternative = Just (filter (\face -> fmap Face.name (Card.convertedFace card) /= Just (Face.name face)) (Game.castableFacesOfId oid gs) <> fusedFaces oid)
        | otherwise = Just (Cast.castableFacesFor oid gs <> fusedFaces oid)
      -- One proposal per half, gated on its own (CR 709.3a, CR 712.11c), which
      -- is why the whole tuple is built per face rather than once per card.
      --
      -- The excuse below being the HALF's and not the card's is what CR 709.3a
      -- makes it, and Parun.InvestigateSpec's "CR 118.8c the excuse is the half's,
      -- so one half is offered and the other forced" is the board that proves it:
      -- one mandatory offer of a split card whose front half states a hidden-zone
      -- additional cost and whose back half states none.
      proposal oid face =
        let name = Face.name face
            -- CR 118.9a: at most ONE alternative cost, so the applied one
            -- replaces the candidates rather than joining them; the two riders
            -- are asked in order, free first. CR 118.9d in both cases -- an
            -- alternative replaces only the MANA cost, so the face's additional
            -- costs ride along.
            --
            -- CR 601.2b's tag rides along: an offer stating which keyword
            -- ability is behind its cost (rule 702.62a's third ability and rule
            -- 702.35a's second) hands that keyword to the candidate, so the cast
            -- records it as Object.castUsing exactly as a printed alternative does.
            -- CastOffer.offeredBy is Nothing for every other offer, which is
            -- Cost.untagged's own value.
            --
            -- One offer can still be SEVERAL candidates, and CR 118.8's choice
            -- costs are why: the face's additional costs ride the applied cost,
            -- and one of them may offer the caster a choice of payments, which
            -- Cost.choiceVariants expands here exactly as it does for a cast the
            -- board itself offers. CR 702.48a's offering is the other optional
            -- additional cost, and Cost.withOffering adds it the same way.
            appliedOne
              | CastOffer.withoutPayingManaCost offer = Just (CandidateCost.plain (CastOffer.offeredBy offer) (Cost.withoutPayingManaCost priced))
              | otherwise = fmap (\c -> CandidateCost.plain (CastOffer.offeredBy offer) (c {Cost.Type.components = Cost.Type.components c <> Face.additionalCosts priced})) (CastOffer.payingInstead offer)
            applied = concatMap (Cost.withOffering caster oid proposed) (concatMap (Cost.choiceVariants priced) (Maybe.maybeToList appliedOne))
            -- CR 708.4: a cast proposed face down is measured against the
            -- face-down characteristics, so it is the stamped state's face that
            -- prices it and carries the additional costs -- none, CR 708.2a's 2/2
            -- printing no text.
            proposed = Cast.asProposed oid name facing gs
            priced = if Facing.isFaceDown facing then Maybe.fromMaybe face (Cast.proposedFace oid name proposed) else face
            -- CR 601.2f: the offer's own reduction (CastOffer.reduction) rides
            -- every candidate, the printed cost and an alternative alike, so it
            -- applies after any increase. The cast is then handed these
            -- candidates rather than finding its own, which are the same list.
            lessened candidate = candidate {CandidateCost.reductions = CandidateCost.reductions candidate <> [ManaCost.MkManaCost [ManaSymbol.Generic (CastOffer.reduction offer)]]}
            candidates
              | CastOffer.reduction offer == 0 = if null applied then Cost.candidateCostsGiven True caster name oid proposed else applied
              | otherwise = fmap lessened (if null applied then Cost.candidateCostsGiven True caster name oid proposed else applied)
            announced = if CastOffer.reduction offer == 0 then applied else candidates
         in -- CR 702.85a's second condition, asked of THIS HALF: the offer may
            -- state a quality the resulting spell must have, and CR 709.3a makes
            -- that a per-half question like the two above. Against the face's own
            -- view and the resolution's context, so a source-comparing atom reads
            -- the same source the reference did. An offer stating none narrows
            -- nothing.
            if maybe True (Filter.matches context (Projection.viewOfCard face)) (CastOffer.restriction offer)
              && Cast.castableWhenOffered (CastOffer.spending offer) caster oid name candidates proposed
              then
                -- CR 118.8c, read off the same candidates the cast will be
                -- announced with: CR 118.9d keeps the face's additional costs on
                -- an alternative, so every candidate already carries them. A
                -- cost APPLIED from another effect (CR 118.8) is appended by
                -- Cost.plusComponents, the funnel Cast.payableCostAt measures
                -- through. Parun.InvestigateSpec's "CR 118.8c an additional cost
                -- another effect applies excuses the cast too" proves it.
                let excused = any (Cost.statesHiddenQuality . Cost.plusComponents (Cost.spellAdjustments Map.empty caster oid proposed) . CandidateCost.cost) candidates
                 in Just (oid, name, announced, excused)
              else Nothing
      -- EVERY object the reference names, each contributing one entry per
      -- castable half (CR 709.3a) -- Shell of the Last Kappa's whole exiled pile
      -- as readily as Tinybones, the Pickpocket's one target. The caller's
      -- objectRefObjects is what makes the two the same read.
      offers =
        concatMap
          ( \oid -> Maybe.fromMaybe [] $ do
              card <- Game.cardOf oid gs
              fmap (Maybe.mapMaybe (proposal oid)) (faces oid card)
          )
          named
      -- One entry per land face (CR 712.12), beside the spells above, which
      -- hold no land face (CR 305.9, Cast.printedRestrictionsOk), so no pair is
      -- offered both ways.
      landOffers
        | verb == PermissionVerb.Play && Cast.landDropOpen caster gs =
            [ (oid, mName, Face.name face)
            | oid <- named,
              -- CR 406.3a: judged on the card turned up, as Cast.asProposed does
              -- for a cast, so a land exiled face down shows its name.
              not (PlayerEffect.prohibitsPlayingLand caster oid (Cast.turnedUpForPlay oid Facing.FaceUp gs)),
              Just obj <- [Game.lookupObject oid gs],
              Just card <- [Game.cardOf oid gs],
              (mName, face) <- Game.landFacesOf obj card
            ]
        | otherwise = []
      everything = fmap Left landOffers <> fmap Right offers
      keyOf entry = case entry of
        Left (oid, _, name) -> (oid, name)
        Right (oid, name, _, _) -> (oid, name)
  -- No survivor is no offer; one survivor is one outcome, so CR 601.3's choice is
  -- elided there rather than asked.
  chosen <- case everything of
    [] -> pure Nothing
    [sole] -> pure (Just sole)
    first : rest -> do
      let decider = Decide.deciderFor caster gs
      picked <- Game.choose (Prompt.ChooseOfferedCastSpell decider caster (fmap keyOf (first NonEmpty.:| rest)))
      -- Reject-not-repair: a pair the offer did not include is no cast at all.
      -- The PAIR and not the name alone, for castWhileSearching's reason: one
      -- card's half must not answer another card's.
      pure (List.find ((== picked) . keyOf) everything)
  let -- The SAME prompt on both paths: CR 118.8c creates no new decision. A land
      -- play's "may" is this prompt too.
      mayDo oid name act = do
        let decider = Decide.deciderFor caster gs
        decision <- Game.choose (Prompt.OfferedCast decider caster oid name)
        case decision of
          OptionalDecision.Declines -> pure Nothing
          OptionalDecision.Exercises -> act
  case chosen of
    Nothing -> pure Nothing
    Just (Left (oid, mName, name)) -> do
      let play = do
            Cast.playLand True caster oid mName
            pure (Just (oid, Nothing))
      case optionality of
        CastObligation.Mandatory -> play
        CastObligation.Optional -> mayDo oid name play
    Just (Right (oid, name, applied, excused)) -> do
      let cast = do
            stackBefore <- State.gets GameState.stack
            Cast.castSpellWith (performManaAbility runSubgame) False True applied (CastOffer.spending offer) caster oid name facing
            -- CR 608.2g: the spell is the new topmost object. A cast that was
            -- reversed put nothing new on top.
            stackAfter <- State.gets GameState.stack
            let spell = case stackAfter of
                  sid : _ | notElem sid stackBefore -> Just sid
                  _ -> Nothing
            -- CR 723.2's second span, dormant until the spell resolves
            -- (Parun.Engine.Stack.resolveTopWith). A reversed cast waits on
            -- nothing.
            case (retake, spell) of
              (Just controller, Just sid) -> do
                stamp <- State.state Game.freshTimestamp
                State.modify' $
                  Common.pushControl
                    caster
                    PlayerControl.MkPlayerControl
                      { PlayerControl.decider = Decider.MkDecider controller,
                        PlayerControl.duration = ControlDuration.WhileResolving sid,
                        -- CR 723.7: Word of Command's mana clause is
                        -- "while doing so", the playing of the card.
                        PlayerControl.manaFromLandsOnly = False,
                        PlayerControl.timestamp = stamp
                      }
              _ -> pure ()
            pure (Just (oid, spell))
      case optionality of
        CastObligation.Mandatory | not excused -> cast
        CastObligation.Mandatory -> mayDo oid name cast
        CastObligation.Optional -> mayDo oid name cast

-- One effect, applied, wrapped in the window CR 607.2a's link is filed from:
-- what was in exile before, and what is in it after.
--
-- CR 609.1: and performed as the effect of a spell or ability `controller`
-- controls (Event.causedBy), the one door every instruction of a spell, an
-- ability, a mana ability and a replacement's own effects goes through, so the
-- moves it makes record their cause. Sacred Ground's scenarios prove it.
applyEffectWith :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
applyEffectWith runSubgame resolving source controller legal chosen effect = Event.causedBy (Just controller) $ do
  before <- State.gets GameState.exile
  -- Read BEFORE the effect runs, while the resolving ability is surely still an
  -- object to read.
  ability <- State.gets (resolvingAbilityName resolving)
  applyOneEffect runSubgame resolving source controller legal chosen effect
  State.modify' (Common.recordExiledWith ExileLink.MkExileLink {ExileLink.source = source, ExileLink.ability = ability} before)
  State.modify' (Common.recordExilePile before)
  -- CR 614.1c: the as-enters effects of what this instruction put onto the
  -- battlefield, before the next instruction reads the board. After the window
  -- above, so what they exile is filed by their own windows, not this one's.
  runEntryEffects runSubgame
  -- CR 614.1a: what a replacement put in a lost game's place (Lich's Mirror),
  -- before the next instruction reads the board. A fence rather than a proof:
  -- no test loses a player the game mid-resolution and reads the board after,
  -- so Engine.performSettle's drain answers every test the same without it.
  runReplacementEffects runSubgame
  -- CR 603.4: the board this instruction's events left, before the next one
  -- changes it. data/scenarios/trigger's Slaughterhouse Bouncer scenario proves
  -- it.
  State.modify' Trigger.fileBoards

-- One effect, applied. `runSubgame` is the injected nested-game runner; only
-- the PlaySubgame arm consults it.
--
-- `controller` is the controller of the resolving spell or ability, never the
-- effect `source`, which for an ability may already have been sacrificed as a
-- cost. Every arm evaluating a Quantity views through
-- `effectViewOf source legal gs` (CR 608.2h).
--
-- `resolving` is the object ON THE STACK -- the spell, or the ABILITY object --
-- where every slot this fold defines is bound, where CR 603.7c's captured
-- environment is read back, and where CR 601.2b's announced X lives. Not
-- `source`: for an ability the two differ (CR 113.7a), and that permanent can be
-- gone before a later effect of the same list runs.
applyOneEffect :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
applyOneEffect runSubgame resolving source controller legal chosen effect = case effect of
  Effect.DealDamage payload -> Damage.dealDamage runPreventionRiders runReplacementEffects runSubgame resolving source controller legal payload
  Effect.Fight payload -> Damage.fight runPreventionRiders runReplacementEffects runSubgame legal payload
  Effect.ModifyTarget payload -> Damage.modifyTarget resolving source controller legal chosen payload
  Effect.ChangeText payload -> Damage.changeText resolving source controller legal payload
  Effect.AddMana payload -> Damage.addMana resolving source controller legal payload
  Effect.ActivateManaAbilities payload -> Damage.activateManaAbilities performManaAbility runSubgame resolving source controller legal payload
  Effect.MoveMana payload -> Damage.moveMana resolving source controller legal payload
  Effect.Search payload -> Damage.search performManaAbility runSubgame resolving source controller legal payload
  Effect.ExileAllGraveyards -> Damage.exileAllGraveyards source controller
  Effect.ExileHandThenDraw -> Damage.exileHandThenDraw controller
  Effect.NoteManaSpent -> Damage.noteManaSpent resolving source
  Effect.RestartGame payload -> Damage.restartGame performHandAction runSubgame resolving source controller legal payload
  Effect.PlaySubgame payload -> Damage.playSubgame runSubgame resolving payload
  Effect.ChoosePlayer payload -> Damage.choosePlayer resolving source controller payload
  Effect.ChoosePlayerAtRandom payload -> Damage.choosePlayerAtRandom resolving source controller payload
  Effect.ChoosePermanents payload -> Damage.choosePermanents resolving source controller legal payload
  Effect.ChooseSector payload -> Damage.chooseSector resolving source controller payload
  Effect.RollDie payload -> Damage.rollDieArm throwDice runSubgame resolving source controller legal payload
  Effect.Reroll -> Damage.reroll
  Effect.RerollStoredResults payload -> Damage.rerollStoredResults throwDice runSubgame resolving source controller legal payload
  Effect.FlipCoin payload -> Damage.flipCoinArm throwForCoin runSubgame resolving source controller legal payload
  Effect.Guess payload -> Zones.guess resolving source controller legal chosen payload
  Effect.ControlPlayerNextTurn payload -> Damage.controlPlayerNextTurn controller legal payload
  Effect.ControlPlayerThisResolution payload -> Damage.controlPlayerThisResolution controller legal payload
  Effect.Destroy payload -> Damage.destroy resolving source controller legal chosen payload
  Effect.Sacrifice payload -> Damage.sacrifice resolving source controller legal chosen payload
  Effect.TurnFaceDown payload -> Damage.turnFaceDown resolving source controller legal payload
  Effect.TurnFaceUp payload -> Damage.turnFaceUp resolving source controller legal payload
  Effect.RemoveFromCombat payload -> Damage.removeFromCombat resolving source controller legal payload
  Effect.BecomesBlocked payload -> Damage.becomesBlocked legal payload
  Effect.SwitchBlockers payload -> Damage.switchBlockers legal payload
  Effect.ExchangeBlocks payload -> Damage.exchangeBlocks legal payload
  Effect.MoveToZone payload -> Zones.moveToZone resolving source controller legal chosen payload
  Effect.ExchangeZones payload -> Zones.exchangeZones resolving source controller legal payload
  Effect.ExchangeCardZones payload -> Zones.exchangeCardZones resolving source controller legal chosen payload
  Effect.ShuffleIntoLibrary payload -> Zones.shuffleIntoLibrary resolving source controller legal payload
  Effect.SetOwner payload -> Zones.setOwner resolving source controller legal payload
  Effect.ExchangeOwnership payload -> Zones.exchangeOwnership resolving source controller legal payload
  Effect.Ante payload -> Zones.ante resolving source controller legal payload
  Effect.PutSticker payload -> Zones.putSticker resolving source controller legal chosen payload
  Effect.Shuffle payload -> Zones.shuffle resolving source controller legal payload
  Effect.OfferCast payload -> Zones.offerCastArm offerCast runSubgame resolving source controller legal chosen payload
  Effect.OfferNamedCopy payload -> Zones.offerNamedCopy offerOutsideCopy runSubgame resolving source controller legal payload
  Effect.OfferNotedCopy payload -> Zones.offerNotedCopy offerOutsideCopy runSubgame resolving source controller legal payload
  Effect.GrantPlayFromExile payload -> Zones.grantPlayFromExile resolving source controller legal payload
  Effect.GrantLookAtExiled payload -> Zones.grantLookAtExiled resolving source controller legal payload
  Effect.MakePlotted payload -> Zones.makePlotted resolving source controller legal payload
  Effect.MakeForetold payload -> Zones.makeForetold resolving source controller legal payload
  Effect.MakeWarped payload -> Zones.makeWarped resolving source controller legal payload
  Effect.Heal payload -> Zones.healArm resolving source controller legal payload
  Effect.ForEach payload -> Zones.forEach applyEffectWith loopOffers runSubgame resolving source controller legal chosen payload
  Effect.ForEachNumber payload -> Zones.forEachNumber applyLoopBody runSubgame resolving source controller legal chosen payload
  Effect.Repeat payload -> Zones.repeatArm applyLoopBody runSubgame resolving source controller legal chosen payload
  Effect.RepeatIf payload -> Zones.repeatIf applyLoopBody runSubgame resolving source controller legal chosen payload
  Effect.Draw payload -> Zones.draw resolving source controller legal payload
  Effect.Mill payload -> Zones.mill resolving source controller legal payload
  Effect.Reveal payload -> Zones.reveal resolving source controller legal chosen payload
  Effect.LookAt payload -> Zones.lookAt resolving source controller legal payload
  Effect.ArrangeInLibrary payload -> Zones.arrangeInLibrary resolving source controller legal payload
  Effect.Scry payload -> Zones.scry resolving source controller legal payload
  Effect.Surveil payload -> Zones.surveil resolving source controller legal payload
  Effect.Fateseal payload -> Zones.fateseal resolving source controller legal payload
  Effect.Clash payload -> Zones.clash resolving source controller payload
  Effect.AsYouCascade payload -> Zones.asYouCascade applyOneEffect runSubgame resolving source controller legal chosen payload
  Effect.Explore payload -> Zones.explore resolving source controller legal payload
  Effect.Connive payload -> Zones.connive resolving source controller legal payload
  Effect.Discard payload -> Zones.discard resolving source controller legal chosen payload
  Effect.LoseLife payload -> Zones.loseLife resolving source controller legal payload
  Effect.GainLife payload -> Zones.gainLife resolving source controller legal payload
  Effect.ExchangeLifeTotals payload -> Zones.exchangeLifeTotals controller legal payload
  Effect.ExchangeValues payload -> Zones.exchangeValues resolving source controller legal payload
  Effect.SetLifeTotal payload -> Zones.setLifeTotal resolving source controller legal payload
  Effect.LoseGame payload -> Zones.loseGame resolving source controller legal payload
  Effect.WinGame payload -> Zones.winGame resolving source controller legal payload
  Effect.DrawGame -> Zones.drawGame source controller
  Effect.RedistributeLifeTotals -> Zones.redistributeLifeTotals source controller
  Effect.IncreaseSpeed payload -> Zones.increaseSpeed resolving source controller legal payload
  Effect.DecreaseSpeed payload -> Zones.decreaseSpeed resolving source controller legal payload
  Effect.PlayerSacrifices payload -> Zones.playerSacrifices resolving source controller legal payload
  Effect.Vote payload -> Zones.vote resolving source controller legal payload
  Effect.Bid payload -> Zones.bid resolving source controller legal payload
  Effect.Create payload -> Objects.create resolving source controller legal chosen payload
  Effect.Conjure payload -> Objects.conjure resolving source controller legal payload
  Effect.CreateCopy payload -> Objects.createCopy resolving source controller legal chosen payload
  Effect.BecomeCopy payload -> Objects.becomeCopy resolving source controller legal payload
  Effect.CopyStackObject payload -> Objects.copyStackObject resolving source controller legal payload
  Effect.ChooseNewTargets payload -> Objects.chooseNewTargets resolving source controller legal payload
  Effect.ChangeTargets payload -> Objects.changeTargets resolving source controller legal payload
  Effect.ArmDelayedTrigger payload -> Objects.armDelayedTrigger resolving source controller legal payload
  Effect.Replace payload -> Objects.replace resolving source controller legal payload
  Effect.PreventNextDamage payload -> Objects.preventNextDamage resolving source controller legal chosen payload
  Effect.PreventAllDamage payload -> Objects.preventAllDamage resolving source controller legal chosen payload
  Effect.PreventNextDamageInstance payload -> Objects.preventNextDamageInstance resolving source controller legal chosen payload
  Effect.RedirectDamage payload -> Objects.redirectDamage resolving source controller legal payload
  Effect.SkipPhase payload -> Objects.skipPhase resolving source controller legal payload
  Effect.AffectPlayers payload -> Objects.affectPlayers resolving source controller legal payload
  Effect.RequireBlock payload -> Objects.requireBlock resolving source controller legal payload
  Effect.Prohibit payload -> Objects.prohibit resolving source controller legal payload
  Effect.ForbidAttack payload -> Objects.forbidAttack resolving source controller legal payload
  Effect.ForbidBeingBlocked payload -> Objects.forbidBeingBlocked resolving source controller legal payload
  Effect.RequireAttack payload -> Objects.requireAttack resolving source controller legal payload
  Effect.CreateEmblem payload -> Objects.createEmblem controller payload
  Effect.BecomeMonarch payload -> Objects.becomeMonarch resolving source controller legal payload
  Effect.TakeTheInitiative payload -> Objects.takeTheInitiative resolving source controller legal payload
  Effect.Designate payload -> Objects.designate resolving source controller legal payload
  Effect.SetClassLevel payload -> Objects.setClassLevel legal payload
  Effect.Unsuspect payload -> Objects.unsuspectArm resolving source controller legal payload
  Effect.SetHalfLocked payload -> Objects.setHalfLocked controller legal payload
  Effect.BecomeProtector payload -> Objects.becomeProtector controller legal payload
  Effect.CounterAndMark payload -> Objects.counterAndMark controller legal payload
  Effect.Mentor payload -> Objects.mentor source controller legal payload
  Effect.Exploit -> Objects.exploit resolving source controller legal
  Effect.GiveGift -> Objects.giveGift controller
  Effect.ItBecomes payload -> Objects.itBecomes payload
  Effect.Attach payload -> Objects.attach resolving source legal payload
  Effect.AttachAsThoughCreature payload -> Objects.attachAsThoughCreature source legal payload
  Effect.AttachTarget payload -> Objects.attachTarget resolving source controller legal payload
  Effect.AttachTargetToEach payload -> Objects.attachTargetToEach resolving source controller legal payload
  Effect.AttachBound payload -> Objects.attachBound resolving source controller legal payload
  Effect.AttachAll payload -> Objects.attachAll resolving source controller legal chosen payload
  Effect.Unattach payload -> Objects.unattach resolving source controller legal chosen payload
  Effect.ExileHaunting payload -> Objects.exileHaunting resolving legal payload
  Effect.Counter payload -> Counters.counter resolving source controller legal payload
  Effect.PutCounters payload -> Counters.putCounters resolving source controller legal chosen payload
  Effect.Divide payload -> Counters.divide resolving source controller legal payload
  Effect.PutCountersFrom payload -> Counters.putCountersFrom resolving source controller legal payload
  Effect.ChooseCardName payload -> Counters.chooseCardName resolving source controller legal payload
  Effect.ChooseQuality payload -> Counters.chooseQuality resolving source controller payload
  Effect.FromOutsideTheGame payload -> Counters.fromOutsideTheGame source controller payload
  Effect.ExileThisSpell -> Counters.exileThisSpell resolving
  Effect.RemoveCounters payload -> Counters.removeCounters resolving source controller legal payload
  Effect.RemoveCountersAmong payload -> Counters.removeCountersAmong resolving source controller legal payload
  Effect.MoveCounters payload -> Counters.moveCounters resolving source controller legal payload
  Effect.Proliferate -> Counters.proliferate source controller
  Effect.Bolster payload -> Counters.bolster resolving source controller legal payload
  Effect.Earthbend payload -> Counters.earthbendArm applyEffectWith runSubgame resolving source controller legal chosen payload
  Effect.Airbend payload -> Counters.airbend applyEffectWith runSubgame resolving source controller legal chosen payload
  Effect.Firebend payload -> Counters.firebend applyEffectWith runSubgame resolving source controller legal chosen payload
  Effect.Amass payload -> Counters.amass resolving source controller legal payload
  Effect.Blight payload -> Counters.blight resolving source controller legal payload
  Effect.TemptWithTheRing -> Counters.temptWithTheRing controller
  Effect.OpenAttraction -> Counters.openAttraction controller
  Effect.Assemble payload -> Counters.assemble resolving source controller legal payload
  Effect.Planeswalk -> Counters.planeswalk resolving controller
  Effect.ChaosEnsues -> Counters.chaosEnsues
  Effect.Abandon -> Counters.abandon source
  Effect.ClaimPrize -> Counters.claimPrize controller
  Effect.Forage -> Counters.forage resolving controller
  Effect.Populate -> Counters.populate resolving controller
  Effect.TimeTravel -> Counters.timeTravel resolving controller
  Effect.Recruit -> Counters.recruit controller
  Effect.Learn -> Counters.learn resolving source controller
  Effect.Cloak payload -> Counters.cloak resolving source controller legal payload
  Effect.ManifestDread payload -> Counters.manifestDread resolving source controller legal payload
  Effect.Venture payload -> Counters.venture controller payload
  Effect.GainPlayerCounters payload -> Counters.gainPlayerCounters resolving source controller legal payload
  Effect.RemovePlayerCounters payload -> Counters.removePlayerCounters resolving source controller legal payload
  Effect.PayAnyEnergy payload -> Counters.payAnyEnergy resolving source controller payload
  Effect.ChooseNumber payload -> Counters.chooseNumber resolving source controller legal payload
  Effect.BindAmount payload -> Counters.bindAmount resolving source controller legal payload
  Effect.Tap payload -> Counters.tap resolving source controller legal payload
  Effect.Untap payload -> Counters.untap resolving source controller legal chosen payload
  Effect.Detain payload -> Counters.detain resolving source controller legal payload
  Effect.Goad payload -> Counters.goad resolving source controller legal payload
  Effect.Pair payload -> Counters.pair resolving source controller legal chosen payload
  Effect.DoesNotUntapNext payload -> Counters.doesNotUntapNext resolving source controller legal payload
  Effect.Transform payload -> Counters.transform resolving source controller legal chosen payload
  Effect.Convert payload -> Counters.convert resolving source controller legal chosen payload
  Effect.Flip payload -> Counters.flipArm resolving source controller legal payload
  Effect.Meld payload -> Counters.meld resolving source controller legal payload
  Effect.PhaseOut payload -> Counters.phaseOut resolving source controller legal payload
  Effect.AddPhases payload -> Counters.addPhases payload
  Effect.EndTurn -> Counters.endTurn runDamageRewriteEffect runReplacementEffects runSubgame
  Effect.EndCombatPhase -> Counters.endCombatPhase runDamageRewriteEffect runReplacementEffects runSubgame
  Effect.GainControl payload -> Counters.gainControl resolving source controller legal payload
  Effect.ExchangeControl payload -> Counters.exchangeControl resolving source controller legal payload
  Effect.TakeExtraTurn payload -> Counters.takeExtraTurnArm resolving source controller legal payload

-- The no-subgame executor, for a test that drives one effect directly: a
-- PlaySubgame resolves as a draw here (see noSubgame).
applyEffect :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
applyEffect = applyEffectWith Common.noSubgame

-- CR 615.5: run the additional effect of every prevention that has just been
-- applied. Drains GameState.pendingPreventionRiders, which Parun.Engine.Damage
-- filled -- that module is below this one and cannot run a card's effects. Every
-- caller runs it before the board can be observed and before the next
-- state-based action check, and that ordering IS the rule: a 1/1 dealt 6 through
-- Test of Faith ends as a 4/4 rather than dying to CR 704.5g first. Emptied
-- BEFORE the riders run, so a rider whose own damage is prevented appends to a
-- fresh queue instead of being re-run here.
runPreventionRiders :: Game Result -> Game ()
runPreventionRiders runSubgame = do
  queued <- State.gets GameState.pendingPreventionRiders
  State.modify' (\gs -> gs {GameState.pendingPreventionRiders = Seq.empty})
  Foldable.traverse_ (runPreventionRider runSubgame) queued

-- One queued prevention's additional effect; nothing runs unless the prevention
-- carries a rider.
--
-- Run ONCE PER SOURCE the application covered, ascending by id, each run with
-- that source bound under the reserved Binding.preventedDamageSource and that
-- source's own amount: Comeuppance deals each attacker the damage prevented from
-- it, and Deflecting Palm's "that source's controller" reads the one source
-- bound. CR 615.5's "amount of damage that was prevented" is the SUM over the
-- recipients this application covered from that source, rule 615.13 counting
-- the application and not the recipients (Divine Deflection throws one lot of
-- 3, not a 2 and a 1). The amount is a Quantity.InSlot read of the reserved
-- Binding.eventAmount slot, published through GameState.ambientAmounts rather
-- than bound onto an object, because the shielded recipient may be a PLAYER.
-- Restored rather than cleared, so this cannot clobber an outer amount.
--
-- `resolving` and `source` are both the rider's own source (CR 113.7). Every slot
-- the rider names is treated as a LEGAL target, CR 608.2b having been applied
-- when the installing spell resolved.
runPreventionRider :: Game Result -> Prevention.Prevention -> Game ()
runPreventionRider runSubgame prevention = Foldable.for_ (Prevention.rider prevention) $ \rider ->
  Foldable.for_ (Map.toAscList (Prevention.amounts prevention)) $ \(damager, share) -> do
    was <- State.gets GameState.ambientAmounts
    State.modify' (\gs -> gs {GameState.ambientAmounts = Map.insert Binding.eventAmount (sum share) was})
    let targets = Map.insert Binding.preventedDamageSource (Set.singleton (Recipient.ToObject damager)) (PreventionRider.targets rider)
        src = PreventionRider.source rider
    Monad.void (runCarrying runSubgame src (PreventionRider.controller rider) Map.empty targets (PreventionRider.effects rider))
    State.modify' (\gs -> gs {GameState.ambientAmounts = was})

-- CR 614.1c: run the effects of every as-enters rewrite that has applied and not
-- run yet. Drains GameState.pendingEntryEffects, which Parun.Engine.Event filled
-- -- runPreventionRiders above in every structural respect and for the same
-- reason. Emptied before the effects run.
--
-- Two callers. applyEffectWith runs it as each instruction finishes, so a later
-- instruction of the same resolution reads the board the effects left (CR
-- 608.2h) -- Parun.FaceDownSpec's "CR 614.1c / 608.2h the reanimated Ixidron's
-- power is read after its own sweep" proves it. Parun.Engine.Engine.performSettle
-- runs it for every other road onto the battlefield (a permanent spell, a land
-- play), before the SBA pass and the trigger scan.
runEntryEffects :: Game Result -> Game ()
runEntryEffects runSubgame = do
  queued <- State.gets GameState.pendingEntryEffects
  State.modify' (\gs -> gs {GameState.pendingEntryEffects = Seq.empty})
  -- CR 603.4 / 614.12: the effects are part of the entry, so a board their own
  -- instructions file (Trigger.fileBoards) is dropped, the entry not yet over:
  -- its siblings are still held off the battlefield. The filing after the drain
  -- stands. data/scenarios/trigger's Battering Krasis scenario proves it.
  filed <- State.gets GameState.boardAfterEvent
  Foldable.traverse_ (runEntryEffect runSubgame) queued
  State.modify' (\gs -> gs {GameState.boardAfterEvent = filed})

-- One entered permanent's as-enters effects, in printed order.
--
-- `resolving` and `source` are both the permanent (CR 113.7), runPreventionRider's
-- posture. The slot maps are empty because a static ability targets nothing (CR
-- 115.10a).
--
-- CR 107.3m: an X these effects read is the one announced for the spell that
-- became the permanent (Neverwinter Hydra's "roll X d6"), bound on the permanent
-- only while they run, since that clause makes the permanent's own X 0.
runEntryEffect :: Game Result -> PendingEntryEffect.PendingEntryEffect -> Game ()
runEntryEffect runSubgame pending = do
  let oid = PendingEntryEffect.object pending
      setX value gs = gs {GameState.objects = Map.adjust (\o -> o {Object.bindings = Map.alter (const value) Binding.variableX (Object.bindings o)}) oid (GameState.objects gs)}
  entering <- State.gets (Game.lookupObject oid)
  let announced = entering >>= Object.announcedX
      before = entering >>= Map.lookup Binding.variableX . Object.bindings
  Foldable.for_ announced $ \n -> State.modify' (setX (Just (Binding.toAmount n)))
  -- CR 614.12: what entered in the same event is held off the battlefield while
  -- the effects run, as it was when the rewrite applied (enteredBeside).
  outer <- State.gets GameState.enteringBeside
  beside <- State.gets (Common.enteredBeside oid)
  State.modify' (\gs -> gs {GameState.enteringBeside = Set.union outer beside})
  Monad.void (runCarrying runSubgame oid (PendingEntryEffect.controller pending) Map.empty Map.empty (PendingEntryEffect.effects pending))
  State.modify' (\gs -> gs {GameState.enteringBeside = outer})
  Foldable.for_ announced $ \_ -> State.modify' (setX before)
  State.modify' (Trigger.resampleEntry oid)

-- CR 614.1a: run the effects a replacement put in an event's place -- Kill-Suit
-- Cultist's destruction, Lich's Mirror's reset, Forbidden Crypt's loss. Drains
-- GameState.pendingReplacementEffects, which Parun.Engine.Event filled --
-- runPreventionRiders above in every structural respect and for the same reason.
-- Emptied before the effects run, so an effect whose own damage is replaced
-- appends to a fresh queue instead of being re-run here.
--
-- For damage, every caller runs it BEFORE runPreventionRiders and before the
-- next state-based action check: the replaced event and the rest of its batch
-- were simultaneous (CR 616.1), so what happens instead of it lands before CR
-- 704.5g reads the board. For a loss of the game or a draw, it runs after each
-- resolved instruction and in every settle before priority; a loss a
-- state-based action check meets runs inside that check instead (Sba.performStateBasedActions' `instead`, runDamageRewriteEffect).
-- The callers GameState.pendingReplacementEffects lists keep it empty at every
-- priority window.
runReplacementEffects :: Game Result -> Game ()
runReplacementEffects runSubgame = do
  queued <- State.gets GameState.pendingReplacementEffects
  State.modify' (\gs -> gs {GameState.pendingReplacementEffects = Seq.empty})
  Foldable.traverse_ (runDamageRewriteEffect runSubgame) queued

-- One replaced damage event's effects, in printed order.
--
-- `resolving` and `source` are both the row's own source (CR 113.7),
-- runPreventionRider's posture. Every slot the row carries is treated as a LEGAL
-- target, CR 608.2b having been applied when the installing ability resolved.
runDamageRewriteEffect :: Game Result -> PendingReplacementEffect.PendingReplacementEffect -> Game ()
runDamageRewriteEffect runSubgame pending =
  let targets = PendingReplacementEffect.targets pending
      src = PendingReplacementEffect.source pending
   in Monad.void (runCarrying runSubgame src (PendingReplacementEffect.controller pending) Map.empty targets (PendingReplacementEffect.effects pending))

-- CR 103.5b / CR 103.6: perform the effects of an action a card grants from a
-- player's hand. Parun.Engine.Mulligan's window loops reach this through the
-- HandActionPerformer parameter (see Parun.Types.HandActionPerformer).
--
-- The action does not use the stack, so there is nothing to put on it and no
-- modes to bind.
performHandAction :: Game Result -> HandActionPerformer.HandActionPerformer
performHandAction runSubgame source player =
  Monad.mapM_
    ( applyEffectWith
        runSubgame
        source
        source
        player
        -- CR 115.1: the reserved self slot is NOT a target, so there is no CR
        -- 608.2b legality question -- the card is in the acting player's hand by
        -- construction. Binding it is how "this card" is expressible with no
        -- self-variant opcode.
        (Map.singleton Binding.triggerSource (Set.singleton (Recipient.ToObject source)))
        (Map.singleton Binding.triggerSource (Set.singleton (Recipient.ToObject source)))
    )

-- | CR 701.52a: roll a six-sided die to visit this player's Attractions. A die
-- roll like any other (CR 706), then the result the Visit triggers read.
rollToVisit :: Game Result -> PlayerId -> Game ()
rollToVisit runSubgame pid = do
  (results, throwers, rolled) <- throwDice runSubgame pid 6 1 (pure 0)
  Monad.unless (null rolled) (Common.recordRoll pid throwers rolled)
  -- CR 706.6 can throw a second die and ignore the lower; one is left.
  Foldable.for_ (Maybe.listToMaybe results) $ \result ->
    State.modify' (Event.recordEvent (GameEvent.RolledToVisit DieResult.MkDieResult {DieResult.roller = pid, DieResult.result = result}))

-- | CR 706.1-706.6: throw `named` dice with `sides` sides for `controller`,
-- through every modification rule 706 names -- CR 614.1a's replacements, CR
-- 706.2b's rerolls and adjustments, CR 706.6's ignored rolls -- and answer each
-- kept die's final result beside the player who threw its final natural result.
-- `perDie` is the instruction's own modifier (CR 706.2). Shared by
-- Effect.RollDie's arm and CR 701.52a's roll to visit, which records nothing
-- here: each caller records its own events.
--
-- Answers what the INSTRUCTION reads, the throwers, and what was actually
-- ROLLED, which is what a caller records. They part where Pokey, the Scallywagg
-- replaced the roll (CR 614.6): a coin flipped instead reads as 1 or 20 and
-- rolls nothing, and a roll standing for that flip (Pokey's other half, applied
-- in the same loop) is recorded as rolled and read back through the face it is
-- -- nothing where it was neither.
throwDice :: Game Result -> PlayerId -> Natural -> Natural -> Game Integer -> Game ([Natural], [PlayerId], [Natural])
throwDice runSubgame controller sides named perDie = do
  settled <- Event.proposeDiceRoll controller sides named
  case settled of
    Left results -> pure (results, fmap (const controller) results, [])
    Right roll -> do
      -- A roll standing for Pokey's flip throws with no modifier of the
      -- instruction's own, throwForCoin's reason: the flip named none, and
      -- the instruction sees only the 1 or 20 the face is read as.
      (results, throwers) <- throwSettled runSubgame roll (if Throw.instead roll then pure 0 else perDie)
      let readBack = if Throw.instead roll then Maybe.mapMaybe (fmap Event.resultOfFace . Event.faceOfResult) results else results
      pure (readBack, throwers, results)

-- | CR 706.1: the roll Pokey, the Scallywagg makes instead of a coin flip,
-- thrown through `throwSettled` and recorded -- the CR 706 road
-- Parun.Engine.Event.flipOneCoin cannot reach. No modifier of the instruction's
-- own: the flip named none.
throwForCoin :: Game Result -> Throw.Throw -> Game [Natural]
throwForCoin runSubgame roll = do
  (results, throwers) <- throwSettled runSubgame roll (pure 0)
  Monad.unless (null results) (Common.recordRoll (Throw.thrower roll) throwers results)
  pure results

-- | `throwDice` once CR 614.1a's loop has settled the roll: how many dice to
-- throw, which to keep, and how many of the lowest CR 706.6 then ignores
-- (Parun.Types.Throw).
throwSettled :: Game Result -> Throw.Throw -> Game Integer -> Game ([Natural], [PlayerId])
throwSettled runSubgame roll perDie = do
  let controller = Throw.thrower roll
      -- Unreachable for coins: both funnels settle a flip themselves
      -- (Event.settleCoins), so a thrower is handed dice alone.
      sides = case Throw.kind roll of
        ThrowKind.Dice n -> n
        ThrowKind.Coins -> 1
      -- CR 706.1a's outcomes "numbered from 1 to N", BOTH ends included: the
      -- answer filtered back to a face the die could show. Its own binding
      -- because a reroll runs it a second time.
      faceOf rolled = if rolled >= 1 && rolled <= sides then rolled else 1
      -- CR 706.2b's FIRST step, taken before the instruction's own modifier
      -- is added below: a source other than this instruction offers to throw
      -- the same die again and take the new number as the natural result
      -- (Clam-I-Am). CR 706.1a's "the same die", so `sides` is unchanged and
      -- the second answer is filtered back against the same range.
      --
      -- RECURSIVE, because the offer is a static ability and its gate is on
      -- the natural result: a rerolled 3 that comes up 3 again is a 3 the
      -- Clam sees, and rule 706.2 puts no limit on how many times a roll is
      -- modified. Terminating because every round costs some player a
      -- Prompt.RerollDie they may decline.
      --
      -- The offers are re-read each round for the same reason, rather than
      -- captured before the first die.
      --
      -- A reroll IS a roll, and records CR 706.1's event again under the
      -- player who throws it -- Pippa, Duchess of Dice's ruling, which has a
      -- reroll trigger "whenever you roll a die". The discarded number is not
      -- CR 706.6's ignored roll: it happened, and its event stands.
      --
      -- Answers the natural result with the player who THREW it: the roller,
      -- or whoever activated a reroll in the window below (`windowCandidates`).
      -- The static offers and those activations compete in the one step, so
      -- both are candidates for the roller's pick.
      rerolling = rerollingWith True
      -- `byNumber` False for a natural result a coin gave (`rethrow`): no die
      -- came up that number, so an offer gated on one ("if you roll a 3") is
      -- not made, where one that reaches any die the player rolled is.
      rerollingWith byNumber thrower natural = do
        gs <- State.get
        modifiers <- Dice.modifiersFor controller
        activations <- duringRoll (State.gets windowCandidates)
        let gated (_, offer) = byNumber || Maybe.isNothing (ModifiedRoll.natural offer)
            static = fmap (\(payer, stated, offer) -> (payer, stated, Left offer)) (distinct Set.empty (fmap (offerOf gs) (filter gated (Dice.rerollOffers sides natural modifiers))))
        offering (static <> activations) thrower natural
      -- CR 109.5's "you" on the modifier, which is the player its "may" and
      -- its CR 706.2a cost belong to -- Clam-I-Am's own controller, who is
      -- also the roller, and Wall of Fortune's, who need not be. The ROLLER
      -- where the carrier names no object, which CR 611.2a's stored form would
      -- be and no printing of this family is.
      offerOf gs (stated, offer) = (payerOf gs stated, stated, offer)
      payerOf gs stated = Maybe.fromMaybe controller (stated >>= \oid -> Projection.controllerOf oid gs)
      -- Two FREE offers to the same player are the same question asked twice:
      -- the answers are indistinguishable, and either accepted throws the same
      -- die. So two Clam-I-Ams ask once. Where CR 706.2a's cost is stated the
      -- offers stand apart -- what is paid, and the permanent it is paid
      -- against, are things the payer can tell apart -- so each is asked.
      distinct seen candidates = case candidates of
        [] -> []
        candidate@(payer, _, offer) : rest
          | Maybe.isJust (ModifiedRoll.cost offer) -> candidate : distinct seen rest
          | Set.member payer seen -> distinct seen rest
          | otherwise -> candidate : distinct (Set.insert payer seen) rest
      -- CR 706.2b's pick: the roller chooses which standing offer is put next
      -- (Dice.pickModifier), and its payer decides whether to take it -- the
      -- modifier's own "may" (CR 706.2a). A declined offer leaves the rest to
      -- be re-checked against the board as it then stands.
      offering offers thrower natural = do
        standing <- duringRoll (State.gets (\gs -> filter (live gs) offers))
        picked <- Dice.pickModifier controller standing
        case picked of
          Nothing -> pure (thrower, natural)
          Just ((payer, stated, kind), rest) -> do
            gs <- State.get
            let mCost = either ModifiedRoll.cost (Just . ActivatedAbility.cost . snd) kind
            answer <- Game.choose (Prompt.RerollDie (Decide.deciderFor payer gs) payer natural mCost)
            case (answer, kind) of
              (OptionalDecision.Declines, _) -> offering rest thrower natural
              (OptionalDecision.Exercises, Left _) -> do
                -- Not implemented: asking the payer again after a failed
                -- payment, as payAgain does for CR 118.12 (#5078).
                paid <- payModifier payer stated mCost
                if not paid
                  then offering rest thrower natural
                  -- The roller throws it: Clam-I-Am's "you may reroll
                  -- it", Wall of Fortune's "have any player reroll a die
                  -- that player rolled".
                  else rethrow controller
              (OptionalDecision.Exercises, Right (oid, ability)) -> do
                requested <- duringRoll $ do
                  activated <- activateWhileRolling runSubgame payer oid ability
                  after <- State.get
                  pure (activated && GameState.rerollRequested after)
                if requested
                  then rethrow payer
                  else offering rest thrower natural
      -- CR 706.2b's reroll is a roll: Pippa, Duchess of Dice's ruling has it
      -- trigger "whenever you roll a die", so it is CR 706.1's event and goes
      -- through CR 614's loop, Event.proposeDiceRoll, as one die of the same
      -- size. Pixie Guide adds a die to it and ignores the lowest; Pokey, the
      -- Scallywagg may flip a coin for a d20, whose 1 or 20 is the die's new
      -- natural result. Each die it throws is offered its own rerolls, before
      -- CR 706.6 drops any, so the number that comes back has had every offer
      -- already.
      --
      -- The die a coin stood in for is still one the player rolled, so it is
      -- offered again -- Wall of Fortune's ruling, "you can tap another
      -- untapped Wall ... to have them reroll again" -- but only by an offer
      -- that names no number: the coin "counts as flipping a coin, not rolling
      -- a die" (Pokey), so no die came up that 1 or 20.
      --
      -- Recorded as the rerolling player's roll: Pippa's ruling gives a reroll
      -- of another player's die to the rerolling player's "whenever you roll
      -- a die".
      rethrow by = do
        settled <- Event.proposeDiceRoll by sides 1
        case settled of
          Left results -> rerollingWith False by (Maybe.fromMaybe 1 (Maybe.listToMaybe results))
          Right again -> do
            State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.RollDice by)))
            kept <- naturals again (pure 0)
            -- One kept: a reroll names one die, and every die a row adds comes
            -- with an ignore. A d20 rolled for a coin flipped for the reroll
            -- reads back as that coin's 1 or 20.
            pure $ case kept of
              (total, thrower) : _ -> (thrower, readBack again (Integer.toNaturalSaturating total))
              [] -> (by, 1)
      readBack again natural = if Throw.instead again then maybe natural Event.resultOfFace (Event.faceOfResult natural) else natural
      -- Whether an offer can still go through: a static offer's cost is
      -- payable, an activation passes the gate a priority activation takes.
      live gs (payer, stated, kind) = case kind of
        Left offer -> payable gs payer stated (ModifiedRoll.cost offer)
        Right (oid, ability) -> Activatable.activatable payer oid ability gs
      -- CR 118.3, Prompt.ChooseToPay's posture for CR 118.12: a cost the
      -- payer has not the resources to pay fully is not offered. A stated
      -- cost with no object behind it cannot be paid at all -- every
      -- component is paid against the permanent that printed it -- and is
      -- skipped for that reason.
      payable gs payer stated mCost = case (stated, mCost) of
        (_, Nothing) -> True
        (Just oid, Just cost) -> Cost.canPay PaymentSubject.ForNeither payer oid cost gs
        (Nothing, Just _) -> False
      payModifier payer stated mCost = case (stated, mCost) of
        (Just oid, Just cost) -> payForModifier payer oid cost
        _ -> pure True
      -- CR 706.2b's SECOND step, once every die is up and every reroll done:
      -- a source other than this instruction offers to move one result up or
      -- down (Night Shift of the Living Dead). After the rerolls, which is
      -- the rule's order, so a result an adjustment moved onto Clam-I-Am's 3
      -- is never offered a reroll. Every result is shown before the choice,
      -- the printed ruling's reading of "after you roll a die", and the answer
      -- names the die.
      --
      -- CR 706.2b's pick, `offering`'s: the roller chooses which standing offer
      -- is put next. An offer TAKEN is spent, since a modifier applies to a
      -- roll once. One declined, or not standing, waits out the rest of this
      -- look and is offered again once another modifier applies, over the
      -- number that left (`waiting`). The budget and the cost are re-read
      -- before each question.
      adjusting results = do
        modifiers <- Dice.modifiersFor controller
        gs <- State.get
        adjustingThrough (fmap (\(stated, offer, amount) -> (payerOf gs stated, stated, (offer, amount))) (Dice.adjustOffers sides modifiers)) [] results
      adjustingThrough offers waiting results = case NonEmpty.nonEmpty results of
        Nothing -> pure results
        Just shown -> do
          gs <- State.get
          let standing (payer, stated, (offer, _)) = Dice.withinLimit gs payer stated offer && payable gs payer stated (ModifiedRoll.cost offer)
              (up, idle) = List.partition standing offers
          picked <- Dice.pickModifier controller up
          case picked of
            Nothing -> pure results
            Just (chosen@(payer, stated, (offer, amount)), rest) -> do
              let mCost = ModifiedRoll.cost offer
                  passed = adjustingThrough rest (chosen : idle <> waiting) results
              answer <- Game.choose (Prompt.AdjustDieRoll (Decide.deciderFor payer gs) payer shown amount mCost)
              case answer of
                Nothing -> passed
                Just (index, direction) -> do
                  paid <- payModifier payer stated mCost
                  if not paid
                    then passed
                    else do
                      State.modify' (Dice.spendLimit stated offer)
                      -- FILTERED, NOT TRUSTED: an index past the end shifts
                      -- the first die.
                      let at = if index < List.genericLength results then index else 0
                          shift n = case direction of
                            RollAdjustment.Increase -> n + toInteger amount
                            RollAdjustment.Decrease -> n - toInteger amount
                      adjustingThrough (rest <> idle <> waiting) [] (zipWith (\i n -> if i == at then shift n else n) [0 :: Natural ..] results)
      -- CR 706.2a's cost, charged between the offer and the modifier's
      -- application: a declined or failed payment leaves the number standing.
      --
      -- DuringResolution, payGatePaidBy's moment and for its reason -- the
      -- roll is CR 609.1's effect being followed -- so the payment is CR
      -- 733.1's own reversible action and the CR 605.3a window it opens is
      -- the payer's to keep.
      --
      -- Not implemented: CR 706.2a's second sentence gives that mana window to
      -- the player who ROLLED, where Cost.pay opens it for the payer (#3981).
      -- NO PRINTING tells the two readings apart, and Monitor Monitor -- the
      -- one printed modifier carrying a mana cost, an Attraction opener -- will
      -- not either: its roller IS its payer, "you may pay
      -- {1} to reroll one or more dice you rolled". Wall of Fortune is the
      -- only printing whose payer is not the roller and its cost states no
      -- mana, so it opens no window at all. The shape that would separate them
      -- is Wall of Fortune's scope with a mana cost, which nothing prints, so
      -- this is falsifiable only by a synthetic card.
      --
      -- Cost.pay takes ONE seat, for the payment and for the window both, so
      -- the change is a second seat threaded through paySubstituting and
      -- payManaWindow -- the path every cast, activation and CR 118.12 gate
      -- also takes.
      --
      -- payGateCost's payment, read against no slots and with the bound slots
      -- dropped, which is not an elision: the cost is printed on the
      -- MODIFIER's object, not on the one resolving, so no text of the
      -- resolving object can name what it took, and the modifier's own change
      -- to the die reads no slot. Proved by Parun.DiceSpec's "CR 701.67a a
      -- modifier's waterbend cost is weighed" case.
      payForModifier payer oid cost = Maybe.isJust . fst <$> payGateCost runSubgame Map.empty payer oid cost
      -- Goblin Bookie's "Activate only any time it makes sense", read as a
      -- window inside CR 706.2's modification step, beside the static offers
      -- above. No rule grants one: CR 117.1b ties activation to
      -- priority, which CR 117.3b hands out only after a resolution. Each ability
      -- ActivationRestriction.DuringDieRoll marks is offered to the player
      -- who may activate it, through the same gate a priority activation
      -- takes (Activatable.activatable), and it resolves at once, as CR
      -- 605.3b's mana ability does -- the only reading in which the reroll
      -- reaches the die. Parun.CardSpec keeps such an ability to an untargeted
      -- Effect.Reroll, which is what lets Prompt.RerollDie ask for it.
      -- docs/decisions.md, "When Goblin Bookie can be activated".
      --
      -- In APNAP order, and within a player in object order, behind the static
      -- offers: the order the roller's pick starts from.
      windowCandidates opened =
        [ (pid, Just oid, Right (oid, ability))
        | pid <- Game.apnapOrder opened,
          oid <- Activatable.activationSources pid opened,
          ability <- Activatable.abilitiesFor oid opened,
          elem ActivationRestriction.Type.DuringDieRoll (ActivatedAbility.restrictions ability)
        ]
      duringRoll = Common.withRollingDie sides
      rollOne by modifierOf = do
        rolled <- Game.ask (Prompt.RollDie sides)
        (thrower, natural) <- rerolling by (faceOf rolled)
        -- After the rerolls above, which is CR 706.2b's order: rerolls are
        -- considered first, and what they leave is the natural result the
        -- instruction's own modifier adds to.
        modifier <- modifierOf
        -- Left unclamped: CR 706.2's result is the number after EVERY
        -- modifier, so a shift from another source applies to this sum as it
        -- stands, negative or not, and only the final figure is clamped below.
        pure (toInteger natural + modifier, thrower)
      -- CR 706.6: every die is thrown and every face asked for -- an ignored
      -- roll HAPPENED and is only then treated as never having happened -- so
      -- the ignore runs on the results and not on the count -- and could not
      -- run any earlier in any case, the lowest roll not being known until
      -- every die has come up.
      --
      -- A unit of several dice is Krark's Thumb's "flip two coins and ignore
      -- one" carried across by Pokey (Parun.Types.Throw): one of them is kept,
      -- chosen once every die is up, the Thumb's ruling's order -- "you will
      -- know the results of all simultaneous flips before choosing which to
      -- ignore". Through Prompt.ChooseDieResult, CR 706.4's question of which
      -- result to use; elided where they agree, since no board can tell the
      -- answers apart: the same number thrown by the same player. FILTERED,
      -- NOT TRUSTED: an index past the end keeps the first die.
      --
      -- Each die keeps the player who threw its final natural result, which a
      -- Goblin Bookie reroll can make another seat's (Pippa's ruling), so
      -- dice tied for CR 706.6's lowest but thrown by different players are
      -- asked about (Dice.ignoreLowest).
      naturals settled modifierOf = do
        units <- traverse (\n -> traverse (const (rollOne (Throw.thrower settled) modifierOf)) [1 .. n]) (Foldable.toList (Throw.units settled))
        picked <- Monad.forM units $ \dice -> case NonEmpty.nonEmpty dice of
          -- Unreachable: a unit starts at one die and only a scaling that
          -- cannot reach zero resizes it. Defensive: a die of 1.
          Nothing -> pure (1, Throw.thrower settled)
          Just offered
            | all (== NonEmpty.head offered) (NonEmpty.tail offered) -> pure (NonEmpty.head offered)
            | otherwise -> do
                gs <- State.get
                answer <- Game.choose (Prompt.ChooseDieResult (Decide.deciderFor (Throw.thrower settled) gs) (Throw.thrower settled) Nothing (fmap (Integer.toNaturalSaturating . fst) offered))
                pure (Replacement.at dice answer (NonEmpty.head offered))
        Dice.ignoreLowest (Throw.thrower settled) fst snd (Throw.ignored settled) picked
  kept <- naturals roll perDie
  -- CR 706.6 before the second step: an ignored roll is one "no effects apply
  -- to", so it is not offered for an adjustment.
  --
  -- CR 107.1b once, on the final figure, after every modifier: The Deck of
  -- Many Things' natural 3, four cards in hand and a shift up is a 0, not a 1
  -- (Parun.DiceSpec's "CR 706.2 a shift applies to the unclamped sum").
  results <- fmap (fmap Integer.toNaturalSaturating) (adjusting (fmap fst kept))
  pure (results, fmap snd kept)

-- What Parun.Engine.Cost reaches through the Parun.Types.ManaAbilityPerformer
-- parameter: CR 405.6c's other effects of the activated mana ability being paid,
-- CR 605.4a's triggered mana ability, CR 118.12's resolution cost, and the CR
-- 706 roll Pokey, the Scallywagg makes for a cost's coin flip (throwForCoin).
--
-- `runSubgame` is CR 729.1a's runner for a subgame either one starts. Only the
-- triggered half can: CR 605.1a's library clause (ManaAbility.movesLibraryCard)
-- keeps an activated ability that plays one off the mana-ability road, and CR
-- 605.1b has no such clause. Parun.GameSpec's "CR 605.4a / 729.1b gameplay: a
-- triggered mana ability's subgame winner draws a card" proves the triggered road.
performManaAbility :: Game Result -> ManaAbilityPerformer.ManaAbilityPerformer
performManaAbility runSubgame =
  ManaAbilityPerformer.MkManaAbilityPerformer
    { ManaAbilityPerformer.effects = performManaAbilityEffects runSubgame,
      ManaAbilityPerformer.triggered = performTriggeredManaAbility runSubgame,
      ManaAbilityPerformer.payGate = performManaPayGate runSubgame,
      ManaAbilityPerformer.throwForCoin = throwForCoin runSubgame
    }

-- CR 118.12 on a mana ability's clause, which CR 605.3b gives no stack object:
-- the SOURCE stands in for the resolving one, performManaAbilityEffects'
-- posture. Offered and answered as Parun.Engine.Resolve.payGateAdmits offers a
-- resolving clause's gate, and reusing an answer already recorded for the
-- ordinal a sharing clause names. The seats selected are not bound under
-- Binding.gatePlayers: there is no ability object to bind them on, and no mana
-- ability prints a "they" (MTGJSON's dump of 2026-08-23: Rhystic Cave is the one
-- mana ability with a resolution cost).
performManaPayGate :: Game Result -> ObjectId -> PlayerId -> ClauseIndex.ClauseIndex -> PayGate.PayGate -> Map.Map ClauseIndex.ClauseIndex (Map.Map PlayerId Bool) -> Game (Bool, Map.Map ClauseIndex.ClauseIndex (Map.Map PlayerId Bool))
performManaPayGate runSubgame source controller cIdx gate answers = do
  let offerAt = Maybe.fromMaybe cIdx (PayGate.offeredAt gate)
  asked <- maybe (payGatePaid runSubgame source source controller (ModeIndex.MkModeIndex 0) cIdx Map.empty Nothing Set.empty gate) pure (Map.lookup offerAt answers)
  pure (not (Set.null (Common.branchSelects (PayGate.branch gate) asked)), Map.insert offerAt asked answers)

-- CR 605.4a: apply one triggered mana ability where it stands. CR 605.1b's
-- classification and CR 603.4's intervening "if" are already spent by
-- Parun.Engine.Cost.applyManaTriggers, which is the only caller; this is the
-- resolution half, and it lives here because Parun.Engine.Cost cannot reach
-- applyEffect.
--
-- No stack object, exactly as for the activated mana ability above, so the
-- SOURCE stands in for the resolving one and the slots are stamped rather than
-- read off an object. CR 605.1b leaves no targets to bind, so what the event
-- bound (Parun.Engine.Event.Binding.eventBindings) is the whole environment --
-- Binding.manaSource, which is how Wild Growth's "its controller" names the
-- land rather than the Aura. What one effect binds, a later one reads
-- (runCarrying): Synthetic Wellspring of Legends' subgame winner.
--
-- A SOURCELESS pending trigger cannot arrive: no inherent ability the rulebook
-- states adds mana, and Parun.Engine.Cost gathers only from an object's
-- conditions. Answered by doing nothing rather than by a partial pattern.
--
-- CR 700.2b's mode choice is FORCED or nothing: a modal triggered mana ability
-- would want the prompt Engine.placeBorne raises, and CR 605.4a leaves no stack
-- object to raise it against. Not implemented: such an ability (#3724).
performTriggeredManaAbility :: Game Result -> PendingTrigger.PendingTrigger -> Game ()
performTriggeredManaAbility runSubgame pending = case PendingTrigger.source pending of
  TriggerSource.Sourceless -> pure ()
  TriggerSource.OfObject source -> do
    let controller = PendingTrigger.controller pending
        modal = TriggeredAbility.modal (PendingTrigger.ability pending)
        -- Every PRINTED mode is fillable: CR 605.1b's no-target clause leaves
        -- nothing for Target.fillableModes to reject, which is the gate
        -- Engine.placeBorne applies instead. Zipped against the modes themselves
        -- rather than counted through Modal.modeCount, whose Natural predecessor
        -- would underflow on a modeless ability.
        every = Set.fromList (fmap fst (zip (fmap ModeIndex.MkModeIndex [0 ..]) (Modal.modeEffects modal)))
        bound =
          Map.union
            (Binding.targetsOf (PendingTrigger.bindings pending))
            ( Map.fromList
                [ (Binding.triggerSource, Set.singleton (Recipient.ToObject source)),
                  (Binding.you, Set.singleton (Recipient.ToPlayer controller))
                ]
            )
    case Modal.forcedSelection every (Modal.Type.selection modal) of
      Nothing -> pure ()
      Just selection -> Monad.void (runCarrying runSubgame source controller bound Map.empty (Modal.modesEffects selection modal))

-- CR 405.6c: run some non-mana effects of a mana ability, as
-- Parun.Engine.Cost.tapForManaWith reaches them in printed order.
--
-- CR 605.3b gives the ability no stack object, so the SOURCE stands in for the
-- resolving one, performHandAction's posture.
--
-- CR 608.2c / 608.2d: what one effect binds, a later one reads -- Spectral
-- Searchlight's "Choose a player. That player adds". The ability has no object
-- to hold its slots, so they are threaded: each effect reads the slots handed in
-- and the ones its predecessors bound, and the answer is all of them. What an
-- effect binds lands on the SOURCE (it is the resolving id here), so each slot
-- the effect defines (boundSlots) is cleared there first and read back after:
-- a slot an earlier activation left behind is never mistaken for this one's.
--
-- Not implemented: an object of the ability's own to carry slots the bindings
-- below do not. A slot read that misses them falls through to the source
-- PERMANENT's bindings instead. CR 605.1a leaves a mana ability no targets to
-- have bound; the other slots Parun.AbilitySlotLintSpec's activatedAbilityOffends
-- admits a read of are the ones its cost's payment binds, which reach the yield
-- (Cost.tapForManaWith) and not these effects (#4850).
performManaAbilityEffects :: Game Result -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> [Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)] -> Game (Map.Map SlotName (Set Recipient))
performManaAbilityEffects runSubgame source controller =
  -- CR 109.5's "you" is the player who activated the ability, and the reserved
  -- self slot is CR 113.7's source. Both are bound here rather than read off an
  -- object, because there is no ability object carrying them:
  -- Parun.Engine.Activate.activateAbility stamps them for every ability that does
  -- go on the stack.
  runCarrying runSubgame source controller $
    Map.fromList
      [ (Binding.triggerSource, Set.singleton (Recipient.ToObject source)),
        (Binding.you, Set.singleton (Recipient.ToPlayer controller))
      ]

-- CR 608.2c: run instructions that have no stack object in printed order, with
-- `holder` both resolving and source (CR 113.7), carrying what each one binds
-- onto `holder` into the slot maps of the next -- the re-read resolveSpellWith
-- makes off the stack object before each effect. PlaySubgame's winner is what a
-- following Draw reads (Synthetic Threshold of Legends). `fixed` is unioned in
-- under every instruction; the slots an instruction defines are cleared off
-- `holder` first, so a stale value cannot stand in for one it never bound.
runCarrying :: (Foldable t) => Game Result -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> t (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game (Map.Map SlotName (Set Recipient))
runCarrying runSubgame holder controller fixed =
  let holderBindings gs = case Game.lookupObject holder gs of
        Just obj -> Object.bindings obj
        Nothing -> Map.findWithDefault Map.empty holder (GameState.detachedBindings gs)
      run bound effect = do
        let defined = boundSlots effect
            env = Map.union bound fixed
        State.modify' $ \gs ->
          (Common.overHolderBindings holder (`Map.withoutKeys` defined) gs)
            { GameState.detachedBindings = Map.adjust (`Map.withoutKeys` defined) holder (GameState.detachedBindings gs)
            }
        applyEffectWith runSubgame holder holder controller env env effect
        after <- State.get
        pure (Map.union (Map.restrictKeys (Binding.targetsOf (holderBindings after)) defined) bound)
   in Monad.foldM run

-- Activate an ability inside throwDice's window and resolve it at once,
-- answering whether it was paid for. The payment is Parun.Engine.Activate's
-- activateAbility without the stack object: CR 602.2b's cost, with CR 601.2f's
-- adjustments, charged against the activator's own mana window. Parun.CardSpec
-- keeps these abilities to one untargeted mode and no X, so there is no mode,
-- target or X to announce.
--
-- The effects then run as performManaAbilityEffects runs a mana ability's, the
-- source standing in for the ability object.
activateWhileRolling :: Game Result -> PlayerId -> ObjectId -> ActivatedAbility.ActivatedAbility Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game Bool
activateWhileRolling runSubgame pid oid ability = do
  before <- State.get
  let stamp = ActivatedAbility.keyword ability
      loyalty = Loyalty.loyaltyKindOf (ActivatedAbility.cost ability)
      gathered = Cost.activationAdjustments Set.empty stamp AbilityKind.NonManaAbility loyalty pid oid before
      totalled = Cost.plusComponents gathered (ActivatedAbility.cost ability)
      spendable = ActivationRestriction.spendableTypes oid (ActivatedAbility.restrictions ability) before
  (announced, _) <- Cost.announce (PaymentSubject.Activating oid stamp spendable) ManaSpending.AsProduced pid oid (Cost.substitutedManas (Cost.waterbendSubstitutions (Cost.Type.components totalled) Map.empty pid oid before) (Cost.totalManas gathered)) totalled
  adjustments <- Cost.announceReductions pid oid before announced gathered
  (payment, _) <- Cost.paySubstituting (const False) (performManaAbility runSubgame) before [] PaymentMoment.OutsideResolution (PaymentSubject.Activating oid stamp spendable) Nothing ManaSpending.AsProduced pid oid (Cost.announceSubstitutions Cost.waterbendSubstitutions pid oid) (Cost.totalWith adjustments announced)
  case payment of
    -- CR 733.1: the payment reversed the activation back to `before` itself.
    Payment.Unpaid -> pure False
    Payment.Paid _ -> do
      State.modify' (ActivationRestriction.recordActivation oid ability)
      State.modify' (ActivationRestriction.logActivation before pid oid (Just ability) AbilityKind.NonManaAbility Set.empty)
      let modal = ActivatedAbility.modal ability
          every = Set.fromList (fmap fst (zip (fmap ModeIndex.MkModeIndex [0 ..]) (Modal.modeEffects modal)))
          bound =
            Map.fromList
              [ (Binding.triggerSource, Set.singleton (Recipient.ToObject oid)),
                (Binding.you, Set.singleton (Recipient.ToPlayer pid))
              ]
      Foldable.for_ (Modal.forcedSelection every (Modal.Type.selection modal)) $ \selection ->
        Monad.mapM_ (applyEffectWith runSubgame oid oid pid bound bound) (Modal.modesEffects selection modal)
      pure True

-- CR 608.2c: a loop body's instructions in written order, each read against what
-- the loop's earlier instructions bound -- a clause re-reads its bindings per
-- instruction (Parun.Engine.Resolve's applyOne), and a body is read the same way
-- over the slots the loop defines, Effect.ForEach's `defined`. The maps handed
-- down win, being CR 608.2b's re-validated targets. Parun.ZoneChangeSpec's Ad
-- Nauseam group proves it: the loss reads the card the body's own move put into
-- the hand.
applyLoopBody :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Set SlotName -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
applyLoopBody runSubgame resolving source controller legal chosen bodyDefined body =
  let applyOne effect = do
        defined <- State.gets (\gs -> Map.restrictKeys (Binding.targetsOf (slotBindings resolving gs)) bodyDefined)
        applyEffectWith runSubgame resolving source controller (Map.union legal defined) (Map.union chosen defined) effect
   in Common.applyClauseEffects resolving source applyOne (Foldable.toList body)

-- The offer itself: who was offered this gate's cost, and which of them paid?
-- CR 118.12's MANDATORY limb is not offered, and that is the rule rather than an
-- elision -- it asks whether the player "started to pay", so a mandatory cost the
-- payer can afford leaves nothing to choose, and CR 118.3 is asked first so an
-- unpayable one takes the "can't" branch with no prompt either.
--
-- Narrowed by `announcedOnly` to the seats that announced this branch of a CR
-- 608.2d pair, where the clause is one: the offer belongs to the players who
-- took it, so Worms of the Earth's sacrifice is offered to nobody who announced
-- its damage instead.
--
-- CR 101.4's APNAP order over the players the reference names, which is what
-- `apnapDecidersOf` imposes: rule 101.4b lets a later payer answer knowing what an
-- earlier one did. The board is re-read for each of them (payGatePaidBy's own
-- State.get) rather than measured once, so a cost that changes the board -- CR
-- 118.12's own "sacrifice this enchantment" -- is affordable to the next payer
-- against the board it left. Each payer spends only their own resources, so the
-- sequencing is not observable as an ordering of the ACTIONS.
--
-- A player the reference names who has LEFT the game stays in this list and is
-- answered unpaid by payGatePaidBy, CR 800.4f.
payGatePaid :: Game Result -> ObjectId -> ObjectId -> PlayerId -> ModeIndex -> ClauseIndex -> Map.Map SlotName (Set Recipient) -> Maybe (Set PlayerId) -> Set PlayerId -> PayGate.PayGate -> Game (Map.Map PlayerId Bool)
payGatePaid runSubgame resolving source controller idx cIdx legal announced committed gate = do
  gs <- State.get
  -- A COMMITTED payer (Parun.Engine.Resolve.chosenBranch) already chose to pay
  -- when they announced the branch, so their offer is CR 118.12's mandatory
  -- limb: paid when CR 118.3 allows, and not asked.
  let offerTo payer = if Set.member payer committed then gate {PayGate.obligation = PayObligation.Mandatory} else gate
  answered <-
    Monad.foldM
      ( \earlier payer -> do
          paid <- payGatePaidBy runSubgame resolving source controller (PayOffer.AtClause idx cIdx) (fmap (fmap Common.paymentDecisionOf) earlier) legal payer (offerTo payer)
          pure (earlier Seq.|> (payer, paid))
      )
      Seq.empty
      (Common.announcedOnly announced (Common.apnapDecidersOf (PayGate.payer gate) legal resolving source controller gs))
  State.modify' (Common.foldPaid resolving (foldr Binding.mergePaid Map.empty (Maybe.mapMaybe snd (Foldable.toList answered))))
  pure (Map.fromList [(payer, Maybe.isJust paid) | (payer, paid) <- Foldable.toList answered])

-- CR 118.12a over CR 608.2f's loop: the members whose ForEach.payGate branch
-- selects anybody, in the loop's own order. Each member is its own offer, read
-- through the loop's slot, so a payment for one member buys nothing for
-- another. CR 101.4: every payer answers all of their offers, one per member,
-- before the next payer in APNAP order answers theirs -- Killing Wave's and
-- Whirlwind Denial's rulings -- and is told what the payers before them
-- answered for THAT member (CR 101.4b). Affordability is of everything the
-- payer has agreed to so far (CR 118.3).
--
-- Only then does anybody pay, and each payer pays everything they agreed to as
-- ONE payment (Cost.together), which is those rulings' "then pays that amount"
-- and CR 101.4's "Then the actions happen simultaneously": Killing Wave paid for
-- three creatures is one loss of 3X life, not three. A payer whose combined
-- payment fails has paid for none of them, and is asked again (CR 733.1,
-- payAgain): the scenario "CR 733.1 a Spirit owner whose payment for Cut the
-- Tethers fails is asked again" proves it. No body runs until every payment
-- is made, and what the payments bound is folded on first (foldPaid). Proved
-- by Parun.ResolveSpec's "an offer per member" group, whose Exquisite Blood case
-- counts the life-loss events.
loopOffers :: Game Result -> ObjectId -> ObjectId -> PlayerId -> SlotName -> Map.Map SlotName (Set Recipient) -> [Recipient] -> PayGate.PayGate -> Game [Recipient]
loopOffers runSubgame resolving source controller slot legal members gate = do
  gs <- State.get
  let legalFor member = Map.insert slot (Set.singleton member) legal
      payersOf member = Common.apnapDecidersOf (PayGate.payer gate) (legalFor member) resolving source controller gs
      order = Game.apnapOrder gs
      offers = [(payer, member) | payer <- order, member <- members, elem payer (payersOf member)]
      agreedBy payer answers = [taken | (p, _, Just taken) <- Foldable.toList answers, p == payer]
      agreeOne acc payer member = do
        (slots, options) <- State.gets (Common.gateCostOf resolving source controller (legalFor member) gate)
        let earlier = Seq.fromList [(p, maybe PaymentDecision.Declines (const PaymentDecision.Pays) taken) | (p, m, taken) <- Foldable.toList acc, m == member]
            owed = fmap (Cost.together . fmap snd) (NonEmpty.nonEmpty (agreedBy payer acc))
        agreed <- Common.payGateAgreed resolving source (PayOffer.ForMember member) earlier payer gate slots owed options
        pure (payer, member, fmap ((,) slots) agreed)
      -- One payer's offers answered again, in place, each against what was
      -- answered before it; later payers' answers stand, CR 733.1 reversing
      -- this payer's action alone.
      reagree payer answers =
        Monad.foldM
          ( \sofar i -> case Seq.lookup i sofar of
              Just (p, member, _) | p == payer -> fmap (\entry -> Seq.update i entry sofar) (agreeOne (Seq.take i sofar) p member)
              _ -> pure sofar
          )
          answers
          [0 .. Seq.length answers - 1]
      -- Each payer pays everything they agreed to as one payment; a failed one
      -- asks that payer again (payAgain).
      payFor (done, answers) payer =
        let attempt failed current = case NonEmpty.nonEmpty (agreedBy payer current) of
              Nothing -> pure (Just (done, current))
              Just taken -> do
                (bound, answered) <- payGateCost runSubgame (fst (NonEmpty.head taken)) payer source (Cost.together (fmap snd taken))
                Common.payAgain failed (fst (NonEmpty.head taken), NonEmpty.toList (fmap snd taken), answered) (fmap (\b -> (Map.insert payer b done, current)) bound) (\failed' -> reagree payer current >>= attempt failed')
         in fmap (Maybe.fromMaybe (done, answers)) (attempt Set.empty answers)
  asked <- Monad.foldM (\acc (payer, member) -> fmap (acc Seq.|>) (agreeOne acc payer member)) Seq.empty offers
  (paid, answered) <- Monad.foldM payFor (Map.empty, asked) order
  State.modify' (Common.foldPaid resolving (foldr Binding.mergePaid Map.empty paid))
  let askedAbout member = Map.fromList [(p, Maybe.isJust taken && Map.member p paid) | (p, m, taken) <- Foldable.toList answered, m == member]
  pure (filter (not . Set.null . Common.branchSelects (PayGate.branch gate) . askedAbout) members)

-- One player's answer to one gate. The cost is the PRINTED one with CR 107.3's X
-- resolved (`announcedXOn`, or PayGate.x's chosen value) and then multiplied by the gate's "for each"
-- (PayGate.perEach), and that pair of rewrites is what every reader below
-- sees -- CR 118.3's affordability test, the prompt the payer is shown, and the
-- payment itself -- so none of them can disagree about what is owed.
--
-- The multiplier is read HERE rather than once for the whole gate, which is the
-- posture payGatePaid's own comment states: rule 101.4b lets an earlier payer's
-- answer move the board, and CR 118.12's cost is measured against the board each
-- payer faces.
--
-- Measured against the RESOLUTION, not against the payer: the context is the
-- resolving controller's (`effectContext`, never Filter.contextFor), so
-- Rakshasa's Disdain's "for each card in your graveyard" counts the
-- graveyard of the player who cast it while the payer is the targeted spell's
-- controller. The quantity is evaluated against the ability's SOURCE through
-- `effectViewOf`, so CR 113.7a's last known record answers for a source that has
-- already left, with the announcement id CR 601.2b stamped on the RESOLVING
-- object -- Resolve.Slots' TopOfLibrary depth is the same pair. An unevaluable
-- or negative count is zero copies (CR 107.1b). Whether such an ability should
-- be offering anything at all is its own text's business: rule 702.24a's
-- intervening "if" is what stops it (CR 603.4), proved at
-- Parun.KeywordTriggerSpec's "a Unicorn murdered in response".
--
-- CR 800.4f, asked BEFORE CR 118.3 and before the offer: a payer who has left
-- the game does not pay, and is not asked whether to. That is an answer of False
-- and not a removal from payGatePaid's map, because CR 118.12a's rewriting makes
-- "unless" mean "if they don't, [do something]" and an unpaid cost is exactly
-- what selects that limb -- rule 702.21a's ward counters the spell.
--
-- It cannot ride the CR 118.3 test beneath it. A departed player keeps their
-- CR 102.1 row, so an affordability question asked of their life total or their
-- last known board can still answer yes. Ward is the reachable case: rule
-- 702.21a targets nothing, so CR 608.2b never empties Binding.targetingObject
-- and the trigger resolves after the targeter has gone, with
-- PlayerRef.HolderOfBound naming them through CR 608.2h.
-- Parun.DepartureSpec's "CR 800.4f a departed player is not offered a ward cost,
-- and does not pay it" proves this arm.
--
-- CR 800.4g is the same situation for a choice that is NOT a payment, and the
-- opposite answer: the controller of the object picks another player to make it,
-- which Parun.Engine.Resolve.Common.askedChooser does. Not here -- a cost is the
-- whole of what this function asks about.
payGatePaidBy :: Game Result -> ObjectId -> ObjectId -> PlayerId -> PayOffer.PayOffer -> Seq.Seq (PlayerId, PaymentDecision.PaymentDecision) -> Map.Map SlotName (Set Recipient) -> PlayerId -> PayGate.PayGate -> Game (Maybe (Map.Map SlotName Binding.Type.Binding))
payGatePaidBy runSubgame resolving source controller offer earlier legal payer gate = attempt Set.empty
  where
    -- CR 733.1 / 118.12a: a payment that fails is reversed, which returns the
    -- payer to the choice, so they are asked again (payAgain).
    attempt failed = do
      (slots, options) <- State.gets (Common.gateCostOf resolving source controller legal gate)
      agreed <- Common.payGateAgreed resolving source offer earlier payer gate slots Nothing options
      case agreed of
        Nothing -> pure Nothing
        Just cost -> do
          (paid, answered) <- payGateCost runSubgame slots payer source cost
          Common.payAgain failed (cost, answered) paid attempt

-- The payment of a cost the payer agreed to, against `source` (CR 113.7a): the
-- slots it bound when it was paid (foldPaid), Nothing when it was not, and the
-- answers the payment was given (payAgain).
payGateCost :: Game Result -> Map.Map SlotName (Set Recipient) -> PlayerId -> ObjectId -> Cost.Type.Cost Keyword.Type.Keyword -> Game (Maybe (Map.Map SlotName Binding.Type.Binding), [Response.Response])
payGateCost runSubgame slots payer source cost = do
  gs <- State.get
  -- CR 118.13b: a symbol payable in multiple ways is announced by the
  -- PAYER "immediately before they pay that cost" -- after CR 118.12's
  -- "may" above, since what is announced is how to pay a cost already
  -- chosen, and before the mana window Cost.pay opens.
  --
  -- CR 601.2f's totalling is `pure`, which is the identity in the list
  -- applicative `Cost.announce` measures through: parun gathers cost
  -- adjustments for a SPELL (Cast.castSpell) and for an ACTIVATION
  -- (Activate.activateAbility) and nowhere else, and `Cost.pay` below
  -- applies none of its own, so the announced cost IS the cost that will
  -- be paid. A card that reduced a CR 118.12 cost would be the one to
  -- refute that, and `data/cards/` prints none. That also keeps the offer
  -- exactly as permissive as `Cost.canPay` above, which enumerates the
  -- same CR 601.2b nonhybrid equivalents through Mana.resolutions --
  -- so no route Mana.announce offers is one the gate refused, and its
  -- no-payable-route fallback stays unreachable from here. CR 701.67a's
  -- taps are folded into the totalling for the same reason, Activate's
  -- `substitutedManas` posture: the gate weighs them too.
  -- Discarded, Activate's reason: rule 702.150a asks about a spell's own
  -- cost, not about a cost paid during a resolution (CR 118.13b).
  (announced, _) <- Cost.announce PaymentSubject.ForNeither ManaSpending.AsProduced payer source (Cost.substitutedManas (Cost.waterbendSubstitutions (Cost.Type.components cost) slots payer source gs) pure) cost
  -- DuringResolution: rule 118.12's cost is paid as the spell or ability
  -- resolves, which is CR 609.1's effect, so a blight paid here is CR
  -- 614.16's subject where Soul Immolation's additional cost is not.
  -- CR 733.1's reversal base: rule 118.12's payment IS the whole of
  -- the action that can fail, so the state it begins in is where a
  -- failure returns to and the CR 605.3a window is the payer's to keep
  -- (Cost.pay). Taken after the announcement above, which writes no
  -- state of its own.
  began <- State.get
  (outcome, answered) <- Replay.recording (Cost.payReading slots (performManaAbility runSubgame) began PaymentMoment.DuringResolution PaymentSubject.ForNeither ManaSpending.AsProduced payer source announced)
  pure (case outcome of Payment.Paid bound -> Just bound; Payment.Unpaid -> Nothing, answered)
