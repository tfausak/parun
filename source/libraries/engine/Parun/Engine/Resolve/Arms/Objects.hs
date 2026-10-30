-- applyOneEffect's arms from create to exileHaunting, one function per
-- Effect constructor, cut from Parun.Engine.Resolve.Effect along its order so the
-- arms compile in parallel. Each takes the recursion of Parun.Engine.Resolve.Effect
-- it calls back into, then the resolution parameters its body reads, then the
-- constructor's fields.
module Parun.Engine.Resolve.Arms.Objects where

import Control.Applicative ((<|>))
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.Functor.Identity as Functor
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Parun.Engine.Attach as Attach
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Damage as Damage
import qualified Parun.Engine.Daytime as Daytime
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Expiry as Expiry
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Initiative as Initiative
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Monarch as Monarch
import qualified Parun.Engine.Plane as Plane
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Prepare as Prepare
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Replacement as Replacement
import qualified Parun.Engine.Resolve.Common as Common
import Parun.Engine.Resolve.Slots (battlefieldMatching, conditionSlots, effectContext, effectViewOf, legalOne, objectRefObjects, overRelations, playerRefPlayers, replacementRowSlots, resolvingAbilityName, slotBindings, slotGroup)
import qualified Parun.Engine.Room as Room
import qualified Parun.Engine.SourceContext as SourceContext
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActiveAttackProhibition as ActiveAttackProhibition
import qualified Parun.Types.ActiveAttackRequirement as ActiveAttackRequirement
import qualified Parun.Types.ActiveBlockRequirement as ActiveBlockRequirement
import qualified Parun.Types.ActiveCopy as ActiveCopy
import qualified Parun.Types.ActiveEvasion as ActiveEvasion
import qualified Parun.Types.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Parun.Types.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.AffectPlayers as AffectPlayers
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.AimedAt as AimedAt
import qualified Parun.Types.AimedPlayers as AimedPlayers
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.AttachAll as AttachAll
import qualified Parun.Types.AttachBound as AttachBound
import qualified Parun.Types.AttachTarget as AttachTarget
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackTargetRef as AttackTargetRef
import qualified Parun.Types.BecameDesignated as BecameDesignated
import qualified Parun.Types.BecomeCopy as BecomeCopy
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChangeTargets as ChangeTargets
import qualified Parun.Types.ClassLevel as ClassLevel
import qualified Parun.Types.ClassLevelChange as ClassLevelChange
import qualified Parun.Types.Conjure as Conjure
import qualified Parun.Types.ConjureCards as ConjureCards
import qualified Parun.Types.ConjureDestination as ConjureDestination
import qualified Parun.Types.ConjureEntry as ConjureEntry
import qualified Parun.Types.ConjureSelection as ConjureSelection
import qualified Parun.Types.CopyCoverage as CopyCoverage
import qualified Parun.Types.CopyOriginal as CopyOriginal
import qualified Parun.Types.CopyStackObject as CopyStackObject
import qualified Parun.Types.CopyTargets as CopyTargets
import qualified Parun.Types.CounterCause as CounterCause
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Create as Create
import qualified Parun.Types.CreateCopy as CreateCopy
import qualified Parun.Types.CreateEmblem as CreateEmblem
import qualified Parun.Types.DamageDirection as DamageDirection
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.Daytime as Daytime
import qualified Parun.Types.Designate as Designate
import qualified Parun.Types.Designation as Designation
import Parun.Types.Effect (Effect)
import qualified Parun.Types.EntryBlock as EntryBlock
import qualified Parun.Types.EntryHost as EntryHost
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.ExileHaunting as ExileHaunting
import qualified Parun.Types.Exploited as Exploited
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.ForbidAttack as ForbidAttack
import qualified Parun.Types.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Parun.Types.FromReference as FromReference
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.InitiativeTarget as InitiativeTarget
import qualified Parun.Types.LibraryDepth as LibraryDepth
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.Mentored as Mentored
import qualified Parun.Types.MonarchTarget as MonarchTarget
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ObjectRef (ObjectRef)
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PhasePattern as PhasePattern
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PreventAllDamage as PreventAllDamage
import qualified Parun.Types.PreventNextDamage as PreventNextDamage
import qualified Parun.Types.PreventNextDamageInstance as PreventNextDamageInstance
import qualified Parun.Types.Prohibit as Prohibit
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.Prompt as Prompt
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.RedirectDamage as RedirectDamage
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Types.RequireAttack as RequireAttack
import qualified Parun.Types.RequireBlock as RequireBlock
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.SetClassLevel as SetClassLevel
import qualified Parun.Types.SetHalfLocked as SetHalfLocked
import qualified Parun.Types.SkipPhase as SkipPhase
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.SpellWasCopied as SpellWasCopied
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Zone as Zone

create :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Create.Create Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
create resolving source controller legal chosen (Create.MkCreate quantity card entry mSlot creator) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- CR 608.2h: the counts the tokens enter with, settled ONCE off the
      -- pre-effect board and outside the per-creator loop below, so every seat's
      -- tokens carry the same answer (CR 608.2f).
      frozen = Common.freezeRiders viewOf context gs resolving source entry
      -- CR 111.2: WHOSE tokens. CR 109.5's "you" is the default reference, and
      -- every other one is somebody the sentence identified -- Rampage of the
      -- Clans' "its controller", read off the loop's member through CR 608.2h.
      -- APNAP (CR 608.2f) for a reference naming several, apnapPlayersOf's own
      -- intersection so a reference naming a departed seat mints nothing.
      creators = Common.apnapPlayersOf creator legal resolving source controller gs
  -- CR 509.4's parenthetical: the attacking creature the effect SPECIFIED,
  -- named by slot. Read ONCE, ahead of the minting loop, so CR 608.2f's single
  -- event cannot see it move; through fromAmongMembers, the reader every "the
  -- object this slot names" site shares, so a targeted slot (Flash Foliage) and
  -- one an earlier effect or a trigger bound read the same way.
  --
  -- Exactly one object or nothing: CR 509.4 names ONE attacking creature, and
  -- no printing names several. Nothing here is Combat's own no-op case anyway.
  mBlocked <- case EntryRiders.blocking entry of
    Nothing -> pure Nothing
    -- CR 509.4's main clause: Combat asks the controller.
    Just EntryBlock.Chosen -> pure (Just Combat.AnyAttacker)
    Just (EntryBlock.Specified slot) -> do
      named <- Common.fromAmongMembers legal resolving chosen slot
      pure $ case named of
        [attacker] -> Just (Combat.SpecifiedAttacker attacker)
        _ -> Nothing
  -- CR 303.4i's "attached to", read ONCE ahead of the minting loop for
  -- mBlocked's reason and through the same reader: Nothing where the effect
  -- named no host, and otherwise every object the slot names -- none for rule
  -- 303.4i's undefined object (Preston Garvey, Minuteman at zero targets),
  -- several for Dunbarrow Revivalist's "one of them", whose CR 608.2d choice
  -- among the legal hosts Event.createTokens makes once the token exists.
  --
  -- EntryHost.Chosen is the MoveToZone's alone (moveOne), which
  -- Parun.EffectLintSpec fences, so a Create reads it as naming no host.
  mAttached <- case EntryRiders.attachedTo entry of
    Nothing -> pure Nothing
    Just (EntryHost.Chosen _) -> pure Nothing
    Just (EntryHost.Specified slot) -> Just . fmap Recipient.ToObject <$> Common.fromAmongMembers legal resolving chosen slot
  -- CR 508.4's rider, read ONCE ahead of the minting loop for mBlocked's
  -- reason.
  let mAttack = Common.entryAttack legal resolving entry gs
  -- PER CREATOR, every amount off the same pre-effect `gs` (CR 608.2f), so one
  -- seat's tokens cannot change how many the next seat gets.
  --
  --
  -- ONE event for every token and seat (CR 603.6a, CR 608.2f), so a
  -- batch-scoped "one or more creatures enter" fires once for the lot:
  -- data/scenarios/card-trigger/cr-603-7b-two-goblins-entering-at-once-spend-the-boon-once.json.
  minted <- Event.simultaneously . fmap concat . Monad.forM creators $ \creating ->
    case Common.evaluateForRecipient viewOf context gs resolving source creating quantity of
      Just n
        | n > 0 -> do
            -- CR 111: create n tokens under that player's control (CR 111.2)
            -- through the single funnel, so CR 614's token replacements get their
            -- opportunity. CR 110.5b: the funnel is handed the entry's tap state.
            -- CR 122.6's counters ride along through that rule's own door, so a
            -- counter replacement reaches them, in the counts freezeRiders
            -- settled above.
            made <- Event.createTokens creating (Common.bakeTokenCharacteristics (Quantity.evaluateFor viewOf context gs resolving source) card) Nothing (Integer.toNaturalSaturating n) (EntryRiders.tapped entry) (EntryRiders.counters frozen) mAttached (Common.resolvingMarks resolving gs)
            -- CR 508.4: a creature put onto the battlefield attacking has its
            -- defending player chosen in Parun.Engine.Combat, and CR 508.3a's
            -- attack triggers see nothing. After the entry loops rather than
            -- inside them: CR 614.16's replacement settles the COUNT first.
            Monad.forM_ mAttack (\specified -> Monad.mapM_ (Combat.putOntoBattlefieldAttacking specified) made)
            -- CR 509.4, the blocking twin one rule over, and in the same place
            -- for the same reason: CR 614.16's replacement settles the COUNT
            -- first, and CR 506.3e / CR 509.4a's no-op conditions live in
            -- Parun.Engine.Combat rather than here.
            Monad.forM_ mBlocked (\blocked -> Monad.mapM_ (Combat.putOntoBattlefieldBlocking blocked) made)
            pure made
      _ -> pure []
  Common.bindObjects resolving mSlot minted

-- Alchemy's conjure keyword action. Digital-only, so there is no rule to cite;
-- what the CR settles is that the result is a CARD and not CR 111.1's token,
-- which is what Parun.Engine.Event's conjure and conjureOntoBattlefield mint.
--
-- The card and the destination are read off no board -- the one is literal
-- text and the other a constructor -- but the COUNT is a Quantity, so it takes
-- CR 608.2h's snapshot like every other count: evaluated once off the
-- pre-effect board, ahead of the minting loop, so a card arriving cannot
-- change how many arrive.
--
-- The conjurer is the resolving CONTROLLER (CR 109.5's "you"). Not implemented:
-- a printing that states one instead, which is a shape rather than one card --
-- Parun.Types.Conjure lists the two forms (#3970).
conjure :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Conjure.Conjure Card.Type.Card -> Game ()
conjure resolving source controller legal (Conjure.MkConjure quantity cards selection destination mSlot) = do
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- Four of the five arrivals are no zone change -- the card was in no
      -- zone to leave -- so nothing triggers and nothing is revealed. The rule
      -- behind that: CR 603.6 makes a "put into a graveyard from anywhere"
      -- ability a zone-change trigger, CR 603.6c's last sentence naming that
      -- wording outright, and CR 400.6's event moves an object from one zone to
      -- another, so a materialization is no event such a trigger or a CR 614.1
      -- replacement can see. Parun.ConjureSpec's Planar Void case proves it,
      -- against a cast Think Twice reaching the same graveyard on the same
      -- board.
      --
      -- The BATTLEFIELD is the exception and takes its own road below, because
      -- CR 616.1's entry loop and CR 603.6a's trigger scan both have to see a
      -- permanent enter: that scan reads the event that PUTS a permanent there
      -- rather than a zone change, CR 111.2's token being the CR's own object
      -- that enters having left no zone.
      --
      -- A stated library DEPTH is settled per card, as each lands, so a later
      -- card of the same conjure is placed in a library already holding the
      -- earlier ones; unproven, since no card in data/cards/ conjures more
      -- than one card to a depth. A random depth is ASKED (Prompt.RandomDepth), over the places the
      -- library has -- a library of k other cards has k + 1 -- and never
      -- raised for one place. Parun.ConjureSpec's Calim and Mine Security cases
      -- prove the two. The clamp of an answer outside the places is a
      -- regression fence: no case there answers outside them.
      --
      -- The CANDIDATES of a WRITTEN conjure are picked over once per card
      -- conjured, and the pick is
      -- ASKED rather than rolled: docs/design.md section 2.2 makes randomness
      -- a prompt, RandomObject's posture. A one-candidate list is the card the
      -- sentence names outright, which no board can tell from a pick, so no
      -- prompt is raised there (Parun.Types.Prompt's rule). The answer is
      -- filtered back to a candidate rather than trusted, and a name that
      -- matches none takes the head. Two candidates sharing a name would be
      -- indistinguishable to the answer, and the first is what is conjured.
      --
      -- WHICH question is asked is the opcode's own field, and the two are not
      -- interchangeable (CR 701.9b): a random pick goes through Game.ask,
      -- since randomness is not CR 104.4b's optional action, and a chosen pick
      -- through Game.choose, carrying the Decider and the seat that a choice
      -- owes. Parun.ConjureSpec's Follow the Tracks case proves the chosen half
      -- reaches the answer rather than the head of the offer.
      --
      -- Not implemented: "X random cards" picking X DISTINCT cards (Giant
      -- Secrets' "conjure X random cards from Giant Secrets's spellbook into
      -- your hand"). Each pick here is independent, so one card can come up
      -- twice (#3648).
      --
      -- A DUPLICATE names objects already in the game rather than candidates
      -- written out in the card file, so there is nothing to pick over and
      -- `selection` asks nothing. Each named object is duplicated in turn, the
      -- whole count per object -- Gyox, Brutal Carnivora's "conjure X
      -- duplicates of it" names one object and makes X cards -- and the set is
      -- swept ONCE off the pre-effect board (CR 608.2f), as CreateCopy's arm
      -- below sweeps its own.
      --
      -- What is duplicated is the object's COPIABLE values (CR 707.2) and not
      -- the card printed under it: a Clone that is a copy of an Ornithopter
      -- duplicates as an Ornithopter. The PAIR of reads is CreateCopy's and
      -- has to move together -- Game.cardOfWithLastKnown for the card a reader
      -- past the projection sees, Event.copiedSnapshotWithLastKnown for the
      -- values themselves -- and both take CR 608.2h's last-known branch, since
      -- the object a trigger named can be gone by the time it resolves
      -- (Sinister Reflections is an instant and its targets can be killed in
      -- response to it). Every later incarnation keeps those values
      -- (Object.duplicate); Parun.ConjureSpec's "a duplicate of a Clone cast
      -- and resolved is the Piker" proves it.
      duplicatesOf ref = Maybe.mapMaybe (\oid -> fmap (\card -> (card, Just (Event.copiedSnapshotWithLastKnown oid gs))) (Game.cardOfWithLastKnown oid gs)) (objectRefObjects legal resolving controller source gs ref)
      answered written answer = Maybe.fromMaybe (NonEmpty.head written) (List.find (\candidate -> Common.conjuredName candidate == answer) (NonEmpty.toList written))
      -- The question `selection` names, put over a list of NAMES of two or
      -- more; a one-name list is taken outright.
      pickName names =
        Maybe.fromMaybe (NonEmpty.head names) <$> case selection of
          ConjureSelection.AtRandom -> Game.drawAmong Prompt.RandomCard (NonEmpty.toList names)
          ConjureSelection.ByChoice -> Game.chooseAmong Prompt.ChooseConjuredCard controller (NonEmpty.toList names)
      pickWritten written = fmap (\answer -> (answered written answer, Nothing)) (pickName (fmap Common.conjuredName written))
      -- A REFERENCE pick (CR 108.1) asks the interpreter which of the
      -- reference's cards the filter admits -- ONCE, off the pre-effect board
      -- like the count -- then puts the written road's question over their
      -- names and looks the picked name up. Filtered, not trusted: an answer
      -- outside the names takes the head, and a card the lookup hands back
      -- that the filter does not admit is not conjured. A reference admitting
      -- nothing conjures nothing.
      referenceAmount from = FromReference.amount from >>= Common.evaluateForRecipient viewOf context gs resolving source controller
      pickReference predicate amount names = do
        answer <- pickName names
        found <- Game.lookUpCard answer
        g <- State.get
        pure $ do
          card <- found >>= (`Game.cardOfPrinting` g)
          Monad.guard (Projection.referenceAdmits (Game.teams g) amount predicate card)
          Just (card, Nothing)
      referencePickers from count = do
        let amount = referenceAmount from
            predicate = FromReference.filter from
        names <- Game.ask (Prompt.ReferenceCards predicate amount)
        pure $ case NonEmpty.nonEmpty (ListUtils.nubOrd names) of
          Nothing -> []
          Just offered -> replicate count (pickReference predicate amount offered)
      -- One pick per card conjured on the written and reference roads, and
      -- `n` entries per named object on the duplicate road, the whole count
      -- per object as the battlefield road below mints it. `pure` rather than
      -- a prompt for a duplicate: the object was named before the conjure ran.
      -- Parun.ConjureSpec's Gyox case proves the count reaches exile.
      pickers n = case cards of
        ConjureCards.Written written -> pure (replicate (Integer.toIntSaturating n) (fmap Just (pickWritten written)))
        ConjureCards.Duplicate ref -> pure (concatMap (replicate (Integer.toIntSaturating n) . pure . Just) (duplicatesOf ref))
        ConjureCards.Reference from -> referencePickers from (Integer.toIntSaturating n)
      intoZone zone settle n = fmap (concatMap Maybe.catMaybes) (pickers n >>= Monad.mapM (\p -> p >>= Monad.mapM (\(card, copied) -> Event.conjure controller card copied zone LibraryPosition.defaultValue >>= \made -> made <$ Monad.mapM_ settle made) . Maybe.maybeToList))
      sink depth oid = do
        g <- State.get
        let places = Natural.length (Map.findWithDefault Seq.empty controller (GameState.library g))
        ordinal <- case depth of
          LibraryDepth.FromTop k -> pure k
          LibraryDepth.AtRandomInTop k -> case min k places of
            reach
              | reach < 2 -> pure 1
              | otherwise -> fmap (max 1 . min reach) (Game.ask (Prompt.RandomDepth reach))
        State.modify' (Game.sinkInLibrary (Natural.toIntSaturating ordinal - 1) controller oid)
      onto entry n (card, copied) = do
        made <- Foldable.toList <$> Event.conjureOntoBattlefield controller card copied (Integer.toNaturalSaturating n) (ConjureEntry.tapped entry)
        -- CR 508.4, Create's arm's posture and in the same place: after the
        -- entry loops, with the controller choosing what it attacks, and CR
        -- 508.3a's attack triggers seeing nothing.
        Monad.when (ConjureEntry.attacking entry) (Monad.mapM_ (Combat.putOntoBattlefieldAttacking Combat.Any) made)
        pure made
  -- The cards conjured, bound for a later clause to name (CR 603.7c's "that
  -- card"), Create's bindObjects.
  conjured <- case Common.evaluateForRecipient viewOf context gs resolving source controller quantity of
    Just n
      | n > 0 -> case destination of
          ConjureDestination.Hand -> intoZone Zone.Hand (const (pure ())) n
          ConjureDestination.Library depth -> intoZone Zone.Library (\oid -> Monad.mapM_ (`sink` oid) depth) n
          ConjureDestination.Graveyard -> intoZone Zone.Graveyard (const (pure ())) n
          ConjureDestination.Exile -> intoZone Zone.Exile (const (pure ())) n
          -- CR 110.2a: the resolving controller is who the permanent enters
          -- under, which conjureOntoBattlefield stamps.
          -- One pick for the whole BATCH rather than one per card, which is
          -- the card conjureOntoBattlefield mints every member of its CR
          -- 614.12 entry loop from. Nothing in data/cards/ states a count
          -- above one over a spellbook, so which reading this is stays a
          -- regression fence (#3648).
          -- CR 110.5b's status is the arm's own payload, stated by the
          -- sentence rather than defaulted here (Foundry Groundbreaker's
          -- "onto the battlefield tapped"), and it reaches the mint rather
          -- than a tap afterwards: a permanent that arrived untapped and was
          -- tapped after would have been read untapped by its own CR 616.1
          -- loop and by every CR 603.6a watcher of the entry.
          -- One batch per pick, which on the written road is the one pick the
          -- whole count is minted from and on the duplicate road is one batch
          -- of `n` per named object. Every batch enters at one moment, so
          -- Event.together orders them all as one CR 613.7m batch -- a
          -- regression fence, since no card in data/cards/ conjures a duplicate
          -- of two or more objects onto the battlefield.
          ConjureDestination.Battlefield entry -> Event.simultaneously . Event.together $ case cards of
            ConjureCards.Written written -> pickWritten written >>= onto entry n
            ConjureCards.Duplicate ref -> concat <$> Monad.mapM (onto entry n) (duplicatesOf ref)
            ConjureCards.Reference from -> referencePickers from 1 >>= fmap concat . Monad.mapM (\p -> p >>= fmap concat . Monad.mapM (onto entry n) . Maybe.maybeToList)
    _ -> pure []
  Common.bindObjects resolving mSlot conjured

createCopy :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> CreateCopy.CreateCopy (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
createCopy resolving source controller legal chosen (CreateCopy.MkCreateCopy quantity ref entry mSlot exceptions) = do
  gs <- State.get
  -- CR 707.2 / 111.3: this many tokens per named permanent, minted through the
  -- same CR 111.2 funnel, carrying the copied permanent's COPIABLE values
  -- rather than its projection. All of it read off ONE `gs` (CR 608.2f).
  --
  -- The token's own card is the copied permanent's, so a reader going past the
  -- projection to Game.faceOf sees the same text the snapshot does; it is not
  -- where the characteristics come FROM, the snapshot being layer 1 (CR
  -- 613.1a). CR 608.2h: both reads take the last known branch for a permanent
  -- already gone, and the pair has to move together.
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      sources = objectRefObjects legal resolving controller source gs ref
      -- CR 608.2h: the counters the copies enter with, settled ONCE off the
      -- pre-effect board, outside the loop over named permanents below.
      frozen = Common.freezeRiders viewOf context gs resolving source entry
      -- CR 508.4's rider, read ONCE off the pre-effect board for Create's
      -- reason.
      mAttack = Common.entryAttack legal resolving entry gs
  -- CR 509.4's parenthetical, read the way Create's arm reads it and for the
  -- same reasons: the attacking creature the effect SPECIFIED, named by slot,
  -- once and ahead of the minting loop, through fromAmongMembers. Mirror
  -- Match's "a token that's a copy of that creature and that's blocking that
  -- creature" names the ForEach member it just copied, so the slot the ref
  -- reads and the slot this reads are one name.
  mBlocked <- case EntryRiders.blocking entry of
    Nothing -> pure Nothing
    -- CR 509.4's main clause: Combat asks the controller.
    Just EntryBlock.Chosen -> pure (Just Combat.AnyAttacker)
    Just (EntryBlock.Specified blockedSlot) -> do
      named <- Common.fromAmongMembers legal resolving chosen blockedSlot
      pure $ case named of
        [attacker] -> Just (Combat.SpecifiedAttacker attacker)
        _ -> Nothing
  -- The count is Create's, read the same way and off the same `gs` (CR 707.1).
  minted <- case Quantity.evaluateFor viewOf context gs resolving source quantity of
    Just n
      | n > 0 ->
          -- CR 613.7m over copies of SEVERAL sources, which enter together:
          -- one batch across every createTokens call (Event.together).
          Event.simultaneously . Event.together . fmap concat . Monad.forM sources $ \src ->
            fmap concat . Monad.forM (Maybe.maybeToList (Game.cardOfWithLastKnown src gs)) $ \card -> do
              -- CR 707.2 copies no counters, so what the token arrives with
              -- is what the EFFECT said and nothing the original carried --
              -- Littjara Mirrorlake's "except it enters with an additional
              -- +1/+1 counter on it". Through Event.createTokens' own counter
              -- argument, CR 122.6's door, so CR 614.16's replacements see
              -- them; Create's arm one case up hands over the same value.
              --
              -- CR 110.5b's tap state rides through the same funnel, Create's
              -- road; Parun.EffectLintSpec lints that no CreateCopy in the pool
              -- sets a rider this arm does not read.
              --
              -- ONE call per named permanent, with the whole count: CR 614.12's
              -- entry loop is handed the batch, so the copies enter
              -- simultaneously and none may copy a sibling.
              --
              -- CR 707.9's exceptions are folded into the snapshot on the way
              -- in, exactly as the CR 707.5 entry road folds AsCopy's, so the
              -- excepted value is part of the token's own copiable values (CR
              -- 707.9b) -- Multiversal Recruitment's "except it isn't
              -- legendary". "This ability" is the resolving object's, read the
              -- way the BecomeCopy arm below reads it.
              -- Nothing for the subject's own copiable values: CR 707.9c's
              -- retained original belongs to an object that already existed,
              -- and a token minted by CR 707.1 did not.
              made <- Event.createTokens controller card (Just (Replacement.applyCopyExceptions (Common.thisAbilitySource resolving gs) Nothing exceptions (Event.copiedSnapshotWithLastKnown src gs))) (Integer.toNaturalSaturating n) (EntryRiders.tapped entry) (EntryRiders.counters frozen) Nothing (Common.resolvingMarks resolving gs)
              -- CR 508.4, after the entry loop for Create's reason.
              Monad.forM_ mAttack (\specified -> Monad.mapM_ (Combat.putOntoBattlefieldAttacking specified) made)
              -- CR 509.4, the blocking twin one rule over, in the same place
              -- and for the same reason Create's arm puts it there.
              Monad.forM_ mBlocked (\blocked -> Monad.mapM_ (Combat.putOntoBattlefieldBlocking blocked) made)
              pure made
    _ -> pure []
  Common.bindObjects resolving mSlot minted

becomeCopy :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> BecomeCopy.BecomeCopy (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
becomeCopy resolving source controller legal (BecomeCopy.MkBecomeCopy original subjectRef duration exceptions newTargets) = do
  -- CR 108.1: a NAMED original is the card the Oracle reference gives the
  -- name, looked up before the board below is read.
  named <- case original of
    CopyOriginal.Named name -> Game.lookUpCard name
    CopyOriginal.OfObject _ -> pure Nothing
  let onStackIn g oid = List.find ((== Zone.Stack) . Object.zone) (Game.lookupObject oid g)
      -- The copiable values, and the original's stack incarnation whose
      -- choices CR 707.2 hands on. A named card's are read off a
      -- counterfactual board holding it (Event.mintOutside), which is
      -- thrown away with the read; it is on no stack, so it hands on none.
      copiedOriginal gs = case original of
        CopyOriginal.OfObject ref -> case objectRefObjects legal resolving controller source gs ref of
          [oid] -> Just (Event.copiedSnapshotWithLastKnown oid gs, onStackIn gs oid)
          _ -> Nothing
        CopyOriginal.Named _ -> fmap (\printingId -> let (oid, board) = Event.mintOutside controller printingId gs in (Event.copiedSnapshot oid board, Nothing)) named
  before <- State.get
  State.modify' $ \gs ->
    -- CR 707.1: each named subject becomes a copy of the named original, in
    -- whatever zone it already sits -- CR 707.4's "while remaining on the
    -- battlefield" for a permanent, Synthetic Mirror of the Fallen's card in a
    -- graveyard and Synthetic Mimicry's spell on the stack otherwise, no zone
    -- change happening in any of them (CR 400.7). Both sides are enumerated
    -- ONCE off the same `gs` (CR 608.2f), so an illegal slot, a player recipient and a set that
    -- matched nothing all arrive empty and copy nothing. ONE original: CR 707.2
    -- copies the values of "the original object", singular.
    --
    -- The snapshot is a VALUE, so CR 707.2b holds by construction. Written at
    -- layer 1 (CR 613.1a), so layers 2-7 re-apply over the new base -- CR
    -- 707.4's "doesn't change any noncopy effects presently affecting the
    -- permanent". WHERE it is written is what `duration` decides, below.
    --
    -- CR 707.9's exceptions are folded into the snapshot on the way in, exactly
    -- as the CR 707.5 entry road folds AsCopy's (Event's EntryR arm), so the
    -- excepted ability is part of the copy's own copiable values (CR 707.9a)
    -- rather than an effect layered over them.
    --
    -- "This ability" is the RESOLVING object's own -- thisAbilitySource, off
    -- Parun.Types.Source, so the ability is read where CR 602.2a and CR 603.3
    -- already carry it rather than being looked back up on a source that may
    -- have left (CR 113.7a).
    case copiedOriginal gs of
      Just (copied, mOriginal) ->
        let -- PER SUBJECT, because CR 707.9c's retained original value is the
            -- subject's own (Vesuvan Doppelganger's "it doesn't copy that
            -- creature's color"), and CR 707.4's road names a set. Read off
            -- the pre-effect `gs` like everything else here (CR 608.2f), so a
            -- subject written earlier in the fold does not change what a later
            -- one retains.
            snapshotFor subject = Replacement.applyCopyExceptions (Common.thisAbilitySource resolving gs) (Just (Event.copiedSnapshot subject gs)) exceptions copied
            write subject = Map.adjust (\o -> o {Object.bindings = Binding.setCopy (snapshotFor subject) (Object.bindings o)}) subject
            subjects = objectRefObjects legal resolving controller source gs subjectRef
            -- CR 707.2's second half, for a subject on the STACK: it acquires
            -- the original's "choices made when casting or activating it" --
            -- none when the original is not on the stack. Off the pre-effect
            -- `gs` for the reason above.
            acquire g = foldr acquireOne g (filter (Maybe.isJust . onStackIn gs) subjects)
            acquireOne subject g =
              let g1 = g {GameState.objects = Map.adjust (Common.acquireChoices (PC.spell (snapshotFor subject)) (Game.acquisitionOf subject g) mOriginal) subject (GameState.objects g)}
               in maybe g1 (\o -> Common.rearmStackExile subject (snapshotFor subject) o g1) (Game.lookupObject subject g1)
         in case duration of
              -- CR 707.3: the card states no ending, so the copiable values go
              -- onto the subject itself (Binding.setCopy) and nothing has to
              -- remember them. CR 613.7 puts them over any stored row already
              -- covering the subject (Game.supersedeStoredCopies). CR 607.5:
              -- the abilities they bring are an acquisition of their own,
              -- named by a fresh timestamp, so nothing noted for the ones
              -- they replace is linked to them.
              Nothing ->
                let (ts, gs1) = Game.freshTimestamp gs
                    acquired o = o {Object.acquisition = Acquisition.Copied ts}
                 in acquire (Game.supersedeStoredCopies (Set.fromList subjects) gs1 {GameState.objects = foldr (\subject -> Map.adjust acquired subject . write subject) (GameState.objects gs1) subjects})
              Just stated -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source stated gs of
                -- CR 611.2b: the duration never started, so nothing is stored.
                Nothing -> gs
                Just expiry ->
                  -- CR 611.2c: the swept ids are frozen into the stored row,
                  -- so the set never changes afterwards. ONE timestamp over
                  -- the whole sweep, as ModifyTarget's arm takes, and the
                  -- sweep is split into a row per DISTINCT snapshot only
                  -- because CR 707.9c's retained value is each subject's own
                  -- -- two subjects sharing a snapshot share a row.
                  let (ts, gs1) = Game.freshTimestamp gs
                      row (pc, oids) =
                        ActiveCopy.MkActiveCopy
                          { ActiveCopy.source = source,
                            ActiveCopy.timestamp = ts,
                            ActiveCopy.expiry = expiry,
                            ActiveCopy.covers = CopyCoverage.These oids,
                            ActiveCopy.snapshot = pc,
                            ActiveCopy.turned = Nothing
                          }
                      rows = fmap row . Map.toList . Map.fromListWith Set.union $ fmap (\subject -> (snapshotFor subject, Set.singleton subject)) subjects
                   in acquire gs1 {GameState.copyEffects = rows <> GameState.copyEffects gs1}
      Nothing -> gs
  -- CR 707.10c's "its controller may choose new targets for it": each subject
  -- on the stack, asked of that spell's controller (CR 405.4), once it is the
  -- copy. Transcantation's ruling makes the prompt the spell's only road back
  -- to a target; one left without any doesn't resolve (CR 608.2b,
  -- Resolve.targetsAllIllegal).
  Monad.forM_ (if newTargets then fmap snd (copiedOriginal before) else Nothing) $ \mOriginalOf ->
    Monad.forM_ (filter (Maybe.isJust . onStackIn before) (objectRefObjects legal resolving controller source before subjectRef)) $ \spell -> do
      g <- State.get
      Monad.forM_ (Game.lookupObject spell g) $ \obj ->
        let spellController = Maybe.fromMaybe (Projection.defaultControllerOf obj) (Projection.controllerOf spell g)
         in Common.chooseNewTargetsFor (Maybe.isNothing mOriginalOf) source spellController spellController spell

copyStackObject :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> CopyStackObject.CopyStackObject (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
copyStackObject resolving source controller legal (CopyStackObject.MkCopyStackObject ref targets quantity copierRef exceptions) = do
  gs <- State.get
  -- CR 707.10: `quantity` copies of each named object, each put onto the stack.
  -- The named objects are enumerated ONCE off this `gs` (CR 608.2f), and the
  -- count is determined once off it too (CR 608.2h); each copy is then minted
  -- against the live state, since a fresh id and a fresh timestamp are both
  -- counters the previous mint moved.
  -- Parun.KeywordTriggerSpec's Storm group proves the count.
  let copies = maybe 0 Integer.toIntSaturating (Quantity.evaluateFor (effectViewOf resolving source legal gs) (effectContext gs resolving controller source legal (slotBindings resolving gs)) gs resolving source quantity)
  Monad.forM_ (Common.copyStackSubjects legal resolving controller source gs ref) $ \original ->
    -- CR 707.10's three nouns: a spell (Game.isSpell) and an activated or
    -- triggered ability (Game.isAbility), each classifying off the object's
    -- ZONE and its Source and never off which card it is. Every other LIVE
    -- object copies nothing -- a copy of a CARD is CR 707.12's act (OfferCast's
    -- `copied`) or CR 707.13's (Effect.OfferNamedCopy), and a permanent on the
    -- battlefield is the CreateCopy and BecomeCopy opcodes' subject rather
    -- than this one's.
    --
    -- CR 707.10 over an object that has LEFT the stack, second: CR 608.2h's
    -- last known information, which GameState.stackArchive keeps and the live
    -- board cannot. An effect that ARMED a copier files its own reading there
    -- (CR 702.50a's epic ability, at each of its controller's upkeeps for the
    -- rest of the game), so nothing here cases on which keyword armed it.
    --
    -- WHICH archived object a ref can name is copyStackSubjects' question, so
    -- the roads here are rule 702.50a's epic, whose delayed ability names a
    -- slot bound to the archived id, a copy-this-spell trigger whose spell left
    -- the stack (CR 702.40a's storm over a countered Grapeshot), and a trigger
    -- whose event bound the spell it copies (Ivy, Gleeful Spellthief's "that
    -- spell", countered while the trigger waited), or the ability it copies
    -- (Rings of Brighthearth's "that ability", likewise; Game.cease files it).
    Monad.forM_ (if Game.isSpell original gs || Game.isAbility original gs then Game.lookupObject original gs else Map.lookup original (GameState.stackArchive gs)) $ \obj ->
      -- CR 707.10's "that player copies it": WHO puts the copy onto the stack,
      -- which is the copy's owner and controller and CR 707.10c's chooser --
      -- Meletis Charlatan's "the controller of target instant or sorcery spell".
      -- Read off the same pre-effect `gs` as the objects (CR 608.2f), and
      -- PLURAL, one copy per seat the reference names; every producer names one,
      -- and the elided default names the resolving controller.
      Monad.forM_ (playerRefPlayers legal resolving source controller gs copierRef) $ \copier -> Monad.forM_ (Common.copyOnStackOf (Object.source obj)) $ \(copySource, kind) -> Monad.replicateM_ copies $ do
        -- CR 707.10's answers, as the target maps to write: one EMPTY map
        -- where the copy keeps the decisions rule 707.10 copied (rule 707.10c
        -- included, its offer below being a separate act), CR 707.10d's one
        -- map per candidate, in the order its controller chose, and CR
        -- 707.10e's single map for the target the effect states. The list's
        -- LENGTH is how both of the latter two say "a copy isn't created".
        plan <- case targets of
          CopyTargets.Copied -> pure [Map.empty]
          CopyTargets.ChosenByController -> pure [Map.empty]
          CopyTargets.ForEach candidateRefs -> Common.copyForEachTargets controller copier resolving source legal original candidateRefs
          CopyTargets.Stated newRef -> Common.copyStatedTargets controller copier resolving source legal original newRef
        Monad.forM_ plan $ \retarget -> do
          -- CR 707.10d / 707.10e with CR 115.7f: a target the effect re-aims
          -- takes the replaced target's part of the division, reaimDivisions'
          -- reading. An answer handing out other parts keeps the targets
          -- alone, a regression fence: every pool copier re-aims one target,
          -- which asks nothing. data/scenarios/divide's Precursor Golem case
          -- proves the part carried.
          rebound <- Common.reaimDivisions copier original (Object.bindings obj) retarget
          gsNow <- State.get
          let (copyId, gs1) = Game.freshObjectId gsNow
              (ts, gs2) = Game.freshTimestamp gs1
              -- CR 707.10's "all decisions made for it": the modes, the targets,
              -- the value of X and the announced costs are all fields of the
              -- object being copied, so the copy IS that object with the few
              -- things CR 707.10 names overwritten. Enumerating what to carry
              -- would be a list to keep in step with Parun.Types.Object; this way
              -- a new decision field is copied by construction.
              --
              -- Owner and controller are the seat `copier` named, both stated
              -- outright by CR 707.10 and neither inherited: the copy is
              -- "owned by the player under whose control it was put on the
              -- stack", which is the copying effect's controller unless the
              -- effect says who else (Meletis Charlatan).
              -- Rule 707.10 gives an OWNER only to a copy of a spell, and
              -- the same write is right for an ability: parun's Object.owner on an
              -- ability object is that ability's controller, which is what
              -- Parun.Engine.Activate stamps and what Parun.Engine.Stack's two
              -- ability arms read.
              --
              -- Zeroed: damage, counters and designations, none of which CR
              -- 707.2 copies. Neither a spell nor an ability on the stack carries
              -- any of the three today, so this is the rule written out rather
              -- than a difference the board can show.
              --
              -- CR 707.2's copiable values are stamped for a SPELL only, where the
              -- other two copy opcodes stamp them so
              -- Projection.copiableCharacteristics answers for all three and CR
              -- 707.3 holds for free. The LIVE reader, not the last-known one: the
              -- object was just looked up, so there is nothing to resurrect. An
              -- ABILITY has no card behind it at all (CR 113.7a; Game.cardOf
              -- answers Nothing for one), so there is nothing to snapshot -- CR
              -- 707.10b's "the same source as the original ability" is the whole of
              -- what its copy carries, and it rides in `copySource` above. That
              -- half is a REGRESSION FENCE rather than a proven line: stamping a
              -- snapshot on an ability copy anyway left the suite green
              -- (2026-09-03), an ability having no characteristic any board can
              -- read it back off.
              -- An ARCHIVED spell brings its own snapshot -- filed as it left
              -- the stack, or as an arming effect wrote it, rule 702.50a's
              -- "except for its epic ability" included -- and there is no live
              -- object left to take a fresh reading off, so that snapshot is
              -- what the arm below re-stamps rather than a fresh reading.
              --
              -- CR 707.9's exceptions are folded into the snapshot on the way
              -- in, exactly as the BecomeCopy arm above folds them, so Double
              -- Major's "except it isn't legendary" is part of the copy's own
              -- copiable values (CR 707.9b) and survives CR 707.10f's token.
              -- `own` is Nothing for CreateCopy's reason: a copy put onto the
              -- stack has no previous copiable values for CR 707.9c to retain.
              except = Replacement.applyCopyExceptions (Common.thisAbilitySource resolving gs) Nothing exceptions
              stampCopiable = case kind of
                StackObjectKind.Spell | Maybe.isJust (Game.lookupObject original gs) -> Binding.setOwnCopy (except (Event.copiedSnapshot original gs))
                -- An ARCHIVED spell's exceptions are re-folded over the snapshot
                -- GameState.stackArchive holds. A REGRESSION FENCE rather than a
                -- proved line: no road to the archive states an exception --
                -- rule 702.50a's epic does not, and neither does a copy-this-spell
                -- keyword trigger (Parun.Engine.Keyword.copiesOf).
                StackObjectKind.Spell -> maybe id (Binding.setOwnCopy . except) (Game.copyStampOf obj)
                StackObjectKind.ActivatedAbility -> id
                StackObjectKind.TriggeredAbility -> id
              -- CR 201.5's slot, and the one place the two nouns CR 707.10
              -- copies part company. A copy of an ABILITY keeps the original's
              -- `self`: CR 707.10b says "if the ability refers to its source by
              -- name, the copy refers to that same object". A copy of a SPELL is
              -- "itself a spell", and the text on it is text on the COPY, so CR
              -- 201.5's "the object it's on" is the copy -- a copy of
              -- Chronomantic Escape exiles the copy, which CR 707.10a then
              -- ceases to exist rather than the original on the stack below it.
              --
              -- CR 602.2a's thisAbility slot goes the other way: it names the
              -- ability's OWN object rather than its source, and CR 707.10's
              -- last sentence makes the copy an ability of its own, so the
              -- copy's printed "this ability" is the copy. Re-stamped for the
              -- same reason `you` is -- Parun.Engine.Activate wrote the
              -- original's id there as it went on the stack -- and not a
              -- decision CR 707.10 copies. data/scenarios/copy's Forsworn Paladin
              -- case proves the aim moved, and Parun.CopySpec's Stifle case that
              -- it answers once the original has left the stack. A triggered ability's copy is
              -- re-stamped the same way, Parun.Engine.Engine.placeBorne having
              -- written the original's id there.
              stampSelf = case kind of
                StackObjectKind.Spell -> Binding.setTriggerSource copyId
                StackObjectKind.ActivatedAbility -> Binding.setThisAbility copyId
                StackObjectKind.TriggeredAbility -> Binding.setThisAbility copyId
              copy =
                -- CR 707.10: a copy of a spell is no card.
                (Game.setSource copySource obj)
                  { -- CR 707.10 puts the copy ONTO THE STACK, so the zone is the
                    -- opcode's own rather than the copied object's -- which the
                    -- guard above has already established was the stack.
                    Object.zone = Zone.Stack,
                    Object.owner = copier,
                    Object.enteredUnder = Just copier,
                    Object.timestamp = ts,
                    Object.damage = 0,
                    Object.counters = Map.empty,
                    Object.counterTimestamps = Map.empty,
                    Object.designations = Set.empty,
                    -- CR 701.37c's X rides the designation, so it is zeroed
                    -- with it -- `designations` above, same sentence.
                    Object.designationValues = Map.empty,
                    Object.storedResults = Map.empty,
                    -- CR 707.10: the copy is created with these values.
                    Object.acquisition = Acquisition.Own,
                    -- CR 707.10 copies the alternative cost, but a copy isn't
                    -- CAST, so it keeps evoke's record and not escape's.
                    Object.castUsing = Keyword.copiedCastUsing (Object.castUsing obj),
                    -- CR 707.10: a copy isn't cast, so it was cast from no zone
                    -- (Filter.WasCastFrom). Parun.PlanechaseSpec's Double Major
                    -- case is the proof.
                    Object.castFrom = Nothing,
                    -- CR 702.143c's foretold spell is one that "was a foretold
                    -- card before it was cast", and a copy was neither a card
                    -- nor cast (CR 707.10), so it was not foretold.
                    Object.foretold = Nothing,
                    -- CR 707.2: "text-changing effects ... are not copied",
                    -- and CR 702.47c makes splice one, so the copy has only
                    -- the printed text. Parun.CastSpec's Twincast splice case
                    -- is the proof.
                    Object.spliced = Seq.empty,
                    -- CR 123.1: stickers are not copiable. A regression
                    -- fence: no unit-1 board copies a stickered spell.
                    Object.stickers = Seq.empty,
                    -- CR 400.7d's record of what PAID, which CR 707.10 does not
                    -- carry across: the copy is neither cast nor activated, and
                    -- the rule's objects-used-to-pay sentence stops at objects --
                    -- its own example says a copy of Dawnglow Infusion gains no
                    -- life "because mana isn't an object". Forsworn Paladin's "if
                    -- mana from a Treasure was spent to activate this ability" is
                    -- the reader, and data/scenarios/copy's Forsworn Paladin
                    -- case the proof.
                    Object.manaSpent = Mana.Type.MkMana [],
                    -- CR 601.2b's record of how many Phyrexian symbols were
                    -- announced for life, dropped for a reason of its own rather
                    -- than the one above: rule 702.150a's compleated asks about
                    -- "the player who cast it", and CR 707.10's first sentence
                    -- says a copy of a spell isn't cast -- so there is no such
                    -- player and the clause cannot hold, whether or not CR
                    -- 707.2's "choices made when casting" reaches the
                    -- announcement. `announcedX` beside it is carried because CR
                    -- 707.10 names the value of X outright, and CR 107.3m reads
                    -- it off the spell without asking who cast it.
                    -- Parun.CopySpec's Tamiyo, Compleated Sage case is the proof.
                    Object.phyrexianLifePaid = 0,
                    -- CR 109.5's "you" is RE-STAMPED: Parun.Engine.Cast and
                    -- Parun.Engine.Activate write the caster or activator into it
                    -- as the original goes on the stack, and CR 707.10 makes the
                    -- copy's controller the seat `copier` named instead. The
                    -- RESERVED slots are the ones that can need a write of their
                    -- own, this one and `stampSelf`'s two above -- every other
                    -- binding is a DECISION, which CR 707.10 copies verbatim,
                    -- including an ability's self slot, so CR 707.10b's "the copy
                    -- refers to that same object" needs no write.
                    -- CR 707.10d's and CR 707.10e's targets, where the effect
                    -- chose them, over the decisions CR 707.10 copied. Empty
                    -- for the other two answers, which leave every one of them
                    -- standing.
                    Object.bindings = Binding.setYou copier (stampSelf (stampCopiable (Map.union (Maybe.fromMaybe (fmap Binding.toRecipients retarget) rebound) (Object.bindings obj))))
                  }
          State.put (Game.insertIntoZone Zone.Stack LibraryPosition.defaultValue copier copyId gs2 {GameState.objects = Map.insert copyId copy (GameState.objects gs2)})
          -- CR 707.10c's chooser is the COPY's controller and not the copying
          -- effect's: Meletis Charlatan's "that player may choose new targets
          -- for the copy". Proved by Parun.CopySpec's Charlatan group.
          Monad.when (targets == CopyTargets.ChosenByController) (Common.chooseNewTargetsFor False source copier copier copyId)
          -- CR 115.1: "these targets are declared as part of the process of
          -- putting the spell or ability on the stack", and CR 707.10c puts the
          -- copy on the stack once its controller has decided what its targets
          -- will be -- so each of them becomes a target of the copy, and CR
          -- 702.21a's ward fires on it.
          --
          -- EVERY target, not only the ones CR 707.10c changed: the copy "is
          -- itself a spell" -- or itself an ability -- under CR 707.10, so an
          -- object the copy kept is a target of something it was not a target of
          -- before. Read back off the board AFTER the re-target above rather than
          -- from the copied bindings, for the same reason.
          --
          -- The KIND is the copied object's, which copyOnStackOf classified: CR
          -- 707.10's "a copy of a spell is itself a spell" and "a copy of an
          -- ability is itself an ability".
          gsCopied <- State.get
          Event.becameTarget gsCopied copyId kind copier (Common.targetsOnStack copyId gsCopied)
          -- CR 707.10: a copy of a SPELL put onto the stack, which is not a
          -- cast, is the event magecraft's "or copy" watches (SpellCast.copies).
          Monad.when (kind == StackObjectKind.Spell) (State.modify' (Event.recordEvent (GameEvent.SpellCopied (SpellWasCopied.MkSpellWasCopied copier copyId))))

-- CR 115.7d over each named spell or ability still on the stack.
chooseNewTargets :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
chooseNewTargets resolving source controller legal = Common.retargetEach (Common.chooseNewTargetsFor False source controller) legal resolving controller source

-- CR 115.7a / 115.7b, the same walk with the stricter re-aim. `onto` is read
-- once, against the resolving effect's own bindings.
changeTargets :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ChangeTargets.ChangeTargets -> Game ()
changeTargets resolving source controller legal (ChangeTargets.MkChangeTargets ref onto) = do
  gs <- State.get
  let named = fmap (Set.fromList . objectRefObjects legal resolving controller source gs) onto
  Common.retargetEach (Common.changeTargetsFor named source controller) legal resolving controller source ref

armDelayedTrigger :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ArmDelayedTrigger.ArmDelayedTrigger (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
armDelayedTrigger resolving source controller legal arm@(ArmDelayedTrigger.MkArmDelayedTrigger name onset duration _) = do
  gs <- State.get
  -- CR 608.2h's last-known fallback, and not belt and braces: the source can
  -- have left an opcode earlier in this same list, CR 400.7 having deleted the
  -- id `source` names. CR 603.7: a rule 702 keyword has no card text to declare
  -- the far end in, so a name a minted ability arms resolves against rule 702's
  -- own roster instead; the two namespaces are kept disjoint by Parun.CardSpec.
  case Projection.armedDelayedAbility resolving source arm gs <|> Keyword.mintedDelayedAbility name of
    -- For a CARD's name the dataflow lint makes a dangling one a failing test,
    -- and this arm only keeps the executor total. A MINTED name has no such
    -- lint, so a forgotten roster row lands here and does nothing.
    Nothing -> pure ()
    Just ability ->
      -- CR 603.7d-f: the controller is the player who controlled the spell or
      -- ability AS IT RESOLVED, baked in now.
      --
      -- Binding.announcedTargets is left behind: it serves CR 601.2h's payment,
      -- and a copy given new targets (CR 707.10c) still carries the old group.
      -- A FENCE: no board in the suite arms a delayed ability off a retargeted copy.
      --
      -- CR 603.7c's environment takes its RECIPIENTS from the map the
      -- instruction was handed rather than off the object, exactly as the
      -- instruction's siblings read them: Effect.ForEach binds its member only
      -- there (Nihiloor's "that player"), a repeated mode's occurrence finds
      -- its own slots there under their printed names (CR 700.2d), and CR
      -- 608.2b has already dropped an illegal target from it. Every other
      -- field of a slot the object holds is kept. Nihiloor's scenario "steals
      -- from each opponent" proves the member. Overriding a name the object
      -- ALSO holds is a REGRESSION FENCE: mutating it leaves the suite green,
      -- since no pool card's delayed ability reads a target slot of a repeated
      -- mode or one CR 608.2b re-validated away. Scryfall o:"same mode more
      -- than once" (o:"next end step" or o:"when you do"), 2026-10-09, finds
      -- one delayed ability, Cabaretti Confluence's, and its sacrifice names
      -- the token rather than the target.
      let bound = maybe Map.empty Object.bindings (Game.lookupObject resolving gs)
          handedDown recipients binding = binding {Binding.Type.targets = if Set.null recipients then Nothing else Just recipients}
          captured =
            Map.delete Binding.announcedTargets . Map.filter (/= Binding.Type.empty) $
              Map.union (Map.intersectionWith handedDown legal bound) (Map.union bound (Map.map (`handedDown` Binding.Type.empty) legal))
       in -- CR 603.7a's other end: the BOUNDARY, not a turn number, for one
          -- printed "on your next turn". Which turn that names is settled as
          -- that turn begins (Event.settleOnsets). CR 603.7b's stated duration:
          -- the OUTER Maybe is the card printing no duration; the inner one is
          -- Expiry.arm reporting that a printed duration never STARTED (CR
          -- 611.2b).
          State.put (Event.armDelayed ability source controller captured (Event.armOnset (Common.oneSeat legal resolving source controller gs) source controller gs onset) (duration >>= \d -> Expiry.arm (Game.readingAcquisition resolving source) legal controller source d gs) gs)

replace :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Replace.Replace Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
replace resolving source controller legal (Replace.MkReplace duration uses origin condition re) =
  -- CR 614.3 / 615.3: install the floating replacement. Targetless and
  -- unprompted. CR 113.7: the SOURCE is this effect's source, which with the
  -- timestamp is the row's CR 614.5 identity. CR 614.15: the ORIGIN
  -- travels with the row rather than being re-derived.
  State.modify' $ \gs ->
    let context = effectContext gs resolving controller source legal (slotBindings resolving gs)
     in case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
          -- CR 611.2b: the duration never started.
          Nothing -> gs
          Just expiry ->
            let (ts, gs1) = Game.freshTimestamp gs
                active =
                  ActiveReplacement.MkActiveReplacement
                    { -- CR 601.2c / 608.2b: "target player" is the player this
                      -- resolution's slot names now, BAKED for `controller`'s
                      -- reason below.
                      ActiveReplacement.effect = Functor.runIdentity (overRelations (pure . Common.bakeRelation (Filter.slotPlayers context)) re),
                      ActiveReplacement.source = source,
                      -- CR 109.5: the resolution's controller, BAKED now --
                      -- the source is a spell CR 608.2n is about to put in a
                      -- graveyard, so it will have no controller to project
                      -- when the row is consulted.
                      ActiveReplacement.controller = controller,
                      ActiveReplacement.timestamp = ts,
                      ActiveReplacement.expiry = expiry,
                      ActiveReplacement.uses = uses,
                      ActiveReplacement.origin = origin,
                      -- CR 614.1: the clause's printed "if" rides the row and
                      -- is asked as the event would happen, never latched here
                      -- (see Parun.Types.ActiveReplacement).
                      ActiveReplacement.condition = condition,
                      ActiveReplacement.rider = Nothing,
                      -- The resolution's slot bindings, captured as the row is
                      -- installed for the reason Parun.Types.DelayedTrigger
                      -- captures them (CR 603.7c): this resolution is about to
                      -- end and its object with it, so a pattern naming a slot
                      -- would have nothing live to read. The row's `condition`
                      -- is asked against these too (Replacement.collect), so
                      -- the clause and the pattern cannot disagree about what a
                      -- slot names.
                      --
                      -- NARROWED to the slots THIS ROW names, installDamageRow's
                      -- restriction and for its reason: referredToSources reads
                      -- this map as CR 609.7a's "any object referred to by ... a
                      -- replacement or prevention effect that's waiting to
                      -- apply", and a slot an unrelated earlier effect of the
                      -- same resolution bound is not something this row refers
                      -- to. The CLAUSE's own reads join the row's, since it is
                      -- asked in a Context built from this very map.
                      ActiveReplacement.slots =
                        Map.restrictKeys
                          (Filter.slotObjects context)
                          (Map.keysSet (replacementRowSlots re) <> foldMap (Map.keysSet . conditionSlots) condition),
                      -- CR 608.2h, installDamageRow's bake.
                      ActiveReplacement.choices = SourceContext.choicesOf (Game.readingAcquisition resolving source gs source) source gs
                    }
             in gs1 {GameState.replacements = active : GameState.replacements gs1}

preventNextDamage :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> PreventNextDamage.PreventNextDamage (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
preventNextDamage resolving source controller legal chosen (PreventNextDamage.MkPreventNextDamage duration kind ref whatRecipient whoRecipient sourceFilter quantity riderEffects) = do
  -- CR 615.3 / 615.7: install a floating prevention shield, consulted at the
  -- damage funnel until it is spent or the duration expires. Its own opcode
  -- rather than an Effect.Replace carrying a DamageR, because the pattern has
  -- to name the shielded permanent or player by id, which card data cannot.
  -- Through Damage.damageRecipient, so the baked recipient is in the same
  -- vocabulary a DamageEvent's target arrives in (CR 120.1a).
  --
  -- ONE ROW PER NAMED RECIPIENT, which is CR 615.11: a shield over "each of a
  -- number of untargeted creatures" is a separate shield per creature, created
  -- as the spell resolves. Only ONE ROW ALTOGETHER for a card that DESCRIBES
  -- its recipients instead (Divine Deflection's "you and/or permanents you
  -- control"), which CR 615.11 does not reach -- it names neither "each" nor an
  -- untargeted creature -- leaving CR 615.7's plain shield: one countdown,
  -- reduced by 1 for each 1 damage it prevents, whatever it is around. A card
  -- writing both spellings is read as the description alone, since the
  -- described row already covers whatever it admits and a second row would be a
  -- second shield the card never printed.
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      describedRecipient = (whatRecipient, whoRecipient)
      described = Maybe.isJust whatRecipient || Maybe.isJust whoRecipient
      recipients = Maybe.mapMaybe (Damage.damageRecipient gs) (foldMap (Common.objectRefRecipients legal resolving controller source gs) ref)
      -- The recipient each row this resolution installs bakes: one row naming
      -- nobody for a described shield, and one per named recipient otherwise.
      rows = if described then [Nothing] else fmap Just recipients
      -- CR 615.5: the additional effect, BAKED onto the row with this
      -- resolution's chosen targets and CR 109.5's "you".
      rider = Common.preventionRider chosen controller source riderEffects
      -- HOW MUCH, read once per row, so a named row is handed its recipient's
      -- part of CR 601.2d's division (Quantity.Share), DealDamage's posture. A
      -- target CR 608.2b found illegal has no row, so its part shields nobody:
      -- data/scenarios/divide's Remedy case proves it. An unevaluable amount
      -- installs no row, DealDamage's posture too.
      amountOf row = Quantity.evaluateFor viewOf (maybe context (\recipient -> context {Filter.shares = Binding.sharesOf recipient (slotBindings resolving gs)}) row) gs resolving source quantity
      -- CR 615.7: a shield of 0 can prevent nothing, so none is installed --
      -- and neither is CR 609.7a's choice raised when no row is, a choice
      -- existing only to be baked into a row. CR 608.2b's gone target leaves a
      -- named shield no recipient, so there is nothing to shield. A DESCRIBED
      -- shield always has its one row, its recipients being read at the
      -- damage event rather than settled here.
      shields = [(row, Integer.toNaturalSaturating n) | row <- rows, Just n <- [amountOf row], n > 0]
  Monad.unless (null shields) $ do
    -- CR 609.7a: "the source is chosen when the effect is created", so the
    -- choice is made ONCE here and every shield this resolution installs
    -- watches the object it landed on.
    sourceChoice <- Common.chooseDamageSource controller resolving context gs sourceFilter
    case (sourceFilter, sourceChoice) of
      -- The card asked for a source and CR 609.7a's pool was empty, so
      -- there is nothing to shield against and no row is installed --
      -- stricter than printed rather than weaker, which a row watching
      -- every source would be.
      (Just _, Nothing) -> pure ()
      _ ->
        State.modify' $ \g0 ->
          List.foldl' (\g (row, amount) -> Common.installDamageRow resolving legal (Filter.slotObjects context) controller source duration kind (DamageRewrite.PreventNext amount) Uses.Unlimited rider (Filter.Type.And []) describedRecipient g (row, sourceChoice)) g0 shields

preventAllDamage :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> PreventAllDamage.PreventAllDamage (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
preventAllDamage resolving source controller legal chosen (PreventAllDamage.MkPreventAllDamage duration kind ref whatRecipient whoRecipient direction sourceFilter printedSource riderEffects) = do
  -- CR 615.1 / 615.3: one floating shield per object the ref names, with no
  -- amount to count down. PreventNextDamage's row but for its rewrite, hence
  -- the shared `installDamageRow`; CR 615.7's "reduced to 0" terminator does
  -- not exist here, so only the duration ends it. The recipient side goes
  -- through Damage.damageRecipient for PreventNextDamage's reason (CR
  -- 120.1a); the source side is an ObjectId and needs no such translation.
  --
  -- ONE ROW ALTOGETHER for a card that DESCRIBES its recipients instead (Pack
  -- Leader's "to Dogs you control", Comeuppance's "to you and planeswalkers you
  -- control"), PreventNextDamage's split exactly: CR
  -- 611.2c leaves that set live, so the row carries the predicate and
  -- Replacement re-asks it at each damage event rather than sweeping it here.
  -- A DealtTo card writing both spellings is read as the description alone;
  -- beside DealtBy the two are not alternatives at all, the ref naming the
  -- SOURCE there and the description the recipients, so both ride the row.
  gs <- State.get
  let named = foldMap (Common.objectRefRecipients legal resolving controller source gs) ref
      -- Through effectContext rather than Filter.contextFor, so CR 609.7a's
      -- candidates are narrowed against this resolution's own slot bindings
      -- and CR 109.5's "you" rather than against an empty slot map.
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      recipients = Maybe.mapMaybe (Damage.damageRecipient gs) named
      -- The recipient each row this resolution installs bakes: one row naming
      -- nobody for a described shield, and one per named recipient otherwise.
      --
      -- A shield naming NO recipient side at all -- Pay No Heed's "prevent all
      -- damage a source of your choice would deal this turn" -- gets that same
      -- lone row, whose Nothing recipient is DamagePattern's "every recipient".
      -- The empty `ref` is what tells it apart from CR 608.2b's gone target,
      -- which is a card that DID name a recipient and lost it: that one keeps
      -- installing nothing.
      rows = if Maybe.isJust whatRecipient || Maybe.isJust whoRecipient || Maybe.isNothing ref then [Nothing] else fmap Just recipients
      -- CR 615.5's additional effect. With no amount to count down, "this way"
      -- is what THIS application prevented, which Prevention.amounts carries.
      rider = Common.preventionRider chosen controller source riderEffects
  -- Which SIDE of the damage event the ref's objects sit on, and which
  -- question the source half of the row answers.
  case direction of
    -- A DealtBy row watches CR 120.1's source, which is always an OBJECT, so a
    -- player the ref named drops out. A card describing no recipient names
    -- none on the row either, so the damage Dovin, Hand of Control's shielded
    -- permanent would deal to a PLAYER is prevented as much as the damage it
    -- would deal to a permanent.
    --
    -- The source half here is CR 601.2c's TARGET, and CR 609.7a's player
    -- CHOICE is a different question, so the chosenSource field is not read on
    -- this side: a card writing both would be naming two sources (see
    -- Parun.Types.PreventAllDamage). It gets the trivial predicate beside the
    -- id, CR 615.9's recheck being of a CHOSEN source's printed properties,
    -- and a target has none -- CR 608.2b already rechecked its legality as the
    -- ability resolved.
    --
    -- CR 609.7b's PRINTED properties are a predicate rather than a second
    -- name, so they are threaded on this side too; every by-direction card in
    -- data/cards/ leaves them trivial.
    --
    -- The DESCRIBED recipient rides this side too: CR 615.1's shield watches a
    -- damage EVENT, and a card may narrow either end of it (Goblin Furrier's
    -- "prevent all damage that this creature would deal to snow creatures"), so
    -- the two halves conjoin on the row rather than the description being
    -- dropped for the source's sake. `rows` is not consulted here -- the fold is
    -- over the ids the ref named, and each row bakes CR 601.2c's source beside
    -- the live predicate.
    DamageDirection.DealtBy ->
      State.modify' $ \g0 -> List.foldl' (Common.installDamageRow resolving legal (Filter.slotObjects context) controller source duration kind DamageRewrite.PreventAll Uses.Unlimited rider printedSource (whatRecipient, Nothing)) g0 (fmap (\oid -> (Nothing, Just (Filter.Type.And [], oid))) (Maybe.mapMaybe Recipient.objectOf named))
    DamageDirection.DealtTo ->
      -- No row is CR 608.2b's gone target -- a named recipient that left -- so
      -- there is nothing to shield and CR 609.7a's choice, a choice existing
      -- only to be baked into a row, is not raised either. PreventNextDamage's
      -- posture. A DESCRIBED shield always has its one row, its recipients
      -- being read at the damage event rather than settled here, and so does a
      -- shield naming no recipient at all (`rows` above).
      Monad.unless (null rows) $ do
        -- CR 609.7a: "the source is chosen when the effect is created", so the
        -- choice is made ONCE here and every shield this resolution installs
        -- watches the object it landed on.
        sourceChoice <- Common.chooseDamageSource controller resolving context gs sourceFilter
        case (sourceFilter, sourceChoice) of
          -- The card asked for a source and CR 609.7a's pool was empty, so
          -- there is nothing to shield against and no row is installed --
          -- stricter than printed rather than weaker, which a row watching
          -- every source would be.
          (Just _, Nothing) -> pure ()
          _ -> State.modify' $ \g0 -> List.foldl' (Common.installDamageRow resolving legal (Filter.slotObjects context) controller source duration kind DamageRewrite.PreventAll Uses.Unlimited rider printedSource (whatRecipient, whoRecipient)) g0 (fmap (\recipient -> (recipient, sourceChoice)) rows)

preventNextDamageInstance :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> PreventNextDamageInstance.PreventNextDamageInstance (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
preventNextDamageInstance resolving source controller legal chosen (PreventNextDamageInstance.MkPreventNextDamageInstance duration ref sourceFilter riderEffects) = do
  -- CR 615.8: install a shield that prevents ONE instance of damage from the
  -- chosen source. The rewrite is PreventAll -- "regardless of how much damage
  -- that is", which is the whole event and never CR 615.7's arithmetic -- and
  -- what makes it the NEXT instance rather than every one is Uses.Once, CR
  -- 614.3's use count, the same spelling CR 701.19a's "the next time this
  -- permanent would be destroyed this turn" already takes.
  --
  -- CR 609.7b falls out of that reading rather than needing an arm: a use is
  -- spent by Event.apply, which runs only where the shield actually prevented
  -- the damage, so a shield that prevented none -- CR 615.12's unpreventable
  -- damage, a source whose properties stopped matching -- is not used up.
  --
  -- ONE ROW PER NAMED RECIPIENT, PreventNextDamage's split, and a fold rather
  -- than a single row because an ObjectRef may name several. Every printing of
  -- this rule names exactly one -- Deflecting Palm's "to you", Honorable
  -- Passage's "to any target" -- so one row is what is installed today.
  gs <- State.get
  let context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      recipients = Maybe.mapMaybe (Damage.damageRecipient gs) (Common.objectRefRecipients legal resolving controller source gs ref)
      -- CR 615.5's additional effect, run as part of the prevention rather
      -- than put on the stack: Reverse Damage's life, Deflecting Palm's damage
      -- back.
      rider = Common.preventionRider chosen controller source riderEffects
  -- No recipient is CR 608.2b's gone target, so there is nothing to shield and
  -- CR 609.7a's choice -- a choice existing only to be baked into a row -- is
  -- not raised either. The sibling shields' posture.
  Monad.unless (null recipients) $ do
    -- CR 609.7a: "the source is chosen when the effect is created", so the
    -- choice is made ONCE here.
    sourceChoice <- Common.chooseDamageSource controller resolving context gs (Just sourceFilter)
    case sourceChoice of
      -- CR 609.7a's pool was empty, so there is nothing to shield and no row is
      -- installed -- stricter than printed rather than weaker, which a row
      -- watching every source would be.
      Nothing -> pure ()
      Just _ -> State.modify' $ \g0 -> List.foldl' (Common.installDamageRow resolving legal (Filter.slotObjects context) controller source duration Nothing DamageRewrite.PreventAll Uses.Once rider (Filter.Type.And []) (Nothing, Nothing)) g0 (fmap (\recipient -> (Just recipient, sourceChoice)) recipients)

redirectDamage :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RedirectDamage.RedirectDamage -> Game ()
redirectDamage resolving source controller legal (RedirectDamage.MkRedirectDamage duration kind amount srcRef whatRecipient whoRecipient destRef sourceFilter uses whatSource) = do
  -- CR 614.9: install a floating redirection effect. BOTH sides are baked here,
  -- both being known only at resolution: the source side into
  -- DamagePattern.whichRecipient, the destination into the rewrite. Both
  -- through Damage.damageRecipient (CR 120.1a). The rule's own guard is re-asked
  -- at redirect time, in Event.apply, the destination being able to leave.
  --
  -- ONE ROW PER NAMED RECIPIENT, and ONE ROW ALTOGETHER for a card that
  -- DESCRIBES its recipients instead -- PreventNextDamage's split, for its
  -- reason: Harm's Way's "to you and/or permanents you control" is Divine
  -- Deflection's shape, one countdown read live at each damage event (CR
  -- 611.2c), where Carom's "target creature" is a recipient the resolution
  -- fixed (CR 601.2c). A card writing both spellings is read as the
  -- description alone.
  gs <- State.get
  let viewOf = effectViewOf resolving source legal gs
      recipientsOf ref = Maybe.mapMaybe (Damage.damageRecipient gs) (Common.objectRefRecipients legal resolving controller source gs ref)
      -- Through effectContext rather than Filter.contextFor, for
      -- PreventAllDamage's reason: CR 609.7a's candidates are narrowed against
      -- this resolution's own slot bindings and CR 109.5's "you".
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      describedRecipient = (whatRecipient, whoRecipient)
      described = Maybe.isJust whatRecipient || Maybe.isJust whoRecipient
      redirected = foldMap recipientsOf srcRef
      -- The recipient each row this resolution installs bakes: one row naming
      -- nobody for a described redirection, and one per named recipient
      -- otherwise.
      rows = if described then [Nothing] else fmap Just redirected
      -- CR 615.7's counted shape on this rewrite, its amount evaluated ONCE as
      -- the effect is created (Harm's Way's "the next 2 damage"); Nothing is
      -- Turn the Tables' uncounted "all". A redirection of 0 can move nothing,
      -- so none is installed, PreventNextDamage's posture; an unevaluable
      -- amount is a no-op, DealDamage's.
      rewriteTo dest = case amount of
        Nothing -> Just (DamageRewrite.Redirect dest)
        Just quantity -> case Quantity.evaluateFor viewOf context gs resolving source quantity of
          Just n | n > 0 -> Just (DamageRewrite.RedirectNext (Integer.toNaturalSaturating n) dest)
          _ -> Nothing
  -- EXACTLY ONE destination (CR 614.9). None means CR 608.2b's target is
  -- already gone, so no row is installed.
  case fmap rewriteTo (recipientsOf destRef) of
    [Just rewrite] ->
      -- No recipient to redirect FROM is CR 608.2b's gone target, so there is
      -- nothing to install and CR 609.7a's choice -- a choice existing only to
      -- be baked into a row -- is not raised either. The prevention opcodes'
      -- posture. A DESCRIBED redirection always has its one row, its
      -- recipients being read at the damage event rather than settled here.
      Monad.unless (null rows) $ do
        -- CR 609.7a: "the source is chosen when the effect is created", so the
        -- choice is made ONCE here and every row this resolution installs
        -- watches the object it landed on.
        sourceChoice <- Common.chooseDamageSource controller resolving context gs sourceFilter
        case (sourceFilter, sourceChoice) of
          -- The card asked for a source and CR 609.7a's pool was empty, so
          -- there is nothing to redirect and no row is installed -- stricter
          -- than printed rather than weaker, which a row watching every source
          -- would be.
          (Just _, Nothing) -> pure ()
          _ -> State.modify' $ \g0 -> List.foldl' (Common.installDamageRow resolving legal (Filter.slotObjects context) controller source duration kind rewrite uses Nothing whatSource describedRecipient) g0 (fmap (\recipient -> (recipient, sourceChoice)) rows)
    _ -> pure ()

skipPhase :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SkipPhase.SkipPhase -> Game ()
skipPhase resolving source controller legal (SkipPhase.MkSkipPhase ref selector uses duration) = do
  -- CR 614.1b: "skip" is a replacement effect, installed floating because a
  -- sorcery's skip outlives the sorcery (CR 614.3). CR 614.10a: one instance
  -- PER NAMED PLAYER, each its own row rather than merged, so "skip the next
  -- two" is two rows and Replacement.consume spends the one it applied.
  --
  -- CR 614.3's two terminators are card data. "Next" is Uses.Once under
  -- Duration.Indefinite, waiting however many turns it must (CR 614.10a);
  -- "all combat phases of their next turn" is Uses.Unlimited under a window
  -- that Replacement.collect holds back until that turn (Expiry.begun). A
  -- window that cannot begin stores nothing (Expiry.arm). The PhaseSelector
  -- goes in untouched: step or whole phase (CR 500.1) is card data.
  --
  -- CR 805.8: under the shared team turns option one effect naming several
  -- players on a team skips that team's step once, so the team's first named
  -- player takes the one row. Replacement.applies matches it for the team.
  gs <- State.get
  let named = List.foldl' (\kept pid -> if any (Turn.sharesTurn gs pid) kept then kept else kept <> [pid]) [] (playerRefPlayers legal resolving source controller gs ref)
      install pid g = case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration g of
        Nothing -> g
        Just expiry ->
          let (ts, g1) = Game.freshTimestamp g
              active =
                ActiveReplacement.MkActiveReplacement
                  { ActiveReplacement.effect =
                      ReplacementEffect.PhaseR
                        PhasePattern.MkPhasePattern
                          { PhasePattern.whichPhase = selector,
                            -- The player the resolution named, baked now. Card
                            -- data cannot name one (see
                            -- Parun.Types.PhasePattern).
                            PhasePattern.whosePhase = Just pid
                          },
                    ActiveReplacement.source = source,
                    -- CR 109.5: the resolution's controller, not `pid` above,
                    -- which the effect NAMED; nothing reads this, a PhaseR
                    -- resolving no ControllerRelation.
                    ActiveReplacement.controller = controller,
                    ActiveReplacement.timestamp = ts,
                    ActiveReplacement.expiry = expiry,
                    ActiveReplacement.uses = uses,
                    ActiveReplacement.origin = ReplacementOrigin.Other,
                    -- No clause: CR 614.10a's skip states none (see
                    -- Parun.Types.ActiveReplacement).
                    ActiveReplacement.condition = Nothing,
                    ActiveReplacement.rider = Nothing,
                    ActiveReplacement.slots = Map.empty,
                    -- CR 608.2h, installDamageRow's bake; a PhaseR reads none.
                    ActiveReplacement.choices = SourceContext.choicesOf (Game.readingAcquisition resolving source g source) source g
                  }
           in g1 {GameState.replacements = active : GameState.replacements g1}
  State.modify' (\g -> List.foldl' (flip install) g named)

affectPlayers :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> AffectPlayers.AffectPlayers -> Game ()
affectPlayers resolving source controller legal (AffectPlayers.MkAffectPlayers duration affected playerEffect) =
  -- CR 611.1 / 613.11: install the stored player effect. CR 109.5: the
  -- CONTROLLER is baked in now, the source having none to project once it
  -- leaves the stack. A SCOPED set is not baked, CR 611.2c letting a
  -- rules-modifying effect reach objects it did not begin with, so it is
  -- re-resolved on every read. A NAMED set is baked, the bindings that answer a
  -- target slot (CR 601.2c) being gone once this resolution is over; an
  -- unfilled or illegal slot stores nothing (CR 608.2b).
  State.modify' $ \gs ->
    let baked = case affected of
          AffectedPlayers.Scoped scope -> [AffectedPlayers.Scoped scope]
          -- Through playerRefPlayers so the slot is read exactly as every
          -- other opcode reads one, CR 608.2b's empty answer included.
          AffectedPlayers.Named slot ->
            fmap AffectedPlayers.Named (playerRefPlayers legal resolving source controller gs (PlayerRef.InSlot slot))
        -- CR 601.2c / 608.2b: a zone reference inside the payload is a read of
        -- this resolution's bindings, so it is baked here for the reason the
        -- Named set above is -- Sen Triplets' "that player's hand" is the
        -- targeted opponent, and the slot is gone once this resolution is.
        -- Parun.Engine.Condition.bakeBound is the precedent, and its posture
        -- for a slot naming nobody: the reference is left standing and reads
        -- as naming nobody, rather than falling back to some other seat.
        --
        -- An object's controller or owner is fixed NOW, as the seat it names
        -- at resolution (through playerRefPlayers' CR 608.2h last-known
        -- read), not baked to the object: only a CR 611.2b condition is
        -- re-checked later. A regression fence: no card in data/cards/ puts
        -- any of these references in a player effect.
        atResolution ref = case ref of
          PlayerRef.HolderOfBound {} -> seatNow ref
          _ -> Quantity.bakePlayerRef (Binding.playersIn legal) Map.empty ref
        seatNow ref = case playerRefPlayers legal resolving source controller gs ref of
          [pid] -> PlayerRef.Specific pid
          _ -> ref
        withPlayers = PlayerEffect.mapPlayerRefs atResolution playerEffect
        -- CR 601.2c / 608.2b again, one payload over: a DamagePattern's
        -- `boundRecipient` names the slot this resolution filled, and the
        -- recipient it named is written into `whichRecipient` here --
        -- Whippoorwill's "damage that would be dealt to THAT CREATURE this
        -- turn can't be prevented". The slot dies with the resolution, so
        -- nothing later could read it; installDamageRow bakes a shield's
        -- recipient at the same moment and for the same reason.
        --
        -- Through the LIST applicative, so a slot naming several recipients
        -- stores one effect apiece and a slot naming none stores nothing at
        -- all, which is rule 608.2b's answer for an illegal target. A
        -- pattern naming no slot yields exactly one effect, unchanged.
        bakedEffects = PlayerEffect.overDamagePatterns (Common.bakeDamagePatternRecipient legal resolving controller source gs) withPlayers
        -- CR 611.2b: a duration that never started stores nothing. A window
        -- naming "that player" (Expiry.perSeat) is one window per affected
        -- player, each its own row over that one seat: Sphinx's Decree's
        -- opponents each have a different next turn, so the set is fixed as
        -- the effect begins.
        armed = case Expiry.perSeat duration of
          Nothing -> [(scope, expiry) | expiry <- Maybe.maybeToList (Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs), scope <- baked]
          Just seated ->
            [ (AffectedPlayers.Named pid, expiry)
            | pid <- Game.stillPlaying gs,
              any (PlayerEffect.applies pid controller gs) baked,
              expiry <- Maybe.maybeToList (Expiry.arm (Game.readingAcquisition resolving source) legal controller source (seated pid) gs)
            ]
        install g ((scope, expiry), bakedEffect) =
          let (ts, g1) = Game.freshTimestamp g
              active =
                ActivePlayerEffect.MkActivePlayerEffect
                  { ActivePlayerEffect.source = source,
                    ActivePlayerEffect.controller = controller,
                    -- CR 608.2h: the choices made so far, determined once as
                    -- the effect begins (Parun.Types.ActivePlayerEffect).
                    ActivePlayerEffect.choices = SourceContext.choicesOf (Game.readingAcquisition resolving source gs source) source gs,
                    ActivePlayerEffect.timestamp = ts,
                    ActivePlayerEffect.expiry = expiry,
                    ActivePlayerEffect.scope = scope,
                    ActivePlayerEffect.effect = bakedEffect,
                    ActivePlayerEffect.ability = resolvingAbilityName resolving gs,
                    -- Filled after this resolution, by the cast that uses a
                    -- grant beside it (Parun.Engine.Cast.bindUser). Not
                    -- implemented: capturing a slot this resolution bound
                    -- (#5706).
                    ActivePlayerEffect.slots = Map.empty
                  }
           in g1 {GameState.playerEffects = active : GameState.playerEffects g1}
     in List.foldl' install gs ((,) <$> armed <*> bakedEffects)

requireBlock :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RequireBlock.RequireBlock -> Game ()
requireBlock resolving source controller legal (RequireBlock.MkRequireBlock duration blockerRef attackerRef arity) =
  -- CR 509.1c / 613.11: store one row per (blocker, attacker) pair the two
  -- sides name. A Named side is enumerated ONCE, for the CR 608.2f
  -- simultaneity objectRefObjects buys; an illegal slot (CR 608.2b) stores
  -- nothing, which is provoke's fizzle. A Matching class is RequireAttack's
  -- below: one row, its bound players baked now, since CR 611.2c keeps a
  -- requirement on a declaration dynamic (Alluring Scent). An absent attacker
  -- is one row naming none (Predatory Rampage). How many requirements the rows
  -- state is `arity`, read at Parun.Engine.BlockRequirement.
  State.modify' $ \gs -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
    -- CR 611.2b: the duration never started, so nothing is stored.
    Nothing -> gs
    Just expiry ->
      let restricted side = case side of
            RestrictedCreatures.Named ref -> fmap RestrictedCreatures.Named (objectRefObjects legal resolving controller source gs ref)
            RestrictedCreatures.Matching f -> [RestrictedCreatures.Matching (Common.storedClass legal resolving controller source gs f)]
          blockers = restricted blockerRef
          attackers = maybe [Nothing] (fmap Just . restricted) attackerRef
          (ts, gs1) = Game.freshTimestamp gs
          stored = do
            blocker <- blockers
            attacker <- attackers
            pure
              ActiveBlockRequirement.MkActiveBlockRequirement
                { ActiveBlockRequirement.source = source,
                  ActiveBlockRequirement.controller = controller,
                  ActiveBlockRequirement.timestamp = ts,
                  ActiveBlockRequirement.expiry = expiry,
                  ActiveBlockRequirement.blocker = blocker,
                  ActiveBlockRequirement.attacker = attacker,
                  ActiveBlockRequirement.arity = arity
                }
       in gs1 {GameState.blockRequirements = stored <> GameState.blockRequirements gs1}

prohibit :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Prohibit.Prohibit -> Game ()
prohibit resolving source controller legal (Prohibit.MkProhibit what duration affected) =
  -- CR 611.2a / 613.11: store one prohibition per permanent a Named ref names,
  -- or ONE row for a Matching class -- ForbidAttack's two readings below, and
  -- for its reasons: the ref is enumerated ONCE, for the CR 608.2f
  -- simultaneity objectRefObjects buys, and an illegal slot (CR 608.2b) stores
  -- nothing, which is Hurr Jackal's fizzle; the class is CR 611.2c's, a
  -- prohibition modifying no characteristic and no controller, so it reaches
  -- permanents that arrive after this resolution (Exhaustion), with its bound
  -- players baked now.
  --
  -- Nothing is written onto the permanent itself, and nothing is projected: CR
  -- 613.11 keeps each of these out of the layers, so the row is read through
  -- Parun.Engine.RestrictedCreatures.prohibited and never by a projection. CR
  -- 701.19c makes the Regenerate row a property the DESTRUCTION acquires, at
  -- Event.resolveDestruction.
  State.modify' $ \gs -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
    -- CR 611.2b: the duration never started, or a "for as long as" one has
    -- already ended (Wall of Stolen Identity gone before its trigger
    -- resolved), so nothing is stored.
    Nothing -> gs
    Just expiry ->
      let subjects = case affected of
            RestrictedCreatures.Named ref -> fmap RestrictedCreatures.Named (objectRefObjects legal resolving controller source gs ref)
            RestrictedCreatures.Matching f -> [RestrictedCreatures.Matching (Common.storedClass legal resolving controller source gs f)]
          (ts, gs1) = Game.freshTimestamp gs
          stored =
            fmap
              ( \subject ->
                  ActiveObjectProhibition.MkActiveObjectProhibition
                    { ActiveObjectProhibition.source = source,
                      ActiveObjectProhibition.controller = controller,
                      ActiveObjectProhibition.timestamp = ts,
                      ActiveObjectProhibition.expiry = expiry,
                      ActiveObjectProhibition.what = what,
                      ActiveObjectProhibition.affected = subject
                    }
              )
              subjects
       in gs1 {GameState.objectProhibitions = stored <> GameState.objectProhibitions gs1}

forbidAttack :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ForbidAttack.ForbidAttack -> Game ()
forbidAttack resolving source controller legal (ForbidAttack.MkForbidAttack duration affected aimedAt) =
  -- CR 508.1c / 611.1: store one restriction per permanent a Named ref names,
  -- or ONE row for a Matching class. Prohibit above is the model for the
  -- first and every one of its arguments carries over: the ref is enumerated
  -- ONCE, for the CR 608.2f simultaneity objectRefObjects buys, and an illegal
  -- slot (CR 608.2b) stores nothing, which is Netter en-Dal's fizzle.
  --
  -- The class is NOT enumerated, CR 611.2c's third sentence: a restriction on a
  -- declaration modifies no characteristic and no controller, so it reaches
  -- creatures that enter after this resolution, and the Filter is stored to be
  -- re-read at each declaration. Its bound player and object slots are baked
  -- now, Expiry.arm's reason for baking a ForAsLongAs condition -- the bindings
  -- that answer them are gone once this resolution is over.
  --
  -- CR 109.5's controller is baked, AffectPlayers' reason: the source is a
  -- sorcery in a graveyard by the time "you" is asked of the row.
  --
  -- Nothing is written onto the permanent itself, and nothing is projected: CR
  -- 613.11 keeps a restriction on a declaration out of the layers, so the row
  -- is read at Parun.Engine.CombatRestriction.attackProhibited (or, aimed, at
  -- Parun.Engine.CombatRestriction.cantAttackPlayer) and never by a projection.
  State.modify' $ \gs -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
    -- CR 611.2b: the duration never started, so nothing is stored.
    Nothing -> gs
    Just expiry ->
      let subjects = case affected of
            RestrictedCreatures.Named ref -> fmap RestrictedCreatures.Named (objectRefObjects legal resolving controller source gs ref)
            RestrictedCreatures.Matching f -> [RestrictedCreatures.Matching (Common.storedClass legal resolving controller source gs f)]
          -- A slot's players baked now, one row each, for the class's reason:
          -- the binding is gone once this resolution is over. A slot naming
          -- nobody stores nothing (Chaos Dragon's "those players").
          aims = case aimedAt of
            Just (AimedAt.MkAimedAt (AimedPlayers.EachInSlot slot) kinds) ->
              fmap (\pid -> Just (AimedAt.MkAimedAt (AimedPlayers.BoundPlayer pid) kinds)) (playerRefPlayers legal resolving source controller gs (PlayerRef.EachInSlot slot))
            _ -> [aimedAt]
          (ts, gs1) = Game.freshTimestamp gs
          stored = do
            subject <- subjects
            aim <- aims
            pure
              ActiveAttackProhibition.MkActiveAttackProhibition
                { ActiveAttackProhibition.source = source,
                  ActiveAttackProhibition.controller = controller,
                  ActiveAttackProhibition.timestamp = ts,
                  ActiveAttackProhibition.expiry = expiry,
                  ActiveAttackProhibition.affected = subject,
                  ActiveAttackProhibition.aimedAt = aim
                }
       in gs1 {GameState.attackProhibitions = stored <> GameState.attackProhibitions gs1}

forbidBeingBlocked :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ForbidBeingBlocked.ForbidBeingBlocked -> Game ()
forbidBeingBlocked resolving source controller legal (ForbidBeingBlocked.MkForbidBeingBlocked duration f barred) =
  -- CR 509.1b / 611.2c: store ONE row for the class, ForbidAttack's Matching
  -- arm and for its reasons -- not enumerated, so a creature that enters after
  -- this resolution is inside it; bound players baked now; CR 109.5's
  -- controller stored. Read at
  -- Parun.Engine.CombatRestriction.storedEvasions, never by a projection.
  State.modify' $ \gs -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
    -- CR 611.2b: the duration never started, so nothing is stored.
    Nothing -> gs
    Just expiry ->
      let (ts, gs1) = Game.freshTimestamp gs
          stored =
            ActiveEvasion.MkActiveEvasion
              { ActiveEvasion.source = source,
                ActiveEvasion.controller = controller,
                ActiveEvasion.timestamp = ts,
                ActiveEvasion.expiry = expiry,
                ActiveEvasion.affected = Common.storedClass legal resolving controller source gs f,
                ActiveEvasion.blockers = Common.storedClass legal resolving controller source gs barred
              }
       in gs1 {GameState.evasions = stored : GameState.evasions gs1}

requireAttack :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> RequireAttack.RequireAttack -> Game ()
requireAttack resolving source controller legal (RequireAttack.MkRequireAttack duration attackerRef defenderRef) =
  -- CR 508.1d / 613.11: store one requirement per (attacker, defender) pair,
  -- rule 508.1d counting requirements PER CREATURE. A Named ref is RequireBlock's
  -- twin: enumerated ONCE for CR 608.2f's simultaneity, and an illegal slot (CR
  -- 608.2b) stores nothing, which is Alluring Siren's fizzle. A Matching class
  -- is ForbidAttack's: one row per defender, its bound players baked now, since
  -- CR 611.2c keeps a requirement on a declaration dynamic.
  State.modify' $ \gs -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
    -- CR 611.2b: the duration never started, so nothing is stored.
    Nothing -> gs
    Just expiry ->
      let attackers = case attackerRef of
            RestrictedCreatures.Named ref -> fmap RestrictedCreatures.Named (objectRefObjects legal resolving controller source gs ref)
            RestrictedCreatures.Matching f -> [RestrictedCreatures.Matching (Common.storedClass legal resolving controller source gs f)]
          -- Through playerRefPlayers and objectRefObjects so a ref is read
          -- exactly as every other opcode reads one, CR 608.2b's empty answer
          -- included. A permanent becomes the announcement CR 508.1b names it
          -- by as of now -- a planeswalker (CR 306.6) or a battle (CR 310.5)
          -- -- and anything else stores nothing. One no longer attackable at
          -- the declaration is pruned there by membership
          -- (Parun.Engine.AttackRequirement's fromStored). A requirement naming
          -- no defender stores one row per attacker, obeyed by any
          -- announcement.
          defenders = case defenderRef of
            Nothing -> [Nothing]
            Just (AttackTargetRef.Players ref) -> fmap (Just . AttackTarget.OfPlayer) (playerRefPlayers legal resolving source controller gs ref)
            Just (AttackTargetRef.Permanents ref) -> fmap Just (Maybe.mapMaybe announcement (objectRefObjects legal resolving controller source gs ref))
          announcement oid
            | Projection.isPlaneswalkerOf oid gs = Just (AttackTarget.OfPlaneswalker oid)
            | Projection.isBattleOf oid gs = Just (AttackTarget.OfBattle oid)
            | otherwise = Nothing
          (ts, gs1) = Game.freshTimestamp gs
          stored = do
            attacker <- attackers
            defender <- defenders
            pure
              ActiveAttackRequirement.MkActiveAttackRequirement
                { ActiveAttackRequirement.source = source,
                  ActiveAttackRequirement.controller = controller,
                  ActiveAttackRequirement.timestamp = ts,
                  ActiveAttackRequirement.expiry = expiry,
                  ActiveAttackRequirement.attacker = attacker,
                  ActiveAttackRequirement.defender = defender
                }
       in gs1 {GameState.attackRequirements = stored <> GameState.attackRequirements gs1}

createEmblem :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> CreateEmblem.CreateEmblem Card.Type.Card -> Game ()
createEmblem resolving source controller legal (CreateEmblem.MkCreateEmblem card player) = do
  gs <- State.get
  -- CR 114.2: each player the reference names gets an emblem, minted by
  -- Event.createEmblem, in APNAP order as Effect.Create's creators are (CR
  -- 608.2f). A target slot CR 608.2b found illegal names nobody.
  Monad.forM_ (Common.apnapPlayersOf player legal resolving source controller gs) $ \getter ->
    Event.createEmblem getter card

becomeMonarch :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> MonarchTarget.MonarchTarget -> Game ()
becomeMonarch resolving source controller legal target = do
  gs <- State.get
  let newMonarch = Common.oneSeat legal resolving source controller gs $ case target of
        MonarchTarget.TheController -> PlayerRef.Relative PlayerRelation.You
        -- CR 725.2: the controller of the ability's bound source, read from the
        -- reserved trigger-source slot through CR 608.2h's last known
        -- information: the creature that stole the crown by connecting is
        -- routinely dead by the time this resolves -- it traded with its
        -- blocker in the same damage step. Same reading as
        -- Event.Binding.combatDamagerOn, which admitted the damager.
        MonarchTarget.ControllerOfSource -> PlayerRef.HolderOfBound Holder.Controller Hop.Itself Binding.triggerSource
        -- CR 601.2c's chosen player, re-checked under CR 608.2b: the slot is a
        -- TARGET, so an illegal one crowns nobody while the rest of the ability
        -- still resolves.
        MonarchTarget.InSlot slot -> PlayerRef.InSlot slot
  case newMonarch of
    Nothing -> pure ()
    -- CR 101.2: a "can't become the monarch" effect outranks this instruction
    -- and the crown does not move. Read here rather than at the three
    -- MonarchTarget arms, so every route this opcode has is stopped at once.
    Just p | PlayerEffect.prohibitsBecomingMonarch p gs -> pure ()
    -- CR 725.3's handoff, the CR 603.2 event and CR 725's exile watches are all
    -- Monarch.crown's, so no caller can move the crown without them.
    Just p -> State.modify' (Monarch.crown p)

-- CR 726.1: the initiative moves, whichever InitiativeTarget named the taker.
takeTheInitiative :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> InitiativeTarget.InitiativeTarget -> Game ()
takeTheInitiative resolving source controller legal target = do
  gs <- State.get
  let taker = Common.oneSeat legal resolving source controller gs $ case target of
        InitiativeTarget.TheController -> PlayerRef.Relative PlayerRelation.You
        -- CR 726.2: the controller of the ability's bound source, for
        -- Effect.BecomeMonarch ControllerOfSource's reason one rule over.
        InitiativeTarget.ControllerOfSource -> PlayerRef.HolderOfBound Holder.Controller Hop.Itself Binding.triggerSource
  case taker of
    Nothing -> pure ()
    -- CR 726.3's hand-off, CR 726.5's re-take and the CR 603.2 event are all
    -- Initiative.takeInitiative's, so no caller can move the designation
    -- without them. No eligibility gate, where the crown has one: rule 726
    -- states no "can't take the initiative" effect.
    Just p -> State.modify' (Initiative.takeInitiative p)

-- The slot's permanent gains the designation (CR 702.112a, CR 701.37a, CR
-- 701.60a) -- a state write, not a CR 613 modification.
--
-- GameEvent.BecameDesignated is emitted only on a TRANSITION (CR 701.60d); a
-- player recipient, an illegal slot (CR 608.2b) and an id naming no object all
-- write nothing. CR 701.60c's menace and can't-block are read off
-- Object.designations live.
--
-- Parun.Engine.Prepare.mayGain is CR 722.3a's own precondition beside the
-- transition guard -- "a permanent can't gain this designation unless it has a
-- prepare spell" -- and mintOnDesignated is CR 722.3c's copy, run in the same
-- breath as the write because the rule says "AS a permanent ... gains the
-- prepared designation". Both are keyed on WHICH designation and neither asks
-- which card; see that module.
designate :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Designate.Designate -> Game ()
designate resolving source controller legal (Designate.MkDesignate designation slot mValue) =
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure ()
      Just target -> do
        gs <- State.get
        -- CR 701.37c's X, settled against the RESOLUTION -- the ability's own
        -- source and slots, `Effect.Create`'s reading of its count -- so a
        -- "Monstrosity X" reads the X its activation announced (CR 601.2b) and
        -- not a live board. Written on the TRANSITION alone, with the mark, so
        -- CR 701.37a's second monstrosity leaves the first value standing.
        let value =
              Quantity.evaluateFor (effectViewOf resolving source legal gs) (effectContext gs resolving controller source legal (slotBindings resolving gs)) gs resolving source
                =<< mValue
            mark o = o {Object.designations = Set.insert designation (Object.designations o)}
            recordValue o = maybe o (\n -> o {Object.designationValues = Map.insert designation (Integer.toNaturalSaturating n) (Object.designationValues o)}) value
        Monad.when (maybe False (not . Set.member designation . Object.designations) (Game.lookupObject target gs) && Prepare.mayGain designation target gs) $ do
          State.modify'
            (\g -> g {GameState.objects = Map.adjust (recordValue . mark) target (GameState.objects g)})
          State.modify' (Event.recordEvent (GameEvent.BecameDesignated (BecameDesignated.MkBecameDesignated designation target)))
          Prepare.mintOnDesignated designation target
    _ -> pure ()

-- CR 716.2a: "This Class's level becomes N." A state write on the slot's
-- permanent, not a CR 613 modification -- CR 716.2b makes a level a designation,
-- which is what Object.classLevel holds and what the Designate arm above writes
-- the boolean marks into.
--
-- BECOMES rather than increments, and the level bar's own
-- ActivationRestriction.OnlyIf is the only thing that keeps the ladder in order
-- (CR 716.2a's "activate only if this Class is level N-1"). Nothing is re-checked
-- here, which is CR 113.7a: once activated, an ability exists on the stack
-- independently of its source, so a level that moved in between changes nothing.
--
-- A player recipient, an illegal slot (CR 608.2b) and an id naming no object all
-- write nothing -- Designate's postures.
--
-- GameEvent.ClassLevelSet is what TriggerCondition.SelfBecomesClassLevel watches,
-- and it is emitted only on a TRANSITION -- the Designate arm above's posture.
-- CR 716.2a's ladder cannot set a level a Class already has, but this opcode is
-- not the ladder, and a CR 603.2 event for a change that did not happen would
-- fire "when this Class becomes level N" for a level it never became. The level
-- BEFORE is read through CR 716.2d's default, so a Class that has never been
-- levelled crosses from 1.
--
-- The WRITE is unguarded, unlike Designate's: writing the designation is not
-- idempotent where the level was absent, and CR 716.2b makes having one
-- observable (a copy reads CR 716.2d's default instead). So only the event turns
-- on the transition.
--
-- That guard is a REGRESSION FENCE rather than a proven behaviour: no card in
-- `data/cards/` carries Effect.SetClassLevel outside a level bar, and a bar
-- cannot set the level it already has, so removing it leaves the suite green.
-- It is kept because rule 603.2 states it, not because a test pays for it.
--
-- One writer, every road: this is the only place in the engine that CHANGES a
-- permanent's level. Everywhere else naming Object.classLevel builds a fresh
-- object at CR 400.7 with no level at all, so there is no second road to record
-- on.
setClassLevel :: Map.Map SlotName (Set Recipient) -> SetClassLevel.SetClassLevel -> Game ()
setClassLevel legal (SetClassLevel.MkSetClassLevel level slot) =
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure ()
      Just target -> do
        gs <- State.get
        State.modify'
          (\g -> g {GameState.objects = Map.adjust (\o -> o {Object.classLevel = Just level}) target (GameState.objects g)})
        case fmap (ClassLevel.MkClassLevel . ClassLevel.defaulted . Object.classLevel) (Game.lookupObject target gs) of
          Just before | before /= level -> State.modify' (Event.recordEvent (GameEvent.ClassLevelSet (ClassLevelChange.MkClassLevelChange target before level)))
          _ -> pure ()
    _ -> pure ()

-- CR 701.60a's other ending: undoes Designate's write for that one designation.
-- CR 701.60c's menace and can't-block are read off the set live, so nothing
-- else has to be undone. An illegal slot (CR 608.2b), a player recipient and a
-- set that matched nothing all arrive as the empty list.
unsuspectArm :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
unsuspectArm resolving source controller legal ref =
  State.modify' $ \gs ->
    let unsuspect o = o {Object.designations = Set.delete Designation.Suspected (Object.designations o)}
     in gs
          { GameState.objects =
              foldr (Map.adjust unsuspect) (GameState.objects gs) (objectRefObjects legal resolving controller source gs ref)
          }

-- CR 709.5f and CR 709.5g, one arm because the two rules are one sentence with
-- two words swapped: choose a half of the slot's permanent that the setting
-- admits, and give or take the appropriate unlocked designation.
--
-- The CANDIDATES come from Parun.Engine.Room's CR 709.5c derivation -- rule
-- 709.5g's "an unlocked half" for a lock, rule 709.5f's "a locked half" for an
-- unlock -- so the prompt cannot offer a half the instruction forbids, and the
-- answer is FILTERED back through them rather than trusted. Rule 709.5c's own
-- scope is why an object that is not a permanent with a shared type line on the
-- battlefield offers nothing.
--
-- No candidate leaves the instruction doing nothing, CR 101.3: a Room with
-- every door already shut cannot be locked further. A SINGLE candidate is not
-- asked about, both rules leaving nothing to choose.
--
-- A player recipient, an illegal slot (CR 608.2b) and an id naming no object
-- all write nothing -- Designate's postures.
--
-- Casing on `locked` and on `every` is not casing on an effect's identity: both
-- are payloads of one opcode, which is the argument Effect.Designate's own
-- haddock makes.
setHalfLocked :: PlayerId -> Map.Map SlotName (Set Recipient) -> SetHalfLocked.SetHalfLocked -> Game ()
setHalfLocked controller legal (SetHalfLocked.MkSetHalfLocked every locked slot) =
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure ()
      Just target -> do
        gs <- State.get
        let halves = fmap Face.name (if locked then Room.unlockedHalves target gs else Room.lockedHalves target gs)
        case halves of
          [] -> pure ()
          _ : _
            -- "each locked door", which names them rather than choosing among
            -- them, so CR 709.5f's "chooses" has nothing to ask and no prompt
            -- is raised. The unlock is ONE write for CR 709.5i's sake; the
            -- lock is a fold, rule 709.5g having no completion to record.
            | every ->
                if locked
                  then Monad.mapM_ (Event.lockHalf target) halves
                  else Event.unlockHalves controller target (Set.fromList halves)
            | otherwise -> do
                picked <- Game.chooseAmong (\decider who -> Prompt.ChooseHalf decider who target) controller halves
                Monad.forM_ picked $ \half ->
                  if locked then Event.lockHalf target half else Event.unlockHalves controller target (Set.singleton half)
    _ -> pure ()

-- CR 310.9f: the resolving controller becomes the slot's battle's protector,
-- the previous one ceasing to be. A state write on Object.protector, which CR
-- 310.9g keeps through a type change; CR 704.5y repairs a protector who can't
-- be one, and CR 506.4 takes the battle out of combat
-- (Parun.Engine.Combat.noteAttackingNothing). An illegal slot (CR 608.2b)
-- writes nothing.
becomeProtector :: PlayerId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
becomeProtector controller legal slot = case legalOne slot legal >>= Recipient.objectOf of
  Nothing -> pure ()
  Just battle -> State.modify' (\g -> g {GameState.objects = Map.adjust (\o -> o {Object.protector = Just controller}) battle (GameState.objects g)})

-- CR 702.100b and CR 702.149c: the slot's permanent evolves or trains only if
-- the placement put one or more counters on it, so a placement replaced away
-- (CR 614.16) or forbidden marks nothing. The event names that permanent, each
-- rule's "it". The scenario "CR 702.100b a placement Solemnity forbids is no
-- evolution" proves the gate.
counterAndMark :: PlayerId -> Map.Map SlotName (Set Recipient) -> PermanentActed.PermanentActed SlotName -> Game ()
counterAndMark controller legal (PermanentActed.MkPermanentActed action slot) = case legalOne slot legal >>= Recipient.objectOf of
  Nothing -> pure ()
  Just target -> do
    placed <- Event.putCounters (CounterCause.ByEffect controller) target CounterKind.PlusOnePlusOne 1
    Monad.when (placed > 0) (State.modify' (Event.recordEvent (GameEvent.PermanentActed (PermanentActed.MkPermanentActed action target))))

-- CR 702.134a's counter and CR 702.134c's marker: rule 702.134c fires on the
-- mentor ability RESOLVING, so the event is recorded however many counters CR
-- 614.16 left to place. The event names the resolving ability's SOURCE and the
-- slot's creature, in that order.
mentor :: ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
mentor source controller legal slot = case legalOne slot legal >>= Recipient.objectOf of
  Nothing -> pure ()
  Just target -> do
    _ <- Event.putCounters (CounterCause.ByEffect controller) target CounterKind.PlusOnePlusOne 1
    State.modify' (Event.recordEvent (GameEvent.Mentored (Mentored.MkMentored source target)))

-- CR 702.110a's sacrifice and CR 702.110b's marker. The creature is CHOSEN as
-- the effect is applied (CR 608.2d) rather than targeted (CR 115.1), so the
-- candidates are swept live off the battlefield and the ask follows
-- Parun.Types.Prompt.ChoosePermanent's posture: skipped at none, where CR 101.3
-- ignores the instruction, and at one, where CR 608.2d leaves one legal
-- announcement; asked at two or more. FILTERED, not trusted (#222).
--
-- Rule 702.110a's own "you may" is NOT asked here -- it is the clause's
-- Optionality.Optional, which Parun.Engine.Resolve has already answered by the
-- time this runs.
--
-- The marker is recorded on the sacrifice and names the pair rule 702.110b
-- does. Unconditional given a victim, Mentor's posture: a sacrifice is not a
-- destruction and CR 701.21a can refuse this one only for a permanent this
-- controller does not control, which the sweep's Filter.HeldBy Holder.Controller has just
-- excluded.
--
-- The sacrifice and the marker are ONE event (Event.simultaneously): rule
-- 702.110b makes the sacrifice the exploit, so CR 603.10a's look-back offers
-- an exploiter that sacrificed itself its own trigger.
exploit :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Game ()
exploit resolving source controller legal = do
  gs <- State.get
  let candidates =
        battlefieldMatching
          legal
          resolving
          controller
          source
          gs
          (Filter.Type.And [Filter.Type.HasCardType CardType.Creature, Filter.Type.HeldBy Holder.Controller PlayerRelation.You])
  victims <- Maybe.maybeToList <$> Game.chooseAmong (\decider who -> Prompt.ChoosePermanent decider who source) controller candidates
  Monad.forM_ victims $ \victim -> Event.simultaneously $ do
    Event.sacrifice controller victim
    State.modify' (Event.recordEvent (GameEvent.Exploited (Exploited.MkExploited source victim)))

-- CR 702.174c's marker, Firebend's reading of who gives it: `controller`
-- controls the resolving gift spell or gift triggered ability.
giveGift :: PlayerId -> Game ()
giveGift controller = State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.GiveGift controller)))

-- CR 731.1: the GAME gains the designation; what that entails is
-- Parun.Engine.Daytime's. Nobody is named and nothing is prompted.
itBecomes :: Daytime.Daytime -> Game ()
itBecomes designation = do
  _ <- Daytime.becomes Event.recordTransformed designation
  pure ()

-- CR 701.3a / 702.6a: the SOURCE moves, relocating it if it is already
-- attached elsewhere; AttachTarget below moves the slot's TARGET instead.
-- Event.attach is the one funnel CR 701.3's move goes through, holding rule
-- 701.3b, CR 701.3c's restamp and the GameEvent.BecameAttached.
--
-- CR 301.5c: a slot naming SEVERAL objects -- CR 614.16 having multiplied the
-- create that defined it, so living weapon's "it" stands for two Germs -- is a
-- spell or ability causing the Equipment to become attached to more than one
-- object, and the rule gives the choice to the Equipment's own controller.
-- Attach.arbitrate is that rule (CR 303.4d is its Aura twin). Ahead of the
-- target read for slotGroup's usual reason: a group binding is a definition,
-- never a target (CR 115.10a).
attach :: ObjectId -> ObjectId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
attach resolving source legal slot = do
  gs <- State.get
  case fmap Foldable.toList (slotGroup slot resolving gs) of
    Just group@(_ : _) -> do
      destination <- Attach.arbitrate source group
      Foldable.for_ destination (Event.attach source . Recipient.ToObject)
    _ -> Foldable.for_ (legalOne slot legal) (Event.attach source)

-- CR 702.6e: the same move with the slot's planeswalker treated as a creature
-- by CR 301.5's legality test. Rule 702.6e's minted ability is the writer, and
-- its slot is a target, so there is no group to arbitrate.
attachAsThoughCreature :: ObjectId -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
attachAsThoughCreature source legal slot = Foldable.for_ (legalOne slot legal) (Event.attachAsThoughCreature source)

-- CR 701.3a, the other direction: the SLOT's target moves, to a destination
-- chosen now rather than targeted.
attachTarget :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> AttachTarget.AttachTarget -> Game ()
attachTarget resolving source controller legal (AttachTarget.MkAttachTarget slot filter_) =
  case legalOne slot legal of
    -- An unfilled slot, or one CR 608.2b has since made illegal: no-op.
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure () -- a player recipient: nothing on the battlefield moves
      Just subject -> do
        gs <- State.get
        -- The destinations the card's own TEXT admits, narrowed to legal ones
        -- only when the card SAYS so (Filter.CanHostSubject); narrowing
        -- otherwise would answer CR 303.4j on the player's behalf. CR 609.3
        -- when Attach.hostsFor is empty. The elision at one candidate is
        -- Attach.chooseHost's, not re-derived for an optional attach.
        --
        -- Through effectContext and NOT Filter.contextFor, so this
        -- resolution's own reads answer here as they do at its other
        -- positions (CR 608.2c) -- Simic Guildmage's destination asks who
        -- controls the permanent its TARGET slot's Aura is attached to
        -- (Filter.SameControllerAsHostOfBound), which a bare context could
        -- not answer.
        destination <- Attach.chooseHost controller subject (Attach.hostsFor (effectContext gs resolving controller source legal (slotBindings resolving gs)) subject filter_ gs)
        -- Proposed as a bare ToObject; Event.attach re-tags it the way the
        -- subject's own enchant slot references it, and applies CR 303.4j's
        -- refusal. Always a different object than the current host, so CR
        -- 701.3c's restamp is always earned.
        Monad.mapM_ (Event.attach subject . Recipient.ToObject) destination
    _ -> pure ()

-- CR 303.4d / CR 301.5c: the same move, with the destination filter read as
-- "each" rather than "one of". The candidate list is built exactly as
-- AttachTarget builds it -- same filter, same Context, so CR 109.5's "you" on
-- the card's own text stays the ASKING ability's -- and only the arbitration
-- differs: Attach.arbitrate asks the SUBJECT's controller instead of the
-- resolving controller. Everything downstream is shared, so CR 303.4j's
-- refusal, CR 701.3b's no-op and CR 701.3c's restamp cannot diverge between
-- the two opcodes.
attachTargetToEach :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> AttachTarget.AttachTarget -> Game ()
attachTargetToEach resolving source controller legal (AttachTarget.MkAttachTarget slot filter_) =
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure ()
      Just subject -> do
        gs <- State.get
        destination <- Attach.arbitrate subject (Attach.hostsFor (effectContext gs resolving controller source legal (slotBindings resolving gs)) subject filter_ gs)
        Monad.mapM_ (Event.attach subject . Recipient.ToObject) destination
    _ -> pure ()

-- CR 701.3a's third arrangement, and the one the other two cannot spell: the
-- MOVER is whatever a binding names -- Sigarda's Aid's "it", CR 400.7e's
-- entrant under Binding.became -- and the DESTINATION is targeted rather than
-- found now. Nothing is chosen here, which is the observable difference from
-- AttachTarget above: the destination was fixed at CR 603.3d, so shroud
-- refused it then (CR 702.18a) and CR 608.2b has already dropped it from
-- `legal` if it went illegal, leaving this a no-op.
--
-- The mover is read through objectRefObjects rather than legalOne so that a
-- GROUP binding names every member (CR 712.21c's two cards, say); each is
-- attached to the one destination, which CR 301.5c permits since the limit it
-- states is on the Equipment and not on the creature.
attachBound :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> AttachBound.AttachBound -> Game ()
attachBound resolving source controller legal (AttachBound.MkAttachBound subject destination) =
  case legalOne destination legal of
    Just recipient -> do
      gs <- State.get
      Common.attachTogether (objectRefObjects legal resolving controller source gs (ObjectRef.InSlot subject)) recipient
    -- An unfilled slot, or one CR 608.2b has since made illegal: no-op.
    Nothing -> pure ()

-- CR 701.3a with the mover a GROUP and one destination chosen now: Glamer
-- Spinners' "attach all Auras enchanting target permanent to another
-- permanent with the same controller", Balan's "all Equipment you control".
--
-- The movers are gathered FIRST, since the destination's
-- Filter.CanHostSubject is asked of all of them (Attach.groupHostsFor). The
-- destination is the resolving controller's to choose (CR 608.2d), through
-- Prompt.ChoosePermanent's posture -- no one mover is THE subject a
-- Prompt.ChooseAttachment would name -- and asked even when nothing moves,
-- since the instruction still makes the choice. None admitted: nothing moves
-- (CR 609.3). A mover that cannot go there stays put (CR 701.3b, CR 303.4j),
-- which Event.attach applies. Only a destination within the controller's
-- range (CR 801.5a), every one for a planar source (CR 801.18): Fumble's
-- "another creature".
attachAll :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> AttachAll.AttachAll -> Game ()
attachAll resolving source controller legal chosen (AttachAll.MkAttachAll ref filter_) = do
  movers <- Common.askingObjects resolving source controller legal chosen ref
  gs <- State.get
  let grants = Projection.controlGrants gs
      inReach oid = all (\you -> Projection.objectInRangeGiven grants you oid gs) (Plane.rangePerspective source controller gs)
  destination <- Game.chooseAmong (\decider who -> Prompt.ChoosePermanent decider who source) controller (filter inReach (Attach.groupHostsFor (effectContext gs resolving controller source legal (slotBindings resolving gs)) movers filter_ gs))
  -- Proposed as a bare ToObject; Event.attach re-tags it per mover, as
  -- AttachTarget's arm says.
  Foldable.for_ destination (Common.attachTogether movers . Recipient.ToObject)

-- CR 701.3d: move each named permanent off its host, leaving it on the
-- battlefield, through Event.detach so each is a becomes-unattached event. The
-- movers are gathered ONCE (CR 608.2f), off the board before any moves, and in
-- one event group. CR 702.151b's creature-type removal on a reconfigure
-- Equipment ends with the attachment, Keyword.reconfigured's affected set
-- re-asking Object.attachedTo.
unattach :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
unattach resolving source controller legal chosen ref = do
  movers <- Common.askingObjects resolving source controller legal chosen ref
  Event.simultaneously (Monad.forM_ movers Event.detach)

exileHaunting :: ObjectId -> Map.Map SlotName (Set Recipient) -> ExileHaunting.ExileHaunting -> Game ()
exileHaunting resolving legal (ExileHaunting.MkExileHaunting card slot) =
  case legalOne slot legal of
    Just recipient -> case Recipient.objectOf recipient of
      Nothing -> pure ()
      Just haunted -> do
        -- The card is read LIVE off the resolving object, never out of
        -- `chosen`: rule 702.55a's "it" is the graveyard incarnation the death
        -- minted (CR 400.7e), and CR 115.10a makes it no target.
        --
        -- EVERY card the slot holds, group first: a merged or melded creature
        -- dies as several cards, and CR 730.3c / 712.21c take "the same
        -- actions ... upon each of them", so each is exiled haunting the one
        -- target (CR 702.55b's "cards"). Parun.MutateSpec's "CR 730.3c/702.55b
        -- a mutated creature with haunt exiles both cards haunting its target"
        -- proves it.
        cards <- Common.slotBoundObjects resolving Map.empty card
        Monad.forM_ (Maybe.fromMaybe [] cards) $ \oid -> do
          -- CR 400.7 mints the exiled incarnation; CR 702.55b's link is filed
          -- against THAT id, which puts the ability in exile for CR 113.6k. A
          -- cancelled move (CR 614.6) leaves no link.
          --
          -- The link names the object the ability TARGETED, so it goes on
          -- matching after that object has stopped being a creature, and is
          -- what TriggerCondition.HauntedCreatureDies compares against.
          mNew <- Event.changeZoneReturning oid Zone.Exile
          Monad.forM_ mNew $ \newId ->
            State.modify' (\g -> g {GameState.haunting = Map.insert newId haunted (GameState.haunting g)})
    _ -> pure ()
