-- applyOneEffect's arms from moveToZone to bid, one function per
-- Effect constructor, cut from Parun.Engine.Resolve.Effect along its order so the
-- arms compile in parallel. Each takes the recursion of Parun.Engine.Resolve.Effect
-- it calls back into, then the resolution parameters its body reads, then the
-- constructor's fields.
module Parun.Engine.Resolve.Arms.Zones where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import Data.Set (Set)
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Attach as Attach
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Condition as Condition
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Departure as Departure
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Expiry as Expiry
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Foretell as Foretell
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.MoveDuration as MoveDuration
import qualified Parun.Engine.Plane as Plane
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Players as Players
import qualified Parun.Engine.Plot as Plot
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Replacement as Replacement
import qualified Parun.Engine.Resolve.Common as Common
import Parun.Engine.Resolve.Slots (battlefieldMatching, boundSlots, effectContext, effectViewOf, handCardsOf, legalMany, legalOne, matchingFromAmong, objectRefObjects, playerRefPlayers, slotBindings)
import qualified Parun.Engine.Restamp as Restamp
import qualified Parun.Engine.Sticker as Sticker
import qualified Parun.Engine.Warp as Warp
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Ante as Ante
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.AnyNumberOf as AnyNumberOf
import qualified Parun.Types.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.Types.Ballot as Ballot
import qualified Parun.Types.BallotChoice as BallotChoice
import qualified Parun.Types.Bid as Bid
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CarryOver as CarryOver
import qualified Parun.Types.CastObligation as CastObligation
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.CastRepetition as CastRepetition
import qualified Parun.Types.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Types.Connive as Connive.Type
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.Departure as Departure.Type
import qualified Parun.Types.Discard as Discard
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.EachCardFromAmong as EachCardFromAmong
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntryBlock as EntryBlock
import qualified Parun.Types.EntryController as EntryController
import qualified Parun.Types.EntryHost as EntryHost
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.ExchangeCardZones as ExchangeCardZones
import qualified Parun.Types.ExchangeOwnership as ExchangeOwnership
import qualified Parun.Types.ExchangeSides as ExchangeSides
import qualified Parun.Types.ExchangeValues as ExchangeValues
import qualified Parun.Types.ExchangeZones as ExchangeZones
import qualified Parun.Types.ExchangedValue as ExchangedValue
import qualified Parun.Types.ExileLooker as ExileLooker
import qualified Parun.Types.ExilePlayPermission as ExilePlayPermission
import qualified Parun.Types.ExtraVotes as ExtraVotes
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.FaceDownState as FaceDownState
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.ForEachNumber as ForEachNumber
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameOutcome as GameOutcome
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantLookAtExiled as GrantLookAtExiled
import qualified Parun.Types.GrantPlayFromExile as GrantPlayFromExile
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LookAt as LookAt
import qualified Parun.Types.LoopMembers as LoopMembers
import qualified Parun.Types.MakeForetold as MakeForetold
import qualified Parun.Types.Mana as Mana.Type
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.MillTally as MillTally
import qualified Parun.Types.Milled as Milled
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ObjectRef (ObjectRef)
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.OfferCast as OfferCast
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayBudget as PlayBudget
import qualified Parun.Types.Player as Player
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerEffect as PlayerEffect.Type
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerInstruction as PlayerInstruction
import qualified Parun.Types.PlayerQuantity as PlayerQuantity
import Parun.Types.PlayerRef (PlayerRef)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerSacrifices as PlayerSacrifices
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.ProposedEvent as ProposedEvent
import qualified Parun.Types.PutSticker as PutSticker
import qualified Parun.Types.Quantity as Quantity.Type
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence
import Parun.Types.Recipient (Recipient)
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Repeat as Repeat
import qualified Parun.Types.RepeatIf as RepeatIf
import Parun.Types.Result (Result)
import qualified Parun.Types.ReturnWatch as ReturnWatch
import qualified Parun.Types.Reveal as Reveal
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.SetOwner as SetOwner
import qualified Parun.Types.ShuffleIntoLibrary as ShuffleIntoLibrary
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.SpeedDecrease as SpeedDecrease
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.Vote as Vote
import qualified Parun.Types.VoteChoices as VoteChoices
import qualified Parun.Types.VoteObjects as VoteObjects
import qualified Parun.Types.VotePlayers as VotePlayers
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZonePair as ZonePair

moveToZone :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> MoveToZone.MoveToZone (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
moveToZone resolving source controller legal chosen (MoveToZone.MkMoveToZone ref zone entry mSlot _ placement duration) =
  -- ONE object through CR 400.7's funnel, shared by the two arms below.
  let -- CR 400.7: the funnel mints a new incarnation in `zone`, owner-relative
      -- (CR 400.3). The riders (CR 110.5b), the library position (CR 401.2) and
      -- the controller (CR 110.2a) are handed to it rather than written
      -- afterward, so CR 614.1c's entry loop and the Moved snapshot read the
      -- settled values. No CR 800.4b guard: a departed player controls no
      -- resolving spell or ability (CR 800.4a, CR 800.4d). Answers the fold's
      -- state: the ids that have arrived so far, and the incarnations in
      -- reverse -- Nothing for a member that did not arrive.
      --
      -- CR 608.2f makes the whole sweep ONE event, so each member is judged
      -- against `before` -- the board the batch began on -- and against
      -- `sofar`, the members that have already arrived out of it. Threading a
      -- fold rather than a mapM is what carries those two: the funnel processes
      -- one member at a time, which is an implementation order CR 608.2f gives
      -- nobody the right to observe, and the two values are what keep it
      -- unobservable. `sofar` ACCUMULATES rather than naming every target up
      -- front because a member still in its old zone is not on the battlefield
      -- for a sweep to find anyway; only an arrived one needs excluding.
      --
      -- `sofar` is the half a test separates: Parun.AuraSpec's returned Aura and
      -- Parun.CopySpec's reanimated Clone both fail without it. `before` is
      -- threaded because CR 614.4 asks which effects existed before the BATCH,
      -- but nothing in data/cards separates it from Nothing. Every
      -- ReplacementEffect.ZoneChangeR there names a `whenDestination` of
      -- Graveyard or Stack (rest-in-peace, leyline-of-the-void,
      -- anafenza-the-foremost, yawgmoths-will, nexus-of-fate,
      -- dire-fleet-daredevil, synthetic-stack-interdiction),
      -- which no member of a batch moving ONTO THE BATTLEFIELD goes to, or the
      -- Battlefield under a Filter.IsInZone Stack conjunct
      -- (synthetic-entry-interdiction), which no batch member arriving from a
      -- graveyard or a hand satisfies.
      -- The engine installs one row naming NO destination -- CR 702.34a's
      -- exile, Parun.Engine.Keyword.castFromGraveyardExile -- which admits the
      -- battlefield too. It separates nothing either: the three rules that
      -- install it arm it onto an INSTANT OR SORCERY spell alone (CR 702.34a
      -- and CR 702.133a say so outright; CR 702.127a's aftermath is printed on
      -- a split card's instant and sorcery halves), and no such spell is a
      -- member of a batch entering the battlefield. A card whose ZoneChangeR
      -- watched the battlefield and could match a member of such a batch would
      -- separate them.
      moveOne mover mAttack mBlocked frozen before (sofar, acc) (target, (position, above)) = do
        hosted <- chosenHost mover frozen sofar target
        mNew <- case hosted of
          -- CR 303.4g: nothing it may enchant, so the Aura stays where it is.
          Nothing -> pure Seq.empty
          Just seed -> Event.changeZoneEnteringIn (Just before) sofar seed source target zone position frozen (Just mover)
        -- CR 614.6: the move was cancelled, or the id was already gone (CR
        -- 603.7c). Nothing entered, so there is nothing to bind.
        Monad.forM_ mNew $ \newId -> do
          -- CR 401.7: LibraryPlacement.Beneath's depth, where the arrival
          -- landed in a library (CR 400.3's owner's); Game.sinkInLibrary's
          -- clamp is the rule's "fewer than N cards".
          Monad.when (above > 0) $ do
            landedIn <- State.gets (Game.lookupObject newId)
            Monad.forM_ landedIn $ \obj ->
              Monad.when (Object.zone obj == Zone.Library) $
                State.modify' (Game.sinkInLibrary (Natural.toIntSaturating above) (Object.owner obj) newId)
          -- CR 508.4, via Parun.Engine.Combat -- which is also what keeps this
          -- from looking like a declaration, so CR 508.3a's attack triggers see
          -- nothing. CR 506.3b refuses a controller who is not the active
          -- player, which the funnel above has already settled. What it
          -- attacks was read ONCE ahead of this fold (see mAttack below).
          Monad.forM_ mAttack (\specified -> Combat.putOntoBattlefieldAttacking specified newId)
          -- CR 509.4, the blocking twin one rule over, through the same
          -- Parun.Engine.Combat function the Create arm hands its tokens to, so
          -- CR 506.3e and CR 509.4a's two no-op conditions are decided in one
          -- place whichever opcode put the creature there. The attacker was
          -- read ONCE ahead of this fold (see mBlocked below), so CR 608.2f's
          -- single event cannot see it move between members.
          Monad.forM_ mBlocked (\blocked -> Combat.putOntoBattlefieldBlocking blocked newId)
          -- CR 610.3: a move with a duration is only half of a pair, so the
          -- incarnation that arrived is registered against the event that ends
          -- it (Parun.Engine.MoveDuration.endingOf), and against the zone it came
          -- from (rule 610.3's "its previous zone"). Parun.Engine.MoveDuration is
          -- where the second one-shot effect that reads this happens; nothing a
          -- card prints performs it. Per ARRIVAL, which is CR 712.21c: a melded
          -- permanent leaves as two cards and both come back.
          let watched = do
                lasting <- duration
                from <- fmap Object.zone (Game.lookupObject target before)
                pure (ReturnWatch.MkReturnWatch {ReturnWatch.ending = MoveDuration.endingOf lasting source controller, ReturnWatch.zone = from})
          Monad.forM_ watched $ \watch ->
            State.modify' (\g -> g {GameState.movedUntil = Map.insert newId watch (GameState.movedUntil g)})
          -- CR 400.7: which object's effect put this permanent onto the
          -- battlefield, for Filter.EnteredWithSource. Read off where the
          -- incarnation landed, so a redirected move records nothing.
          landed <- State.gets (fmap Object.zone . Game.lookupObject newId)
          Monad.when (landed == Just Zone.Battlefield) $ do
            State.modify' (\g -> g {GameState.enteredWith = Map.insert newId source (GameState.enteredWith g)})
            State.modify' (Common.linkCraftMaterials resolving newId)
        pure (foldr Set.insert sofar mNew, mNew : acc)
      -- CR 303.4f's choice for an Aura the effect puts onto the battlefield
      -- "attached to" a host it describes (EntryHost.Chosen, Nomad
      -- Mythmaker's "a creature you control"): the rule's "any other
      -- applicable effects", so the offer is the Aura's own entryHostsFor
      -- narrowed by the effect's filter, made by the player it enters under.
      -- Asked here rather than inside the funnel because the filter is card
      -- text read in this resolution's context; a replacement that sends the
      -- card elsewhere discards the answer unused. Answers the
      -- funnel's seed, Nothing for CR 303.4g's "remains in its current zone",
      -- and Just Nothing for every move the rider does not narrow, which the
      -- funnel seats itself. MINUS `sofar`, the funnel's own CR 608.2f exclusion.
      -- Players are never admitted: the filter describes objects.
      --
      -- CR 303.4i's EntryHost.Specified narrows the same offer to the objects
      -- the slot names instead (Necrotic Plague's "attached to that
      -- creature"), so a named host the Aura could not enchant leaves it where
      -- it is rather than letting its controller pick another.
      chosenHost mover riders sofar target = do
        now <- State.get
        let narrowed admits
              | zone == Zone.Battlefield,
                Maybe.isNothing (EntryRiders.faceDown riders),
                Set.member Subtype.Aura (Projection.subtypesOf target now) = do
                  let offered = Attach.entryHostsFor mover target now
                  admitted <- admits (filter (`Set.notMember` sofar) (Maybe.mapMaybe Recipient.objectOf offered))
                  let hosts = filter (maybe False (`Set.member` admitted) . Recipient.objectOf) offered
                  chosenOne <- Attach.chooseEntryHost mover target hosts
                  pure (fmap Just (chosenOne >>= \h -> Attach.entryAttachmentFor mover target h now))
              | otherwise = pure (Just Nothing)
        case EntryRiders.attachedTo riders of
          Just (EntryHost.Chosen filter_) -> narrowed (pure . Set.fromList . matchingFromAmong legal resolving controller source now filter_)
          Just (EntryHost.Specified slot) -> narrowed (\candidates -> fmap (Set.intersection (Set.fromList candidates) . Set.fromList) (Common.fromAmongMembers legal resolving chosen slot))
          Nothing -> pure (Just Nothing)
      -- The context a CHOICE's candidates are filtered in, off the board the
      -- choice is being made on: the resolution's own slots ride along, so a
      -- card offering "a permanent card from among them" (Midnight Tilling)
      -- offers only what an earlier clause of this resolution named.
      chooseContext g = effectContext g resolving controller source legal (slotBindings resolving g)
   in do
        -- CR 610.3b: the specified event has already happened since this
        -- ability triggered, so the object doesn't move. CR 610.3a says the
        -- same of a spell or activated ability put onto the stack, and one
        -- test answers both -- for a source leaving the battlefield, CR 400.7
        -- makes the source one incarnation, so "has it left" is the same
        -- question whichever rule asks it. Glorious Protector's ruling is the
        -- printed statement of it: if it leaves the battlefield before its
        -- triggered ability resolves, no creatures are exiled.
        --
        -- Ahead of the GATHER, so the CR 608.2d choice is not put to anybody
        -- either: with nothing able to move, that question has no board behind
        -- it.
        declined <- State.gets (\gs -> any (\lasting -> MoveDuration.hasHappened lasting resolving source controller gs) duration)
        Monad.unless declined $ do
          -- WHICH objects move, gathered first and moved second, so the CR 401.2
          -- and CR 401.4 questions between the two steps are asked of the whole
          -- batch.
          let gather r = case r of
                -- NOT routed through objectRefObjects: that function reads `slotGroup`
                -- then `chosen`, never `slotOne`, and slotOne is what lets a slot an
                -- EARLIER EFFECT OF THIS SAME RESOLUTION bound name its object here.
                -- A declared target is read out of `chosen` behind CR 608.2b's
                -- re-validation; a slot `chosen` does not mention was never targeted
                -- and is read live. Membership rather than preference keeps a target
                -- from losing its re-validation to a binding sharing its name.
                -- A slot bound to a GROUP names every member, a slot bound to one
                -- names that one, and a TARGETED slot names EVERY still-legal
                -- recipient -- not one, which is the SlotArity.Many objectRefSlots
                -- declares; legalOne declines a slot naming several. An empty list is
                -- an unbound slot, every target gone illegal, or CR 115.6's zero
                -- targets chosen. fromAmongMembers is where those three and their
                -- rules live, shared with the two "from among them" refs so they
                -- cannot read the slot differently.
                ObjectRef.InSlot slot -> Common.fromAmongMembers legal resolving chosen slot
                -- Mulch's "all land cards revealed this way", the arm above's plural.
                -- NOT routed through objectRefObjects, for the InSlot arm's reason:
                -- the members come off slotBoundObjects, which reads the single
                -- binding an earlier effect of this resolution left as well as the
                -- group. The same read chooseCardFromAmong makes, off the pre-move
                -- state (CR 608.2c), so the matched half and "the rest" -- a LATER
                -- clause naming the same slot with InSlot, which finds these cards
                -- gone (CR 400.7) -- cannot see different groups. A looked-at card
                -- put back into the library it is in is gone too, a new object by
                -- CR 701.20d (Event.forgetShown).
                ObjectRef.EachCardFromAmong (EachCardFromAmong.MkEachCardFromAmong slot filter_) -> do
                  members <- Common.fromAmongMembers legal resolving chosen slot
                  gs <- State.get
                  pure (matchingFromAmong legal resolving controller source gs filter_ members)
                -- Each ref gathered in the order written, before anything
                -- moves, so the members move as ONE batch (CR 608.2f); an
                -- object two refs name moves once.
                ObjectRef.AllOf refs -> fmap (ListUtils.nubOrd . concat) (traverse gather (NonEmpty.toList refs))
                -- Every other ref is swept or asked ONCE off the PRE-MOVE state (CR
                -- 608.2c, CR 608.2f) through askingObjects, then moved one at a time,
                -- each judged against the board the batch began on and against the
                -- siblings that have already arrived (see moveOne). CR 400.3 files a
                -- hand arrival under Object.owner, and CR 110.2a hands a battlefield
                -- arrival to the player the effect instructed. A ref naming players
                -- names no object. askingObjects' match is exhaustive, so a new arm
                -- is classified there; only a slot read needing fromAmongMembers'
                -- single binding, as the two arms above do, belongs here.
                _ -> Common.askingObjects resolving source controller legal chosen r
          targets <- gather ref
          -- CR 608.2h: a depth's amount is read once, off the pre-move board.
          depthBoard <- State.get
          let depthOf quantity =
                maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor (effectViewOf source legal depthBoard) (chooseContext depthBoard) depthBoard resolving source quantity)
          arrivals <- Common.settleArrivals (Common.askedChooser resolving source controller legal) depthOf zone placement targets
          -- The batch's own board, read after CR 401.4's arrangement asks (which
          -- move nothing) and before any member does.
          before <- State.get
          -- CR 701.40e's own three conditions, read off that same board; the
          -- `arrived` bind below is where the rule is applied and where the case
          -- for reading a rider here is written out.
          let manifested = fmap FaceDownState.reason (EntryRiders.faceDown entry) == Just FaceDownReason.Manifested
              fromOwnLibrary target = case Game.lookupObject target before of
                Just obj -> Object.zone obj == Zone.Library && Object.owner obj == controller
                Nothing -> False
              oneAtATime =
                zone == Zone.Battlefield
                  && manifested
                  && length arrivals > 1
                  && all (fromOwnLibrary . fst) arrivals
          -- CR 608.2h: the counts the riders carry, settled ONCE off that same
          -- board and before the fold, so no member of the batch can see how many
          -- counters an earlier member arrived with (CR 608.2f).
          let frozen = Common.freezeRiders (effectViewOf source legal before) (chooseContext before) before resolving source entry
          -- CR 509.4's parenthetical: the attacking creature the effect
          -- SPECIFIED, named by slot. Read ONCE, ahead of the fold and off the
          -- same pre-move board the riders' counts were settled on, so CR 608.2f's
          -- single event cannot see it move; through fromAmongMembers, the reader
          -- every "the object this slot names" site shares, so a targeted slot
          -- and one a trigger bound (Aetherplasm's "that creature") read the same
          -- way.
          --
          -- Exactly one object or nothing: CR 509.4 names ONE attacking creature,
          -- and no printing names several. Nothing here is Combat's own no-op
          -- case anyway.
          mBlocked <- case EntryRiders.blocking entry of
            Nothing -> pure Nothing
            -- CR 509.4's main clause: Combat asks the controller.
            Just EntryBlock.Chosen -> pure (Just Combat.AnyAttacker)
            Just (EntryBlock.Specified slot) -> do
              named <- Common.fromAmongMembers legal resolving chosen slot
              pure $ case named of
                [attacker] -> Just (Combat.SpecifiedAttacker attacker)
                _ -> Nothing
          -- CR 508.4's rider, read ONCE off the same pre-move board for
          -- mBlocked's reason.
          let mAttack = Common.entryAttack legal resolving entry before
              -- CR 110.2a: the player the effect instructs to put the objects
              -- there, and so who they enter under -- the resolving controller
              -- unless the rider names another (Endless Whispers' "that
              -- player", Thieves' Auction's loop member). Read once, off the
              -- pre-move board. A reference naming no one player instructs
              -- nobody, so nothing moves (CR 101.3). EntryController.Owner hands
              -- every member to its owner in the funnel instead.
              instructed = case EntryRiders.under entry of
                EntryController.Instructed who -> Common.oneSeat legal resolving source controller before who
                EntryController.Owner -> Just controller
          -- ONE event, which is what Event.simultaneously stamps on everything the
          -- fold records: CR 608.2f processes an action taken on multiple objects
          -- simultaneously, and one opcode is one such action however many objects
          -- the ref swept. The fold's own comments already rest on that sentence --
          -- `before` and the frozen riders are there because no member may observe
          -- another -- so the bracket adds no claim they do not, and CR 603.2c's
          -- batch conditions are what a board can finally read it with.
          --
          -- The per-member CR 616.1 loop inside Event.changeZoneEnteringIn is no
          -- argument for N groups: Event.destroyIn runs exactly such a loop inside
          -- one bracket, and Parun.Engine.Sba's CR 704.3 pass nests deeper still.
          -- CR 616.1g is where the rules say events nest at all -- a replacement
          -- may apply to "an event contained within the first event" -- so a
          -- replacement opportunity per member is not a second event.
          --
          -- Around the FOLD alone. The gathers above ask CR 608.2d choices and CR
          -- 401.4 arrangements, which move nothing and record nothing; a bracket
          -- reaching over them would only widen what the group means.
          --
          -- CR 701.40e is the one exception the rules write to that reading: "if
          -- an effect instructs a player to manifest multiple cards from their
          -- library, those cards are manifested one at a time." Then the opcode
          -- is not one action taken on several objects but several actions, so
          -- each card gets its own event -- its own board, its own frozen riders,
          -- and no sibling to exclude, which is what lets the second card's CR
          -- 614.12 determination count the first one (Parun.FaceDownSpec's
          -- Ethereal Ambush under Synthetic Encircling Net).
          --
          -- The gate reads the RIDER (CR 708.2's manifest reason), the
          -- destination and where the cards are, never the effect's identity:
          -- CR 701.40's keyword action is what a face-down battlefield arrival
          -- out of a library IS. Both of the rule's own restrictions are in it --
          -- MULTIPLE, so a single card takes the ordinary path, and THEIR
          -- LIBRARY, which CR 108.3 makes the owner's, so a manifest out of
          -- another player's library or out of exile (Ghastly Conscription) stays
          -- one event.
          arrived <- case instructed of
            Nothing -> pure []
            Just mover
              | oneAtATime -> fmap concat . Monad.forM arrivals $ \arrival -> do
                  now <- State.get
                  let riders = Common.freezeRiders (effectViewOf source legal now) (chooseContext now) now resolving source entry
                  fmap (reverse . snd) (Event.simultaneously (moveOne mover mAttack mBlocked riders now (Set.empty, []) arrival))
              | otherwise -> do
                  batch <- fmap (reverse . snd) (Event.simultaneously (Event.amongPending (if EntryRiders.under frozen == EntryController.Owner then Nothing else Just mover) (fmap fst arrivals) (Monad.foldM (moveOne mover mAttack mBlocked frozen before) (Set.empty, []) arrivals)))
                  -- CR 613.7m: the members that entered the battlefield together
                  -- take their stamps in APNAP order, each seat choosing its own.
                  -- Not on the one-at-a-time road above, whose cards enter at
                  -- separate moments.
                  Restamp.settle (GameState.nextTimestamp before) (concatMap Foldable.toList batch)
                  pure batch
          -- CR 400.7j: what arrived, for a later effect of this resolution or a
          -- delayed ability it arms (CR 603.7c).
          Common.bindObjects resolving mSlot (concatMap Foldable.toList arrived)

-- CR 701.12d / 701.12f: every named player's two zones swap their cards, an
-- empty zone included. Both zones are the player's own (CR 400.3), so every
-- card is owned by that player, which is CR 701.12d's condition. One CR
-- 608.2f event over every card, each direction read off the same pre-move
-- board, so a card that just arrived is never sent back; each card is a CR
-- 400.7 move with its own CR 616.1 opportunity. There is no CR 701.12e
-- hand-off to make: what is attached is an Aura, Equipment or Fortification
-- permanent (CR 701.3a), and none of these zones holds a permanent.
--
-- Cards entering a library go to its default end in the order read, which is
-- no player's choice to take: every printing shuffles that library at once
-- (Scryfall o:"exchange your" -o:"life total" -o:control, 2026-09-26: Harness
-- Infinity, Morality Shift, Mordenkainen). An exchange into a library with no
-- shuffle would refute this.
exchangeZones :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ExchangeZones.ExchangeZones -> Game ()
exchangeZones resolving source controller legal (ExchangeZones.MkExchangeZones player pair) = do
  before <- State.get
  let (one, other) = ZonePair.zones pair
      named = playerRefPlayers legal resolving source controller before player
      exchanging = filter (`elem` named) (Game.apnapOrder before)
      moves =
        concatMap
          (\pid -> fmap (\oid -> (oid, other)) (Game.zoneMembers one pid before) <> fmap (\oid -> (oid, one)) (Game.zoneMembers other pid before))
          exchanging
  Monad.void (Event.changeZonesTogether moves)

-- CR 701.12d: the one card each ref names exchange zones, each going where
-- the other was. `other` is asked only once `one` has named a card
-- `exchangeable` admits, so a source that has left (CR 400.7) or phased out
-- (CR 702.26b) asks nobody. The aura swap's
-- hand card is chosen from every card the filter admits, not only those that
-- could enchant the host: an unattachable pick is a legal choice whose result
-- is nothing (Arcanum Wings ruling, 2007-05-01, and CR 702.65b).
--
-- Whether BOTH halves can happen is decided before either does (CR 701.12a):
-- two distinct cards in different zones, one owner for both (CR 701.12d), and
-- a card entering the battlefield can be attached as below. A side naming no
-- card, as an empty library's top card, exchanges nothing: CR 701.12d's "even
-- if one zone is empty" is Effect.ExchangeZones', which trades a zone's whole
-- contents (data/scenarios/ante/ante-darkpact-empty-library-takes-the-card-but-exchanges-nothing.json).
-- Then one CR 608.2f
-- event: each card to the other's zone, filed under its owner (CR 400.3), a
-- permanent under the resolving controller (CR 110.2a), and a library card at
-- the end the other left.
--
-- A card entering in place of an attached permanent enters attached to that
-- permanent's host (CR 701.12e), so CR 303.4f asks nobody, and one that cannot
-- legally be (CR 303.4i, through attachmentFor) stops both halves. An Aura card
-- entering in place of an UNATTACHED permanent -- one a text change made a
-- non-Aura (CR 612.1 reaches the type line, and CR 704.5p then detaches it) --
-- is CR 303.4f's, its host chosen here rather than by the funnel so that CR
-- 303.4g's "remains in its current zone" stops the other half too, and never
-- the leaving permanent itself. Parun.AuraSpec's AuraSwap group and
-- data/scenarios/ante/ante-darkpact-takes-an-opponents-ante-card.json are the
-- proof; the no-host and self-host halves are fences, every Aura card those
-- boards offer having a host other than the source. Either way the entering
-- card is judged as the resolving controller's (Attach.entryAttachmentFor),
-- a fence too: AuraSwap's Aura card comes from its controller's own hand.
--
-- Not implemented: a library card from neither end of its library, which
-- LibraryPosition cannot name, sends the other card to the bottom (#4974).
exchangeCardZones :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ExchangeCardZones.ExchangeCardZones -> Game ()
exchangeCardZones resolving source controller legal chosen (ExchangeCardZones.MkExchangeCardZones one other) = do
  ones <- Common.askingObjects resolving source controller legal chosen one
  current <- State.get
  case ListUtils.nubOrd ones of
    [a] | Common.exchangeable a current -> do
      others <- Common.askingObjects resolving source controller legal chosen other
      before <- State.get
      let -- What `card` enters with in place of `left`: Nothing when it
          -- cannot enter, else its attachment seed.
          entering card left = case Game.lookupObject left before of
            Just obj
              | Object.zone obj == Zone.Battlefield -> case Object.attachedTo obj of
                  Just host -> pure (fmap Just (Attach.entryAttachmentFor controller card host before))
                  Nothing
                    | Set.member Subtype.Aura (Projection.subtypesOf card before) -> do
                        let hosts = filter ((/= Just left) . Recipient.objectOf) (Attach.entryHostsFor controller card before)
                        entryHost <- Attach.chooseEntryHost controller card hosts
                        pure (fmap Just (entryHost >>= \h -> Attach.entryAttachmentFor controller card h before))
                    | otherwise -> pure (Just Nothing)
            _ -> pure (Just Nothing)
          zoneOf oid = fmap Object.zone (Game.lookupObject oid before)
          atTop oid = case Game.pileHolderOf oid before of
            Just pid -> take 1 (Game.zoneMembers Zone.Library pid before) == [oid]
            Nothing -> False
          move card left to seed =
            Event.changeZoneAttaching (Just before) Set.empty card to (if atTop left then LibraryPosition.Top else LibraryPosition.Bottom) seed TapState.Untapped Map.empty (if to == Zone.Battlefield then Just controller else Nothing) Nothing Facing.FaceUp False CarryOver.NotCarried False Seq.empty
          ownerOf oid = fmap Object.owner (Game.lookupObject oid before)
      case ListUtils.nubOrd others of
        [b]
          | a /= b,
            Common.exchangeable b before,
            Just zoneA <- zoneOf a,
            Just zoneB <- zoneOf b,
            zoneA /= zoneB,
            ownerOf a == ownerOf b -> do
              seeds <- (,) <$> entering a b <*> entering b a
              case seeds of
                (Just seedA, Just seedB) -> Event.simultaneously (move a b zoneB seedA >> Monad.void (move b a zoneA seedB))
                _ -> pure ()
        _ -> pure ()
    _ -> pure ()

-- CR 701.24: shuffle the objects the refs name into their OWNERS' libraries. Two
-- steps: CR 400.7's move through the same changeZone funnel every destination
-- uses, so a library-entry replacement gets its CR 616.1 opportunity (CR 400.3
-- files the arrival under Object.owner), then CR 701.24a's randomisation.
--
-- The owners are read before either, because the shuffle runs whether or not the
-- move did (CR 701.24c): a cancelled move leaves no incarnation and no owner, and
-- the effect's own PlayerRef is what covers that and CR 701.24d's empty set. The
-- UNION of the two, since rule 701.24's objects go to their owners' libraries and
-- the named player need not be one of them. Each library is shuffled ONCE (CR
-- 608.2f), and CR 701.24a makes WHO shuffles unobservable.
--
-- Every ref's objects move as ONE event (CR 608.2f / 603.2c), so Timetwister's
-- hand and graveyard are one arrival and one shuffle -- proved by
-- Parun.MassEffectSpec's Timetwister group.
--
-- The slot binds the library incarnations (CR 400.7), for a later count:
-- Winds of Change's "draws that many", each player's own -- proved by
-- Parun.MassEffectSpec's Winds of Change group.
shuffleIntoLibrary :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ShuffleIntoLibrary.ShuffleIntoLibrary -> Game ()
shuffleIntoLibrary resolving source controller legal (ShuffleIntoLibrary.MkShuffleIntoLibrary named refs mSlot) = do
  gs <- State.get
  let targets = ListUtils.nubOrd (foldMap (objectRefObjects legal resolving controller source gs) refs)
      -- The owners are read from the PRE-MOVE objects (CR 701.24c); an id that
      -- no longer resolves contributes no owner.
      owners =
        Set.fromList (Maybe.mapMaybe (\target -> fmap Object.owner (Game.lookupObject target gs)) targets)
          <> Set.fromList (foldMap (playerRefPlayers legal resolving source controller gs) named)
  arrivals <- Event.changeZonesTogether (fmap (\target -> (target, Zone.Library)) targets)
  Common.bindObjects resolving mSlot (concatMap Foldable.toList arrivals)
  -- APNAP (CR 608.2f), which is what makes the ORDER of the Prompt.Shuffle calls
  -- a fact about the rules rather than about PlayerId's Ord.
  Monad.forM_ (filter (`Set.member` owners) (Game.apnapOrder gs)) Event.shuffleLibrary

-- CR 108.3 / 407.3: the one named player becomes the owner of each named
-- object -- Darkpact's "You own target card in the ante". No zone change and
-- no event; a ref naming no one player writes nothing.
setOwner :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SetOwner.SetOwner -> Game ()
setOwner resolving source controller legal (SetOwner.MkSetOwner player ref) = do
  gs <- State.get
  let named = ListUtils.nubOrd (objectRefObjects legal resolving controller source gs ref)
  case playerRefPlayers legal resolving source controller gs player of
    [owner] -> State.put (List.foldl' (\g oid -> Game.setOwner oid owner g) gs named)
    _ -> pure ()

-- CR 701.12a / 108.3: the one object each ref names trade owners. All or
-- nothing: a ref naming no object or several, or both naming the same one,
-- exchanges nothing. Two Game.setOwner writes on the objects as they stand,
-- no zone change; one owner on both sides changes nothing.
exchangeOwnership :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ExchangeOwnership.ExchangeOwnership -> Game ()
exchangeOwnership resolving source controller legal (ExchangeOwnership.MkExchangeOwnership one other) = do
  gs <- State.get
  let named ref = ListUtils.nubOrd (objectRefObjects legal resolving controller source gs ref)
      ownerOf oid = fmap Object.owner (Game.lookupObject oid gs)
  case (named one, named other) of
    ([a], [b])
      | a /= b,
        Just ownerA <- ownerOf a,
        Just ownerB <- ownerOf b ->
          State.put (Game.setOwner b ownerA (Game.setOwner a ownerB gs))
    _ -> pure ()

-- CR 407.4: "the owner of an object is the only player who can ante that
-- object". Each named object one of the named players owns moves to the
-- ante, all of them as one event (CR 608.2f); any other is left where it is,
-- and a move that names nobody writes nothing, so CR 608.2c's "If you do"
-- reads it as not having happened. The pure sweep, the read effectIsImpossible's
-- Ante arm makes, so the offer and the instruction name the same objects.
ante :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Ante.Ante -> Game ()
ante resolving source controller legal (Ante.MkAnte player ref mSlot) = do
  gs <- State.get
  let named = objectRefObjects legal resolving controller source gs ref
  let anteing = playerRefPlayers legal resolving source controller gs player
      theirs oid = case Game.lookupObject oid gs of
        Just obj -> List.elem (Object.owner obj) anteing
        Nothing -> False
      targets = filter theirs (ListUtils.nubOrd named)
  Monad.unless (null targets) $ do
    arrivals <- Event.changeZonesTogether (fmap (\target -> (target, Zone.Ante)) targets)
    Common.bindObjects resolving mSlot (concatMap Foldable.toList arrivals)

-- CR 123.3: each placer puts a sticker of an allowed kind on each named
-- object, through Sticker.place, which holds CR 123.3b's owner gate, CR
-- 123.6b's position and CR 123.3c's payment. Placing nothing writes nothing,
-- so happenedBetween reads it as not having happened.
putSticker :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> PutSticker.PutSticker -> Game ()
putSticker resolving source controller legal chosen (PutSticker.MkPutSticker player ref kinds cap free bound) = do
  named <- Common.askingObjects resolving source controller legal chosen ref
  placers <- State.gets (\gs -> playerRefPlayers legal resolving source controller gs player)
  Monad.forM_ placers $ \placer -> Monad.forM_ (ListUtils.nubOrd named) $ \oid -> do
    gs <- State.get
    picked <- Sticker.place False placer oid kinds (Common.ticketCapOf resolving source controller legal gs cap) free
    Monad.forM_ picked (\placed -> Monad.forM_ bound (\slot -> State.modify' (Common.bindStickerSlot resolving slot placed)))

-- CR 701.24a alone: randomize the named libraries so no player knows their
-- order. Nothing moves, so there is no changeZone call and no CR 616.1
-- opportunity -- the cards a "then shuffle" follows are still the objects they
-- were, with the ids they had, but for a revealed or looked-at one (CR
-- 701.20d, Event.shuffleLibrary).
--
-- APNAP (CR 608.2f) and once per library, the arm above's two reasons: a
-- PlayerRef naming a player twice still shuffles their library once, and the
-- ORDER of the Prompt.Shuffle calls is a fact about the rules rather than about
-- PlayerId's Ord.
shuffle :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game ()
shuffle resolving source controller legal ref = do
  gs <- State.get
  let named = Set.fromList (playerRefPlayers legal resolving source controller gs ref)
  Monad.forM_ (filter (`Set.member` named) (Game.apnapOrder gs)) Event.shuffleLibrary

offerCastArm :: (Game Result -> Filter.Context -> (Quantity.Type.Quantity -> Maybe Integer) -> [ObjectId] -> PlayerId -> CastObligation.CastObligation -> PermissionVerb.PermissionVerb -> Maybe PlayerId -> CastRepetition.CastRepetition -> Bool -> CastOffer.CastOffer -> Game [ObjectId]) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> OfferCast.OfferCast -> Game ()
offerCastArm offerCast runSubgame resolving source controller legal chosen (OfferCast.MkOfferCast ref caster optionality verb offer repetition copied controlWhileResolving slot) = do
  -- Named HERE rather than inside offerCast so that one function takes the
  -- objects and never the reference: CR 601.3's offer over a set (Shell of the
  -- Last Kappa) and over one target (Tinybones, the Pickpocket) are then the
  -- same call. Asked, since CR 608.2d's choice may name the card: Word of
  -- Command's "choose a card from it" out of the hand its look bound.
  named <- Common.askingObjects resolving source controller legal chosen ref
  gs <- State.get
  let -- The SAME context the reference above was gathered through, so an offer
      -- whose restriction reads the source (CR 702.85a) answers what the walk
      -- that named these cards answered.
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      evaluate = Quantity.evaluateFor (effectViewOf source legal gs) context gs resolving source
      -- CastOffer.payableFromSpent: only a card whose mana cost the mana spent
      -- on this ability's {X} could pay stays on offer. That mana is
      -- Object.manaSpent less what paid the rest of the total
      -- (Object.manaCostPaid, Mana.xShares), so a cost increase's mana is not
      -- counted; any share the payment leaves open will do. The CARD's mana
      -- cost, which in a hand is Card.combined's (CR 709.4, 712.8a, 715.4).
      ability = Game.lookupObject resolving gs
      spent = maybe (Mana.Type.MkMana []) Object.manaSpent ability
      shares = case (ability >>= Object.manaCostPaid, ability >>= Binding.amountOf Binding.variableX . Object.bindings) of
        (Just paid, Just x) -> Mana.xShares x paid spent
        _ -> [spent]
      affordable oid = not (CastOffer.payableFromSpent offer) || maybe False (\card -> any (`Mana.couldPayFrom` Face.manaCost (Card.combined card)) shares) (Game.cardOf oid gs)
  -- CR 608.2g names "a player", and a reference resolving to nobody offers the
  -- cast to nobody.
  spells <-
    concat
      <$> Monad.forM
        (playerRefPlayers legal resolving source controller gs caster)
        ( \pid ->
            offerCast runSubgame context evaluate (filter affordable named) pid optionality verb (if controlWhileResolving then Just controller else Nothing) repetition copied offer
        )
  -- CR 400.7h: the rest of the effect names the spells, bindObjects's shape.
  Common.bindObjects resolving slot spells

-- CR 707.13 (Garth One-Eye): choose one of the listed names not yet chosen for
-- this source, look the card up (CR 108.1), create a copy of it outside the
-- game, and offer its controller the cast. The names are card data; nothing
-- here asks which one it holds.
--
-- The memory is GameState.namedCopyChoices under the SOURCE's id, so it holds
-- across a change of control and after the source has left (CR 113.7a), and
-- CR 400.7's new object starts empty. The name is spent whether or not the
-- copy is cast, and with none left the arm does nothing (rulings, 2021-06-18).
--
-- ChooseCardName, CR 201.4's prompt, with the unchosen names as CR 201.4a's
-- restriction; asked only for two or more. Filtered, not trusted: an answer
-- outside them chooses nothing.
offerNamedCopy :: (Game Result -> Filter.Context -> PlayerId -> PrintingId.PrintingId -> CastOffer.CastOffer -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> NonEmpty.NonEmpty CardName.CardName -> Game ()
offerNamedCopy offerOutsideCopy runSubgame resolving source controller legal names = do
  gs <- State.get
  let spent = Map.findWithDefault Set.empty source (GameState.namedCopyChoices gs)
      remaining = NonEmpty.filter (`Set.notMember` spent) names
  picked <- case remaining of
    [] -> pure Nothing
    [only] -> pure (Just only)
    _ -> do
      answer <- Game.choose (Prompt.ChooseCardName (Decide.deciderFor controller gs) controller source (Filter.Type.Or (fmap Filter.Type.HasName remaining)) Seq.empty)
      pure (List.find (== answer) remaining)
  Monad.forM_ picked $ \name -> do
    State.modify' $ \g -> g {GameState.namedCopyChoices = Map.insertWith Set.union source (Set.singleton name) (GameState.namedCopyChoices g)}
    found <- Game.lookUpCard name
    Monad.forM_ found $ \printingId -> do
      g <- State.get
      offerOutsideCopy runSubgame (effectContext g resolving controller source legal (slotBindings resolving g)) controller printingId Common.ordinaryOffer

-- CR 707.14 (Magar of the Magic Strings): the copy is made from the card noted
-- for the SOURCE as it entered (EntryRiders.noted), so a copy of that permanent,
-- which has this ability but no note (CR 707.2), creates nothing, and the
-- note outlives the permanent's leaving (CR 113.7a). The card's last values in
-- the graveyard are its printed ones -- a copy effect ends with the zone change
-- that put it there (CR 400.7) -- so the printing is the copy's whole source.
--
-- Created outside the game, as CR 707.13's is: CR 707.14 names no zone.
offerNotedCopy :: (Game Result -> Filter.Context -> PlayerId -> PrintingId.PrintingId -> CastOffer.CastOffer -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> CastOffer.CastOffer -> Game ()
offerNotedCopy offerOutsideCopy runSubgame resolving source controller legal offer = do
  gs <- State.get
  Monad.forM_ (Map.lookup source (GameState.notedCards gs)) $ \printingId ->
    offerOutsideCopy runSubgame (effectContext gs resolving controller source legal (slotBindings resolving gs)) controller printingId offer

-- CR 601.3: write the standing permission onto every object the ObjectRef names,
-- for the player the PlayerRef names and the stated duration.
--
-- NOT gated on the object being in exile: CR 601.3's permissions are not
-- zone-scoped, so a zone test would be the rules core reading the effect.
grantPlayFromExile :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GrantPlayFromExile.GrantPlayFromExile -> Game ()
grantPlayFromExile resolving source controller legal (GrantPlayFromExile.MkGrantPlayFromExile duration player ref spending alternativeCost condition verb increase landEnters upTo) =
  State.modify' $ \gs ->
    -- The sweep every ObjectRef-taking opcode shares: a player recipient, an
    -- illegal slot (CR 608.2b) and a set that matched nothing all arrive empty.
    case objectRefObjects legal resolving controller source gs ref of
      [] -> gs
      targets -> case playerRefPlayers legal resolving source controller gs player of
        -- CR 715.3d's "that player" is ONE seat and
        -- Object.playableFromExile holds one, so a reference naming nobody --
        -- or naming several -- grants nothing, PlayerRef.InSlot's own
        -- collapse.
        [holder] -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration gs of
          -- CR 611.2b: the duration never started, so no permission is stored.
          Nothing -> gs
          Just expiry ->
            let permission =
                  (ExilePlayPermission.defaultValue holder source)
                    { ExilePlayPermission.expiry = expiry,
                      -- CR 118.14, carried from the opcode unread;
                      -- Parun.Engine.Mana is the only thing that acts on it.
                      ExilePlayPermission.spending = spending,
                      -- CR 118.9, carried from the opcode unread;
                      -- Parun.Engine.Cost is the only thing that acts on it.
                      ExilePlayPermission.alternativeCost = alternativeCost,
                      -- BAKED, Expiry.arm's ForAsLongAs reason: the permission
                      -- outlives this resolution's slots.
                      ExilePlayPermission.condition = fmap (Condition.bakeBound legal) condition,
                      -- The default's Granted origin is CR 715.3d's "other
                      -- effects that allow a player to cast it": a card said
                      -- this, not rule 715.3d, so the Adventure exclusion does
                      -- not reach it.
                      ExilePlayPermission.verb = verb,
                      -- CR 601.2f and CR 614.1d, carried from the opcode
                      -- unread; Parun.Engine.Cost and Parun.Engine.Cast.playLand
                      -- act on them.
                      ExilePlayPermission.increase = increase,
                      ExilePlayPermission.landEnters = landEnters,
                      -- CR 601.3: one budget over every object granted,
                      -- so a play of any of them spends it for all.
                      ExilePlayPermission.budget = fmap (\n -> PlayBudget.MkPlayBudget n (Set.fromList targets)) upTo
                    }
                grant o = o {Object.playableFromExile = Just permission}
             in gs {GameState.objects = foldr (Map.adjust grant) (GameState.objects gs) targets}
        _ -> gs

-- CR 406.3: write the look permission onto every object the ObjectRef names,
-- as CR 109.5's "you", plus CR 702.75a's ExileLooker.TheExiler where the
-- payload asks for it. BOTH, and rule 702.75a's hideaway wants both: the
-- player it instructed to look at the cards before exiling one face down is
-- rule 406.3's continuing looker whatever happens to the permanent afterwards.
--
-- NOT gated on the object being in exile, nor on its being face down,
-- Effect.GrantPlayFromExile's reason one rule over: a stamp that landed
-- anywhere else is inert, since Parun.Engine.Exile.mayLookAt reads it only
-- where CR 406.3's default does not already answer yes.
grantLookAtExiled :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> GrantLookAtExiled.GrantLookAtExiled -> Game ()
grantLookAtExiled resolving source controller legal grant =
  State.modify' $ \gs ->
    let granted =
          Set.insert (ExileLooker.ThePlayer controller) $
            if GrantLookAtExiled.followsExiler grant then Set.singleton ExileLooker.TheExiler else Set.empty
        allow o = o {Object.exileLookers = Set.union granted (Object.exileLookers o)}
     in gs {GameState.objects = foldr (Map.adjust allow) (GameState.objects gs) (objectRefObjects legal resolving controller source gs (GrantLookAtExiled.cards grant))}

-- CR 702.170c: each named card becomes plotted -- the stamp CR 702.170d reads
-- and the GameEvent.Plotted entry a "when this card becomes plotted" trigger
-- reads, both through Parun.Engine.Plot.becomePlotted, so this route and CR
-- 116.2k's special action say the same thing by construction. The victims are
-- enumerated ONCE (CR 608.2f).
--
-- NOT gated on the object being in exile, Effect.GrantPlayFromExile's reason one
-- rule over: every producer supplies the exile in the same clause, so a zone
-- test would gate a branch nothing can reach. A stamp that landed elsewhere is
-- inert anyway -- Cast.permitsCastPlotted is asked only of exile's members, and
-- CR 400.7's new incarnation carries no stamp across a zone change.
makePlotted :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
makePlotted resolving source controller legal ref =
  State.modify' $ \gs ->
    foldr Plot.becomePlotted gs (objectRefObjects legal resolving controller source gs ref)

-- CR 702.143d's designation, MakePlotted's arm one rule over and every
-- argument of it unchanged -- the stamp and the cost together, through
-- Parun.Engine.Foretell.becomeForetold, so this route and CR 116.2h's special
-- action say the same thing by construction.
--
-- The payload's reduction rides along because rule 702.143d's second sentence
-- states one where CR 702.170c has none; it is cashed against the exiled
-- card's own mana cost there, once, as this effect resolves.
makeForetold :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> MakeForetold.MakeForetold -> Game ()
makeForetold resolving source controller legal (MakeForetold.MkMakeForetold ref reduction) =
  State.modify' $ \gs ->
    foldr (Foretell.becomeForetold reduction) gs (objectRefObjects legal resolving controller source gs ref)

-- CR 702.185b's designation, MakePlotted's arm one rule over and every
-- argument of it unchanged, through Parun.Engine.Warp.becomeWarped.
makeWarped :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
makeWarped resolving source controller legal ref =
  State.modify' $ \gs ->
    foldr Warp.becomeWarped gs (objectRefObjects legal resolving controller source gs ref)

-- CR 701.69a: remove all the marked damage from each named permanent. The
-- victims are enumerated ONCE (CR 608.2f) off the board as it stands, so an
-- illegal slot (CR 608.2b), a player recipient and a set that matched nothing
-- all heal nothing.
--
-- A direct write and not a funnel, which is rule 702.89a's own road
-- (Parun.Engine.Event's UmbraArmor arm) and CR 701.19a's: healing is no event,
-- so there is nothing for a replacement to be offered or a trigger to see.
healArm :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
healArm resolving source controller legal ref =
  State.modify' $ \gs ->
    let heal o = o {Object.damage = 0}
     in gs
          { GameState.objects =
              foldr (Map.adjust heal) (GameState.objects gs) (objectRefObjects legal resolving controller source gs ref)
          }

forEach :: (Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()) -> (Game Result -> ObjectId -> ObjectId -> PlayerId -> SlotName -> Map.Map SlotName (Set Recipient) -> [Recipient] -> PayGate.PayGate -> Game [Recipient]) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ForEach.ForEach (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
forEach applyEffectWith loopOffers runSubgame resolving source controller legal chosen (ForEach.MkForEach ref membership slot body individually gate startingWith) = do
  gs0 <- State.get
  -- CR 608.2f: WHICH members, swept ONCE from the pre-loop board and then fixed,
  -- so the body can neither shorten the batch nor add to it. Recipients rather
  -- than objects, since rule 608.2f is about "players and/or objects" and
  -- Soulfire Eruption's targets are both.
  let swept = Common.objectRefRecipients legal resolving controller source gs0 ref
  -- CR 608.2d: a "you may" per member is ONE announcement of which members,
  -- made before the first iteration, since the loop is one action (CR 608.2f)
  -- and every choice it offers is announced while it is applied. Asked of the
  -- resolving controller; skipped at no candidate and asked at one, where "any
  -- number" leaves two answers. FILTERED, not trusted (#222), which also keeps
  -- the sweep's order.
  picked <- case membership of
    LoopMembers.Every -> pure swept
    LoopMembers.AnyNumber
      | null swept -> pure []
      | otherwise -> do
          answer <- Game.choose (Prompt.ChooseLoopMembers (Decide.deciderFor controller gs0) controller resolving swept)
          pure (filter (`Set.member` answer) swept)
  ordered <- Common.forEachOrder resolving (startingWith >>= Common.oneSeat legal resolving source controller gs0) (const (Just controller)) picked
  -- CR 118.12a per member: every offer is made before the first body runs.
  members <- maybe (pure ordered) (loopOffers runSubgame resolving source controller slot legal ordered) gate
  let -- The slots the BODY defines, computed off the instruction rather than the
      -- board: a body effect binds into the resolving object's live bindings and
      -- the next body effect must see it. Restricted to those names so a target
      -- slot cannot return under the instance name CR 700.2d renamed it from.
      bodyDefined = foldMap boundSlots body
      -- The member is bound HERE, in the map handed down, never onto the
      -- resolving object, which scopes it to this iteration. OUTERMOST, so the
      -- loop's own name wins; `m` beats `defined`, since `m` is the CR 608.2b
      -- re-validated map and shadowing it would skip a re-validation. A
      -- delayed ability armed in the body captures it from that map
      -- (Effect.ArmDelayedTrigger's arm).
      withMember member defined m = Map.insert slot (Set.singleton member) (Map.union m defined)
      bindingsOf gs = maybe Map.empty Object.bindings (Game.lookupObject resolving gs)
      -- Whatever those names held BEFORE the loop, to be put back at each
      -- iteration's start and once at the end.
      beforeLoop = Map.restrictKeys (bindingsOf gs0) bodyDefined
      -- The other half of the scoping, not tidiness: an iteration whose
      -- MoveToZone found an empty library binds nothing, and without this its
      -- DealDamage would read the card the PREVIOUS iteration exiled. Restoring
      -- rather than deleting leaves the rest of the resolution its environment
      -- for every name the loop's own accumulation (bindAcross below) does not
      -- take back over.
      rescope gs =
        gs
          { GameState.objects =
              Map.adjust
                (\o -> o {Object.bindings = Map.union beforeLoop (Map.withoutKeys (Object.bindings o) bodyDefined)})
                resolving
                (GameState.objects gs)
          }
      -- What THIS iteration bound, against what the loop started from: a name
      -- rescope restored and the body never touched is the pre-loop
      -- environment rather than this member's product.
      produced gs =
        Map.differenceWith
          (\now before -> if now == before then Nothing else Just now)
          (Map.restrictKeys (bindingsOf gs) bodyDefined)
          beforeLoop
      -- The union across the whole loop, over the two fields a body-defined
      -- name can hold: bindSlot's ONE object lands in `targets` and
      -- bindObjectsSlot's batch in `objects`, both of them definitions rather
      -- than targets (CR 115.10a), so nothing here is subject to CR 608.2b.
      -- Set union for the one and append for the other, which keeps the mint
      -- order `objects` is documented to carry. mergeBinding's `<|>` is what
      -- the remaining fields take, and no body-defined name populates them.
      joinAcross a b =
        (Binding.mergeBinding a b)
          { Binding.Type.targets = Binding.Type.targets a <> Binding.Type.targets b,
            Binding.Type.objects = Binding.Type.objects a <> Binding.Type.objects b
          }
      -- CR 608.2c: an instruction AFTER the loop names everything the body
      -- produced, across every member -- Mirror Match's "exile those tokens",
      -- ONE delayed ability over the whole batch rather than one per member.
      -- Applied over rescope's restore, so the accumulation wins for the names
      -- it holds and the pre-loop environment is what the rest keep.
      bindAcross acc gs =
        gs
          { GameState.objects =
              Map.adjust
                (\o -> o {Object.bindings = Map.union acc (Object.bindings o)})
                resolving
                (GameState.objects gs)
          }
  -- CR 608.2f's FIRST sentence: the loop is one action taken on several objects,
  -- so unless the card says its action cannot be processed simultaneously, every
  -- event the whole loop records shares one Parun.Types.EventGroup. That is what
  -- makes CR 603.6a's "all permanents on the battlefield (including the
  -- newcomers) are checked" reach a token a LATER member minted: each member's
  -- entry is offered the sample Event.recordEvent took after the last of them,
  -- rather than the one that existed when that member's own iteration ran.
  --
  -- The bracket is over the WHOLE fold and not over each member's token
  -- creation, because rule 608.2f's unit is the action the loop states, not one
  -- opcode of it -- and the ForEach.individually flag is the same rule's second
  -- sentence, which Soulfire Eruption's example states outright.
  --
  -- Nothing here reorders the members: the bracket changes which events are one
  -- event, never when each iteration runs, so rule 608.2f's APNAP ordering and
  -- CR 603.12's per-member reset are untouched.
  --
  -- The same unit is CR 613.7m's: what the one action put onto the battlefield
  -- entered simultaneously, so Event.together orders every arrival of every
  -- iteration at once, by the seats that control them -- not the loop's own
  -- order, whose chooser is the resolving controller. An individually
  -- processed loop's iterations are separate moments, and each call settles
  -- its own.
  accumulated <-
    (if individually then id else Event.simultaneously . Event.together) $
      Monad.foldM
        ( \acc member -> do
            State.modify' rescope
            -- CR 608.2c: the body's instructions in written order, per member, through
            -- the SAME fold a clause's own instructions run through -- CR 603.12's
            -- "happened" is a question about THIS member's iteration, so it resets at
            -- each member rather than carrying over from the previous one. Nihiloor's
            -- "for each opponent, tap up to one untapped creature you control. When you
            -- do, ..." is the shape: the reflexive is that opponent's own tap, not the
            -- previous opponent's.
            Common.applyClauseEffects
              resolving
              source
              ( \eff -> do
                  defined <- State.gets (\gs -> Map.restrictKeys (Binding.targetsOf (bindingsOf gs)) bodyDefined)
                  applyEffectWith runSubgame resolving source controller (withMember member defined legal) (withMember member defined chosen) eff
              )
              (Foldable.toList body)
            State.gets (Map.unionWith joinAcross acc . produced)
        )
        Map.empty
        members
  State.modify' (bindAcross accumulated . rescope)

-- CR 608.2f over numbers: the bound read once off the pre-loop board, and each
-- number bound on the source (bindAmountSlot) for its iteration's body to
-- read. One action, so ForEach's bracket: one event group, and one CR 613.7m
-- batch for everything the loop puts onto the battlefield. Parun.RestampSpec's
-- Ornate Imitations board proves the batch.
forEachNumber :: (Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Set SlotName -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> ForEachNumber.ForEachNumber (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
forEachNumber applyLoopBody runSubgame resolving source controller legal chosen (ForEachNumber.MkForEachNumber upTo slot body) = do
  gs0 <- State.get
  let viewOf = effectViewOf source legal gs0
      context = effectContext gs0 resolving controller source legal (slotBindings resolving gs0)
      count = maybe 0 Integer.toNaturalSaturating (Common.evaluateForRecipient viewOf context gs0 resolving source controller upTo)
  Event.simultaneously . Event.together . Monad.forM_ [1 .. count] $ \n -> do
    State.modify' (Common.bindAmountSlot resolving source slot n)
    applyLoopBody runSubgame resolving source controller legal chosen (foldMap boundSlots body) body

-- CR 608.2d: the body in written order, then the chooser's "may repeat",
-- asked after each run and never in advance. No event bracket: each run is its
-- own process, so each run's damage is its own event. What the body binds is
-- rescoped per run, ForEach's reason: a run whose discard found an empty hand
-- must not read the card the previous run discarded.
--
-- The chooser is the ONE player the payload names, which is Trade Secrets'
-- target opponent rather than the resolving controller, read through
-- askedChooser so CR 800.4g hands a departed chooser's ask to another player.
-- A reference naming anything but one player asks nobody and ends the loop.
--
-- Parun.ZoneChangeSpec's Kindle the Carnage group proves both the second run and
-- the rescope, and its Trade Secrets group the chooser. The CR 800.4g
-- reassignment is a fence here: no board lets a player leave the game partway
-- through a resolution.
--
-- The gate (CR 706.3c's "Roll again" on one row of a results table) is read
-- live after each run, as RepeatIf's condition is; one that fails ends the
-- loop unasked. Parun.DiceSpec's Delina, Wild Mage group proves it.
repeatArm :: (Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Set SlotName -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Repeat.Repeat (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
repeatArm applyLoopBody runSubgame resolving source controller legal chosen (Repeat.MkRepeat chooser body gate) = do
  rescope <- State.gets (Common.rescopeRun resolving (foldMap boundSlots body))
  let run runs = do
        State.modify' rescope
        applyLoopBody runSubgame resolving source controller legal chosen (foldMap boundSlots body) body
        gs0 <- State.get
        let context = effectContext gs0 resolving controller source legal (slotBindings resolving gs0)
            open = all (Condition.holds (effectViewOf source legal gs0) context gs0 source) gate
        asked <- if open then Common.askedChooser resolving source controller legal chooser else pure Nothing
        Monad.forM_ asked $ \who -> do
          gs <- State.get
          again <- Game.choose (Prompt.ChooseRepeat (Decide.deciderFor who gs) who resolving runs)
          Monad.when (again == OptionalDecision.Exercises) (run (runs + 1))
  run 1

-- CR 608.2c: the process in written order, then its printed "if" asked of the
-- state that run left -- live, so the tally the run's own mill just bound is
-- what it reads. While it holds, the "if"'s instructions and another run. No
-- prompt: no player chooses, which is Effect.Repeat's CR 608.2d difference.
-- Rescoped and unbracketed per run for Effect.Repeat's reasons.
--
-- Parun.PlaneswalkerSpec's GristLoyalty group proves the run count.
repeatIf :: (Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Set SlotName -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> RepeatIf.RepeatIf (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
repeatIf applyLoopBody runSubgame resolving source controller legal chosen (RepeatIf.MkRepeatIf process condition ifHolds) = do
  let bound = foldMap boundSlots (process <> ifHolds)
  rescope <- State.gets (Common.rescopeRun resolving bound)
  let apply = applyLoopBody runSubgame resolving source controller legal chosen bound
      run = do
        State.modify' rescope
        apply process
        gs <- State.get
        -- The ONE object a run's instruction bound sits in its binding's
        -- `targets`, which effectContext reads only through the map it is
        -- handed, so the run's own names join it here, as Effect.ForEach's
        -- `defined` does for its body: Thieves' Auction's "chosen".
        let seen = Map.union legal (Map.restrictKeys (Binding.targetsOf (slotBindings resolving gs)) bound)
            context = effectContext gs resolving controller source seen (slotBindings resolving gs)
        Monad.when (Condition.holds (effectViewOf source seen gs) context gs source condition) $ do
          apply ifHolds
          run
  run

draw :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Draw.Draw -> Game ()
draw resolving source controller legal (Draw.MkDraw ref quantity mSlot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      named = playerRefPlayers legal resolving source controller gs ref
      -- CR 121.2c: the active player draws first, then each other player in turn
      -- order. Observable rather than cosmetic: each draw records a zone change
      -- the trigger scan reads (CR 603.2). Not implemented: CR 121.2d's order within
      -- the active team, which that team chooses (#4014). An intersection: apnapOrder supplies the ORDER and `named`
      -- the MEMBERSHIP, which matters for a seat apnapOrder names and `named`
      -- does not -- a departure leaves the roster (CR 800.4k) but takes the
      -- library (CR 800.4a), so drawing would write drewFromEmpty.
      drawers = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
  -- PER DRAWER (evaluateForRecipient), every amount off the same pre-effect `gs`,
  -- so a seat drawing first cannot change what a later seat draws.
  drawn <- fmap concat . Monad.forM drawers $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        | n > 0 -> do
            -- CR 121.2a: the INSTRUCTION is its own replaceable event, and rule
            -- 616.1g settles it before any of the individual draws below -- so
            -- the count those draws run on is the one this loop leaves standing,
            -- and a row that replaced the instruction outright leaves none.
            outcome <- Event.applyReplacements (ProposedEvent.WouldPerform PlayerInstruction.DrawCards Nothing pid (Integer.toNaturalSaturating n))
            got <- case outcome >>= Replacement.asPerformed PlayerInstruction.DrawCards of
              Nothing -> pure []
              -- CR 121.2: draw the settled count one at a time, so each draw
              -- re-reads the library top and the CR 104.3c empty-library loss is
              -- preserved.
              Just (drawer, settled) ->
                Maybe.catMaybes <$> Monad.replicateM (Natural.toIntSaturating settled) (Event.drawCardReturning drawer)
            -- CR 603.12: fewer cards drawn than the instruction named, against
            -- the count BEFORE any replacement -- The Royal Scions' 2019-10-04
            -- rulings, fewer than four does not trigger and five or more does.
            Monad.when (List.genericLength got < n) Common.fallShort
            pure got
      _ -> pure []
  -- CR 121.1's "and reveal IT": the cards the draw put into a hand, for a later
  -- clause of this resolution to name (#1899). The ids are the ones the CR 400.7
  -- funnel ANSWERED -- the incarnation in the hand -- so a reader finds the card
  -- where the rule says it is; a draw a replacement diverted (CR 121.6c, even to
  -- another drawer), or one off an empty library, contributes nothing and binds
  -- nothing. Parun.Types.Draw says why CR 701.20a rather than CR 400.7j is what
  -- makes the card findable in a hidden zone.
  --
  -- ACROSS drawers and across CR 121.2's individual draws, the tally's posture
  -- in the Mill arm below: the slot is one name and no reader is per-player.
  -- The one/many split is every other group binder's -- one card takes the
  -- SINGLE binding, which slotOne and every singular reader can see, and
  -- several take the group.
  Common.bindObjects resolving mSlot drawn

mill :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Mill.Mill -> Game ()
mill resolving source controller legal (Mill.MkMill ref quantity mTally mSlot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- An illegal slot (CR 608.2b) or a reference naming nobody mills nothing.
      millers = playerRefPlayers legal resolving source controller gs ref
      -- The number each miller is INSTRUCTED to mill, before CR 614.1a has had a
      -- say and before CR 701.17b's library is looked at. PER MILLER
      -- (evaluateForRecipient), off the one pre-effect `gs`, so a seat milling
      -- first cannot change what a later seat is told to mill.
      wanted =
        Maybe.mapMaybe
          ( \pid -> case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
              Just n | n > 0 -> Just (pid, Integer.toNaturalSaturating n)
              _ -> Nothing
          )
          millers
  -- Through Event.millFromReturningTaken, the one mill funnel: it settles the
  -- instruction under CR 616.1g (Bruvac the Grandiloquent doubles it), clamps to
  -- CR 701.17b's library, and moves each card through the CR 400.7 funnel so
  -- every arrival is a fresh incarnation. It answers both the LIBRARY ids taken,
  -- which the tally below asks its characteristics of, and the ids the moves
  -- ANSWERED, which CR 701.17c's binding holds.
  --
  -- Then recorded as the mill it was (CR 701.17a): a cancelled move is no card
  -- milled, so ONE entry per miller holding that player's whole batch, since
  -- rule 701.17a mills them at once -- and recorded even for a card a
  -- replacement diverted elsewhere, since it was milled wherever it ended up.
  milledBy <- Monad.forM wanted $ \(pid, n) -> do
    (taken, arrived) <- Event.millFromReturningTaken pid n
    Monad.unless (null arrived) (State.modify' (Event.recordEvent (GameEvent.Milled (Milled.MkMilled pid (Seq.fromList arrived)))))
    -- CR 701.17b / 603.12: a library too short for the count named, the Draw
    -- arm's shortfall (Wick's Patrol's 2024-07-26 ruling).
    Monad.when (List.genericLength taken < n) Common.fallShort
    pure (taken, arrived)
  let milled = concatMap fst milledBy
      arrivals = concatMap snd milledBy
  -- CR 701.17c: a later clause naming the milled cards -- Midnight Tilling's
  -- "from among them" -- finds them in the graveyard they moved to, so the
  -- binding holds the ids the funnel ANSWERED rather than the library ids the
  -- tally counts (CR 400.7). A card a replacement diverted elsewhere is bound
  -- too, and rule 701.17c is then what decides whether a reader can find it:
  -- an exile is public and a hand is not, which is a question about the READER
  -- rather than about this binding.
  --
  -- ACROSS millers, since the slot is one name and no reader is per-player --
  -- the tally's own posture. The one/many split is every other group binder's:
  -- one milled card takes the SINGLE binding, which slotOne and every singular
  -- reader can see, and several take the group.
  Common.bindObjects resolving mSlot arrivals
  -- The tally, read from the pre-move state because CR 400.7 has since minted
  -- new ids. Each milled card is judged by its own CR 613 projection: rule
  -- 613.1 starts from the actual object and names no zone, so a library card is
  -- folded exactly as a permanent is, and a layer-4 type change (CR 613.1d)
  -- decides rule 728.1's "nonland card" there. Every milled id names a card in
  -- a library, so there is no faceless object for the projection to answer
  -- blankly about.
  --
  -- Through effectContext and NOT Filter.contextFor, so the resolution's own
  -- reads answer here as they do at every other position of it (CR 608.2c): the
  -- slots earlier clauses bound, their names and their amounts, and CR 201.4's
  -- chosen name overlaid the way the Effect.Search arm overlays it -- Predict's
  -- "a card with the chosen name was milled this way", which Parun.ResolveSpec
  -- proves. Read off the LIVE state rather than the pre-effect `gs` the views
  -- come from, since the clause that chose the name is one this resolution has
  -- already carried out.
  --
  -- The VIEWS stay on the pre-effect `gs` for the reason above: CR 400.7 has
  -- minted new ids for the cards themselves, and `milled` holds the library
  -- ones. So the mill's OWN slot, bound just above off the arrival ids, names
  -- nothing this fold can match -- Filter.IsBound over it is False here
  -- whatever the map holds. Unwritable rather than unimplemented: the tally
  -- folds over exactly the cards that slot was bound to, so the atom asks
  -- whether a milled card is one of the milled cards, and no card can say
  -- anything with it. CR 400.7j is about a LATER part of the effect finding
  -- them, which the binding answers off the arrival ids. The tally's other
  -- slot reads are unaffected: an EARLIER clause's slot over a library card
  -- matches the pre-move ids these views carry, and Filter.Shares Name Bound
  -- reads names off the arrival ids through CR 608.2h's last-known reader.
  --
  -- The chosen-name half is PROVED (Parun.ResolveSpec's "Predict's mill tally
  -- reads the name its own first clause chose"); the SLOT half is a regression
  -- fence, since no card in the pool names an earlier clause's slot from a
  -- tally, and swapping effectContext back for a bare Filter.contextFor leaves
  -- the whole suite green. It is written because CR 608.2c states it.
  --
  -- Bound onto this effect's SOURCE, so a later effect reads it as
  -- Quantity.InSlot; bound even at zero, since zero is an answer. ONE number
  -- across every miller, as no Quantity has a per-player reader.
  Monad.forM_ mTally $ \tally -> do
    gs2 <- State.get
    let tallyContext = effectContext gs2 resolving controller source legal (slotBindings resolving gs2)
        viewOfMilled = Projection.viewsOf gs
        counted oid = Filter.matches tallyContext (viewOfMilled oid) (MillTally.filter tally)
    State.modify' (Common.bindAmountSlot resolving source (MillTally.slot tally) (Natural.length (filter counted milled)))

-- CR 701.20a: show the named cards to every player. CR 701.20b keeps them where
-- they are, so the GameEvent.Revealed the funnel appends IS the whole effect.
--
-- The SHOWER is the player CARRYING OUT the instruction (CR 701.20a): for
-- RandomCardInHand that is the seat whose hand it is, not the controller.
-- RevealCause.Ordinary, since rule 702.94a's "this way" is the miracle window's
-- alone. One reveal per named card, which is all GameEvent.Revealed's single
-- ObjectId allows and all rule 701.20a asks for.
reveal :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Reveal.Reveal -> Game ()
reveal resolving source controller legal chosen (Reveal.MkReveal ref mSlot) = do
  gs <- State.get
  -- Name what was shown, if the card asked for a name, in ONE write per
  -- reveal: LookAt's one-versus-many line. A lone card takes the SINGLE
  -- binding, which every reader sees; several take the group binding, which
  -- the ObjectRef readers and Filter.IsBound see and slotOne does not.
  let bindShown = Common.bindObjects resolving mSlot
  -- Asked through askingObjects, so the card revealed and the card a later
  -- clause moves through mSlot cannot come apart: Carth the Lion's "reveal a
  -- planeswalker card from among them and put it into your hand" is ONE choice.
  -- Every card named across every seat is bound as one group, which Fall reads
  -- back with an EachCardFromAmong. Parun.MassEffectSpec's UncoveredClues group
  -- proves the binding.
  named <- Common.askingObjects resolving source controller legal chosen ref
  let -- A card in a hand is shown by the seat whose hand it is -- Duress's
      -- "target opponent reveals their hand", Fall's random cards. A card
      -- picked "from among them" is shown by the resolving controller, who
      -- carries the instruction out.
      shower oid = case (ref, Game.lookupObject oid gs) of
        (ObjectRef.ChosenCardFromAmong {}, _) -> controller
        (_, Just obj) | Object.zone obj == Zone.Hand -> Object.owner obj
        _ -> controller
  Monad.mapM_ (\oid -> Event.revealResolving resolving (shower oid) oid) named
  bindShown named

lookAt :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> LookAt.LookAt -> Game ()
lookAt resolving source controller legal (LookAt.MkLookAt ref slot looker) = do
  -- CR 608.2c: the cards are named as this instruction is reached, and CR 701.20b
  -- (via rule 701.20e) leaves every one where it is -- so the arm is the
  -- binding plus a GameEvent.Looked per card and looker, and an empty library
  -- binds and records nothing. A public GameEvent.Revealed would be a different
  -- rule (CR 701.20a).
  --
  -- A read and never an ask: the look shows every card it names, so a choice
  -- among them is a later instruction's, Word of Command's "choose a card from
  -- it" reading this slot from its OfferCast.
  gs <- State.get
  let named = objectRefObjects legal resolving controller source gs ref
  Monad.forM_ named $ \oid ->
    Monad.forM_ (playerRefPlayers legal resolving source controller gs looker) $ \pid -> Event.look pid oid
  -- Several cards take the group, which Filter.IsBound reads as CR 701.20e's
  -- "among them".
  Common.bindObjects resolving (Just slot) named

arrangeInLibrary :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ArrangeInLibrary.ArrangeInLibrary -> Game ()
arrangeInLibrary resolving source controller legal (ArrangeInLibrary.MkArrangeInLibrary ref chooser) = do
  -- CR 608.2c / 608.2d: the instruction's player states the order, not the
  -- library's owner -- Cruel Fate's caster orders an opponent's cards. A
  -- chooser naming nobody leaves the cards where they are (CR 101.3).
  asked <- Common.askedChooser resolving source controller legal chooser
  gs <- State.get
  -- CR 608.2c: the cards are named as this instruction is reached, which for
  -- Ponder is the slot the look bound one clause earlier.
  let named = objectRefObjects legal resolving controller source gs ref
      -- CR 400.3 makes every library its owner's, so the owner is the seat
      -- whose library is rewritten.
      owners = ListUtils.nubOrd (Maybe.mapMaybe (\oid -> fmap Object.owner (Game.lookupObject oid gs)) named)
  -- APNAP (CR 101.4) for a reference that could name two seats' cards at once;
  -- each library is rewritten before the next is asked.
  Monad.forM_ asked $ \arranger ->
    Monad.mapM_ (Common.arrangeInLibrary arranger named) (filter (\pid -> List.elem pid owners) (Game.apnapOrder gs))

scry :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
scry resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- An illegal slot (CR 608.2b) or a reference naming nobody scries nothing.
      named = playerRefPlayers legal resolving source controller gs ref
      -- CR 701.22c: players scrying at once decide in APNAP order -- apnapOrder
      -- supplies the ORDER, `named` the MEMBERSHIP.
      scryers = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
  -- CR 701.22c's two phases: every scryer decides, and only then do the cards
  -- move, so no decider is asked over a board an earlier one already changed.
  -- Parun.LibraryOrderSpec's "CR 701.22c Eager Construct" case proves it.
  decided <-
    fmap Maybe.catMaybes . Monad.forM scryers $ \pid ->
      case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
        -- CR 701.22b: scry 0 is not a scry, so zero raises no prompt and
        -- proposes no event for a CR 614.1a row to replace.
        Just n | n > 0 -> do
          outcome <- Event.applyReplacements (ProposedEvent.WouldPerform PlayerInstruction.Scry Nothing pid (Integer.toNaturalSaturating n))
          -- A row that replaced the scry outright (Eligeth, Crossroads Augur)
          -- has done its own work: nothing to decide and, CR 614.6, no scry.
          Monad.forM (outcome >>= Replacement.asPerformed PlayerInstruction.Scry) $ \(scryer, settled) ->
            Common.decideScry (toInteger settled) scryer
        _ -> pure Nothing
  Monad.mapM_ (\(pid, order) -> Monad.forM_ order (\(looked, whole) -> State.modify' (Common.reorderLibrary pid looked whole))) decided
  -- CR 701.22d: recorded once the process is complete, and for a scry whose
  -- move was impossible too.
  Monad.mapM_ (\(pid, _) -> State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Scry pid)))) decided

surveil :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
surveil resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- Scry's arm in every respect, APNAP and both phases included (CR
      -- 101.4, rule 701.25 stating no order of its own).
      named = playerRefPlayers legal resolving source controller gs ref
      surveillers = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
  -- The split is a regression fence rather than a proven behaviour: no card
  -- in data/cards/ names two surveillers, and MTGJSON's 2026-08-23 dump has no
  -- printing whose text puts "each player", "each opponent" or "target
  -- players" before "surveil".
  decided <-
    fmap Maybe.catMaybes . Monad.forM surveillers $ \pid ->
      case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
        -- CR 701.25c: surveil 0 is not a surveil at all, so nothing widens
        -- it. CR 701.25b's extra cards join the ones looked at, each grant's
        -- "may" asked on its own, read off the board the surveil begins on.
        Just n | n > 0 -> do
          extras <- Monad.forM [(grant, grantEffect, count) | (grant, grantEffect@(PlayerEffect.Type.AdditionalSurveilCards count)) <- PlayerEffect.offeredExtras pid gs] $ \(grant, grantEffect, count) -> do
            answer <- Game.choose (Prompt.OfferedExtra (Decide.deciderFor pid gs) pid grant grantEffect)
            case answer of
              OptionalDecision.Exercises -> pure count
              OptionalDecision.Declines -> pure 0
          fmap Just (Common.decideSurveil (n + toInteger (sum extras)) pid)
        _ -> pure Nothing
  Monad.mapM_ Common.applySurveil decided
  -- CR 701.25d, scry's placement and for its rule.
  Monad.mapM_ (\(pid, _) -> State.modify' (Event.recordEvent (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.Surveil pid)))) decided

fateseal :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
fateseal resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- The players who FATESEAL, not the ones fatesealed (CR 701.29a); whose
      -- library is looked at is fatesealOne's separate choice.
      named = playerRefPlayers legal resolving source controller gs ref
      fatesealers = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
  -- One fatesealer at a time, unlike Scry's two phases: MTGJSON's 2026-08-23
  -- dump has no printing whose text puts "each player", "each opponent" or
  -- "target players" before "fateseal", so no card makes two players
  -- fateseal at once.
  Monad.forM_ fatesealers $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
      -- Zero reaches no library, so there is nothing to look at and nobody to
      -- ask. Rule 701.29 states no zero case of its own, unlike CR 701.22b.
      Just n | n > 0 -> Common.fatesealOne source n pid
      _ -> pure ()

-- CR 701.30b: the resolving controller clashes with an opponent they choose,
-- and the outcome is bound at the slot for a later clause to read (Pulling
-- Teeth's "if you win" against its "otherwise").
clash :: ObjectId -> ObjectId -> PlayerId -> SlotName -> Game ()
clash resolving source controller slot = do
  won <- Common.clash resolving source controller
  State.modify' (Common.bindAmountSlot resolving source slot won)

-- CR 702.85b: each "as you cascade" action the cascading player has, taken
-- over the exiled batch before the cast decision. Each is "you may put a
-- matching card from among them onto the battlefield tapped", so its choice
-- is ChosenCardFromAmong's up-to-one: the empty answer declines, and two
-- matching cards are a real choice. The row's SOURCE is the move's, so its
-- Filter is read in the row's context and the prompt names the row's
-- permanent; `resolving` stays the cascade ability, where the batch is bound.
asYouCascade :: (Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()) -> Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> SlotName -> Game ()
asYouCascade applyOneEffect runSubgame resolving source controller legal chosen slot = do
  gs <- State.get
  Monad.forM_ (PlayerEffect.cascadeActions controller gs) $ \(rowSource, criterion) ->
    applyOneEffect
      runSubgame
      resolving
      (Maybe.fromMaybe source rowSource)
      controller
      legal
      chosen
      ( Effect.MoveToZone
          ( MoveToZone.MkMoveToZone
              (ObjectRef.ChosenCardFromAmong (ChosenCardFromAmong.MkChosenCardFromAmong slot criterion (HowMany.UpTo (Just (Quantity.Type.Literal 1))) (PlayerRef.Relative PlayerRelation.You)))
              Zone.Battlefield
              EntryRiders.defaultValue {EntryRiders.tapped = TapState.Tapped}
              Nothing
              Nothing
              LibraryPlacement.defaultValue
              Nothing
          )
      )

explore :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ObjectRef -> Game ()
explore resolving source controller legal ref = do
  gs <- State.get
  -- CR 608.2c: the set is swept as this instruction is reached; an illegal slot
  -- (CR 608.2b) or a player recipient answers with nobody -- Recipient.objectOf
  -- drops the latter, which is why the sweep can be the RECIPIENT one and still
  -- reach only permanents.
  --
  -- CR 701.44d's order, through forEachOrder: APNAP across seats, then that
  -- seat's OWN choice within it -- `id`, not the resolving controller CR 608.2f
  -- names one rule up. The seat comes from recipientSeat, which reads
  -- Projection.controllerWithLastKnown, so it agrees with exploreOne about a
  -- permanent that has left (CR 701.44c).
  ordered <- Common.forEachOrder resolving Nothing id (Common.objectRefRecipients legal resolving controller source gs ref)
  Monad.mapM_ (Common.exploreOne resolving) (Maybe.mapMaybe Recipient.objectOf ordered)

connive :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Connive.Type.Connive -> Game ()
connive resolving source controller legal (Connive.Type.MkConnive quantity ref) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
  -- Explore's sweep and order, CR 701.50c stating CR 701.44d's rule over again,
  -- its seats read through last known information by CR 701.50b.
  ordered <- Common.forEachOrder resolving Nothing id (Common.objectRefRecipients legal resolving controller source gs ref)
  -- CR 701.50d's N, read ONCE as this instruction is reached (CR 608.2c):
  -- Raffine, Scheming Seer's "the number of attacking creatures" cannot move
  -- because an earlier conniver in the same instruction drew and discarded.
  -- Amass's arm for the unevaluable case.
  case Quantity.evaluateFor viewOf context gs resolving source quantity of
    Nothing -> pure ()
    Just n -> Monad.mapM_ (Common.conniveOne (Integer.toNaturalSaturating n)) (Maybe.mapMaybe Recipient.objectOf ordered)

-- The card names the set, so CR 701.9b's default choice -- the discarding
-- player's -- does not arise and the discarding player is not prompted. Named
-- ONCE as this instruction is reached (CR 608.2c) and then fixed (CR 608.2f),
-- and buried through the same funnel the counted branch below uses, so CR
-- 701.9a's move is RECORDED as a discard -- writing it as a zone change instead
-- would land every card in the right graveyard and leave
-- TriggerCondition.SelfDiscarded silent.
--
-- CR 701.9b's two exceptions are refs that ASK rather than read, through
-- askingObjects: a random discard (Hymn to Tourach), and a card another player
-- chooses (Duress) from among the hand an earlier Reveal bound.
--
-- The discarding player is PER CARD: rule 701.9a moves a card from its OWNER's
-- hand, and a ref over CR 400.1's per-player zone can name several owners'
-- cards at once. A card whose owner cannot be read is skipped rather than
-- filed under the controller.
discard :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Discard.Discard -> Game ()
discard resolving source controller legal chosen (Discard.These (TheseDiscard.MkTheseDiscard ref mDiscarded)) = do
  named <- Common.askingObjects resolving source controller legal chosen ref
  gs <- State.get
  let owned oid = fmap (\obj -> (Object.owner obj, [oid])) (Game.lookupObject oid gs)
  -- One event group, CR 608.2f, through the other arms' burial, so what
  -- moved is bound the same way.
  Common.buryDiscards resolving mDiscarded (Maybe.mapMaybe owned named)
discard resolving source controller legal _ (Discard.Counted (CountedDiscard.MkCountedDiscard ref quantity mDiscarded)) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
  let -- Every player the reference names, in APNAP order (CR 101.4): a slot
      -- that is unfilled, illegal (CR 608.2b) or names an object contributes
      -- nobody, and apnapOrder supplies the ORDER while `named` supplies the
      -- MEMBERSHIP.
      named = playerRefPlayers legal resolving source controller gs ref
      victims = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
      -- Read against the VICTIM, not the controller, so "cards equal to the
      -- number of creatures they control" is answered per discarding player.
      pickFor victim =
        case Common.evaluateForRecipient viewOf context gs resolving source victim quantity of
          Just n
            | n > 0 -> do
                let held = Game.zoneMembers Zone.Hand victim gs
                    -- `n > 0` above, so the clamp never decides anything here.
                    count = Integer.toNaturalSaturating n
                if count >= Natural.length held
                  -- CR 609.3: discarding the whole hand is "as much as possible," so
                  -- it is forced -- no choice, so no prompt.
                  then pure (victim, held)
                  else do
                    -- CR 701.9b: the discarding player chooses which cards.
                    let decider = Decide.deciderFor victim gs
                    choices <- Game.choose (Prompt.ChooseDiscard decider victim held count)
                    -- FILTERED AND COMPLETED, PlayerSacrifices' posture. This
                    -- branch is reached only when the hand is LARGER than the
                    -- count, so CR 609.3 does no work and every omitted card is one
                    -- the player could have discarded. Deduplicated too, since the
                    -- answer is a LIST and a card named twice would fill two of the
                    -- n slots; `valid <> filler` permutes `held`, so the take is n.
                    let valid = ListUtils.nubOrd (filter (\c -> elem c held) choices)
                        filler = filter (\c -> List.notElem c valid) held
                    pure (victim, List.genericTake count (valid <> filler))
          _ -> pure (victim, [])
  -- CR 101.4: every player chooses in APNAP order, and only THEN do the
  -- actions happen -- PlayerSacrifices' two phases, whose edict is 101.4's own
  -- worked example, so no seat's discard can change what a later seat is
  -- offered. CR 101.4a is why a hand is no exception. The candidate hands are read off the
  -- one `gs` above for the same reason (CR 608.2f).
  --
  -- The SPLIT is a regression fence rather than a proven behaviour: interleaving
  -- the burials with the picks left the suite green, because `held` is read off
  -- the frozen `gs` either way and no printing lets one player's discard reach
  -- another player's hand. The ORDER is proven -- ZoneChangeSpec's "CR 101.4:
  -- asked in turn order from the active player" reads the sequence of prompts.
  doomed <- traverse pickFor victims
  Common.buryDiscards resolving mDiscarded doomed

-- CR 107.1c: each player the reference names picks any number of the matching
-- cards in their own hand, none included (CR 701.9b's chooser), and the picks
-- are then discarded together -- the Counted arm's two phases and burial, for
-- its reasons. The candidates are read off one `gs` (CR 608.2f), the filter in
-- this effect's context, so its "you" is CR 109.5's.
--
-- Skipped at no candidate and at a ceiling of zero, where the empty set is the
-- only answer, and asked at ONE, chosenPermanents' posture: "any number"
-- leaves two distinguishable answers there. FILTERED, not trusted (#222), and
-- capped at the ceiling.
discard resolving source controller legal _ (Discard.AnyNumber (AnyNumberDiscard.MkAnyNumberDiscard ref (AnyNumberMatching.MkAnyNumberMatching filter_ atMost) mDiscarded)) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      named = playerRefPlayers legal resolving source controller gs ref
      victims = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
      pickFor victim = do
        let candidates = handCardsOf context gs victim filter_
            -- Read against the VICTIM, the Counted arm's count's reason.
            ceiling_ = fmap (maybe 0 Integer.toNaturalSaturating . Common.evaluateForRecipient viewOf context gs resolving source victim) atMost
            capped :: [a] -> [a]
            capped = maybe id (take . Natural.toIntSaturating) ceiling_
        if null candidates || ceiling_ == Just 0
          then pure (victim, [])
          else do
            answer <- Game.choose (Prompt.ChooseAnyNumber (Decide.deciderFor victim gs) victim source AnyNumberOf.ToDiscard candidates ceiling_)
            pure (victim, capped (filter (`Set.member` answer) candidates))
  doomed <- traverse pickFor victims
  Common.buryDiscards resolving mDiscarded doomed

loseLife :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> LifeLoss.LifeLoss -> Game ()
loseLife resolving source controller legal (LifeLoss.MkLifeLoss ref quantity cause mTally) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- Whoever the PlayerRef names loses the life. Unordered: there is no CR
      -- 121.2c for life, and CR 704.3 checks state-based actions only as a player
      -- would get priority, so no total is observable in between.
      losers = playerRefPlayers legal resolving source controller gs ref
  -- PER PAYER (evaluateForRecipient): Shahrazad's "half THEIR life" reads each
  -- payer's own total, and every number is read off the SAME `gs`.
  --
  -- CR 608.2f's bracket, the GainLife arm's and for its reason: one instruction
  -- naming several players is one event, so every seat's loss shares a
  -- Parun.Types.EventGroup.
  --
  -- A FENCE rather than a proved behaviour, and the same goes for the
  -- SetLifeTotal, ExchangeLifeTotals and RedistributeLifeTotals brackets below:
  -- only a life GAIN has a CR 603.2c batch condition watching it
  -- (Parun.Types.TriggerCondition.PlayersGainLife), so dropping this bracket
  -- leaves the suite green. It is here because the rule says so.
  lost <- Event.simultaneously . fmap sum . Monad.forM losers $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        | n > 0 -> do
            -- CR 119.3: the life total is simply adjusted. Not through
            -- Parun.Engine.Damage: CR 119.2 makes damage a CAUSE of life loss,
            -- not a synonym. CR 704.5a's state-based action is the existing one
            -- in Parun.Engine.Sba.
            --
            -- Through Event.resolveLifeLoss, CR 614.1's funnel for the class,
            -- carrying the opcode's own cause -- CR 119.3's ByEffect for every
            -- printing, CR 728.1a's ByRadiation for the one ability
            -- Parun.Engine.Rad mints: a row scoped to damage does not reach this
            -- road, which is Worship's own ruling ("Worship does not prevent loss
            -- of life, so loss of life bypasses Worship") and what
            -- Parun.ReplacementSpec's Worship group proves on a board where the
            -- same player at the same life survives 3 damage and dies to
            -- Stronghold Discipline's 3.
            settled <- Event.resolveLifeLoss cause pid (Integer.toNaturalSaturating n)
            Event.changeLife pid (negate (toInteger settled))
            pure settled
      _ -> pure 0
  -- Rule 702.101a's "the total life lost this way", written where a later
  -- effect of this resolution reads it as Quantity.InSlot. The SETTLED total,
  -- summed after CR 614.1's replacements had their say, so an opponent whose
  -- loss was stopped contributes nothing.
  Monad.forM_ mTally $ \slot -> State.modify' (Common.bindAmountSlot resolving source slot lost)

-- CR 119.3's other half, LoseLife's mirror but for the sign. The `n > 0` guard
-- is CR 119.9: a gain of 0 is no life gain event to trigger on.
--
-- CR 608.2f's bracket: "each player gains 4 life" is ONE action taken on
-- several players and is processed simultaneously, so every seat's gain shares
-- one Parun.Types.EventGroup and a CR 603.2c batch condition watching life gain
-- across players sees one trigger event rather than one per seat. Nothing about
-- the WRITES moves: the amounts already come off the one pre-effect `gs`, and
-- what the bracket changes is the group the log stamps.
gainLife :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
gainLife resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      gainers = playerRefPlayers legal resolving source controller gs ref
  Event.simultaneously . Monad.forM_ gainers $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        -- Through Event.resolveLifeGain, CR 614.1's funnel for the gain class,
        -- LoseLife's road above one direction over: a LifeGainR row resizes the
        -- gain and the SETTLED amount is what moves the total.
        | n > 0 -> do
            settled <- Event.resolveLifeGain pid (Integer.toNaturalSaturating n)
            Event.changeLife pid (toInteger settled)
      _ -> pure ()

-- CR 701.12c: both sides reach each other's PREVIOUS total, so both deltas are
-- read off the same game state before either is written. Written as a gain and
-- a loss rather than two assignments, which is what puts a LifeGained and a
-- LifeLost in the log.
--
-- BOTH sides go through changeLifeByDelta, so each is proposed -- the lowered
-- one as a life loss, the raised one as a life gain -- and CR 701.12c's
-- "replacement effects may modify these gains and losses" is reachable;
-- ReplacementSpec's Bloodletter group proves the loss half.
--
-- CR 701.12c's deferral to CR 119.7-8: a player who can't gain life can't be
-- given a higher total this way and a player who can't lose life can't be
-- given a lower one, and CR 119.7-8 both say what happens then -- "the
-- exchange won't happen", the WHOLE exchange, which is CR 701.12a's
-- all-or-nothing again. Asked through `barred` below, so nothing here cases on
-- an effect. Parun.ZoneChangeSpec's ExchangeLifeTotals group is the proof.
--
-- CR 810.9e needs nothing: teammates sharing a total (Game.lifeSharers) hold
-- the same one, so both deltas are zero and the exchange moves nothing.
exchangeLifeTotals :: PlayerId -> Map.Map SlotName (Set Recipient) -> ExchangeSides.ExchangeSides -> Game ()
exchangeLifeTotals controller legal sides = do
  gs <- State.get
  let twoSides = case sides of
        ExchangeSides.WithController slot -> case legalOne slot legal of
          Just (Recipient.ToPlayer other) -> Just (controller, other)
          _ -> Nothing
        ExchangeSides.BetweenTargets slot -> case legalMany slot legal of
          [Recipient.ToPlayer one, Recipient.ToPlayer two] -> Just (one, two)
          _ -> Nothing
  case twoSides of
    Just (this, that) -> do
      let lifeOf pid = maybe 0 Player.life (Map.lookup pid (GameState.players gs))
          thisLife = lifeOf this
          thatLife = lifeOf that
          -- CR 119.7 / 119.8: would this seat's new total be one a "can't"
          -- forbids it reaching? Read off the same pre-exchange `gs` the
          -- deltas are, so both sides are judged against the totals CR
          -- 701.12c's "previous life total" names.
          barred pid delta
            | delta > 0 = PlayerEffect.prohibitsGainingLife pid gs
            | delta < 0 = PlayerEffect.prohibitsLosingLife pid gs
            | otherwise = False
      -- CR 608.2f's bracket: an exchange is ONE action taken on two players --
      -- CR 701.12a's "the entire exchange", which either happens or does not --
      -- so the gain and the loss it decomposes into share one
      -- Parun.Types.EventGroup rather than reading as two events in sequence.
      Monad.unless (barred this (thatLife - thisLife) || barred that (thisLife - thatLife))
        . Event.simultaneously
        $ do
          Common.changeLifeByDelta this (thatLife - thisLife)
          Common.changeLifeByDelta that (thisLife - thatLife)
    -- CR 701.12a: if the entire exchange can't be completed, no part of it
    -- occurs.
    Nothing -> pure ()

-- CR 701.12g: both values are read off the one pre-exchange `gs` before
-- either is written, so each reaches the other's PREVIOUS value. A life total
-- moves through changeLifeByDelta, the ExchangeLifeTotals arm's road; a power
-- or toughness is set by a layer-7b effect (CR 613.4b) holding the other value
-- as a literal, for the card's stated duration (CR 611.2a).
--
-- CR 701.12a's all-or-nothing: a side naming no single player, or no creature
-- on the battlefield, or a life total CR 119.7-8 forbids reaching, cancels the
-- whole exchange. Parun.ZoneChangeSpec's ExchangeValues group is the proof.
exchangeValues :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> ExchangeValues.ExchangeValues -> Game ()
exchangeValues resolving source controller legal (ExchangeValues.MkExchangeValues one other duration) = do
  gs <- State.get
  let single xs = case xs of
        [x] -> Just x
        _ -> Nothing
      -- A side's previous value, and what writing a new one does -- Nothing
      -- when CR 119.7-8 forbid it.
      side value = case value of
        ExchangedValue.LifeTotal ref -> do
          pid <- single (playerRefPlayers legal resolving source controller gs ref)
          life <- Player.life <$> Map.lookup pid (GameState.players gs)
          let barred new
                | new > life = PlayerEffect.prohibitsGainingLife pid gs
                | new < life = PlayerEffect.prohibitsLosingLife pid gs
                | otherwise = False
          pure (life, \new -> if barred new then Nothing else Just (Common.changeLifeByDelta pid (new - life)))
        ExchangedValue.Power ref -> creature ref Projection.powerOf (\new -> SetBasePowerToughness.MkSetBasePowerToughness (Just new) Nothing)
        ExchangedValue.Toughness ref -> creature ref Projection.toughnessOf (SetBasePowerToughness.MkSetBasePowerToughness Nothing . Just)
      creature ref characteristic setting = do
        oid <- single (objectRefObjects legal resolving controller source gs ref)
        Monad.guard (Set.member oid (GameState.battlefield gs))
        Monad.guard (Projection.isCreatureOf oid gs)
        previous <- characteristic oid gs
        pure (previous, Just . setBase oid . setting . Quantity.Type.Literal)
      -- CR 611.2c: the one creature is frozen into the stored effect.
      setBase oid setting = State.modify' $ \g -> case Expiry.arm (Game.readingAcquisition resolving source) legal controller source duration g of
        Nothing -> g
        Just expiry ->
          let (ts, g1) = Game.freshTimestamp g
              eff =
                ContinuousEffect.MkContinuousEffect
                  { ContinuousEffect.source = source,
                    ContinuousEffect.timestamp = ts,
                    ContinuousEffect.expiry = expiry,
                    ContinuousEffect.modification = Modification.SetBasePowerToughness setting,
                    ContinuousEffect.affected = Affected.TheseObjects (Set.singleton oid)
                  }
           in g1 {GameState.continuousEffects = eff : GameState.continuousEffects g1}
  -- CR 608.2f's bracket, the ExchangeLifeTotals arm's: one exchange is one
  -- action.
  Monad.forM_ (side one) $ \(oneValue, oneWrite) ->
    Monad.forM_ (side other) $ \(otherValue, otherWrite) ->
      Monad.forM_ ((>>) <$> oneWrite otherValue <*> otherWrite oneValue) Event.simultaneously

-- CR 119.5: a DELTA per player against that player's own current total, so one
-- seat may gain while another loses. Through Event.changeLife rather than a raw
-- write to Player.life, for the sake of the log the rule describes.
--
-- Evaluated ONCE PER RECIPIENT, a card being able to name a number that is each
-- recipient's own (Biorhythm). Every evaluation and delta is read off `gs`, the
-- state before any life moves (CR 608.2f).
--
-- Each delta goes through changeLifeByDelta, which proposes a DOWNWARD one as a
-- life loss and an UPWARD one as a life gain, since rule 119.5 spells a lower
-- total as the player losing "the necessary amount of life" and a higher one as
-- their gaining it. Under a shared team total (Game.lifeSharers) that is CR
-- 810.9c's single player: their gain or loss moves the team's total.
--
-- Not implemented: CR 810.9d's team choosing the one member a "set each
-- player's life total" affects, so the team's total takes every named
-- member's delta (#4493).
setLifeTotal :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
setLifeTotal resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      recipients = playerRefPlayers legal resolving source controller gs ref
  -- CR 608.2f's bracket, the GainLife arm's: one instruction setting several
  -- players' totals is one event, however the per-seat deltas fall out.
  Event.simultaneously . Monad.forM_ recipients $ \pid ->
    -- A player with no row is nobody to move.
    Monad.forM_ (Map.lookup pid (GameState.players gs)) $ \player ->
      -- An undeterminable total is no instruction, asked per recipient: one
      -- seat's unanswerable count says nothing about the others.
      Monad.forM_ (Common.evaluateForRecipient viewOf context gs resolving source pid quantity) $ \total ->
        Common.changeLifeByDelta pid (total - Player.life player)

-- CR 104.3e: the players the reference names lose the game. IMMEDIATELY, as the
-- effect applies, which is the whole distinction from CR 104.3b-d -- those are
-- state-based actions and wait for the next priority, this is not. CR 104.3
-- lists all of them together and CR 104.5 attaches ONE consequence to every
-- one, so the departure afterwards is the road Parun.Engine.Sba's CR 704.5 pass
-- and CR 104.3a's concede already take rather than a second one.
--
-- ONE call over the whole set for CR 104.4a's sake: a seat-at-a-time loop would
-- settle the second-to-last departure as the last player's win instead of the
-- draw the rule states. APNAP (CR 608.2f) orders the departures, the Shuffle
-- arm's reason -- the order is a fact about the rules rather than about
-- PlayerId's Ord -- and apnapOrder is SEATING, so the survivors are filtered in
-- separately. A player an effect says can't lose the game is not named.
loseGame :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game ()
loseGame resolving source controller legal ref = do
  gs <- State.get
  let named = Set.fromList (filter (\pid -> not (PlayerEffect.precludes GameOutcome.Lose pid gs)) (playerRefPlayers legal resolving source controller gs ref))
      alive = Set.fromList (Game.stillPlaying gs)
  Departure.leaveGameTogether True Departure.Type.Lost (filter (\pid -> Set.member pid named && Set.member pid alive) (Game.apnapOrder gs))

-- CR 104.2b with CR 801.14: a player the reference names wins the game, which
-- is each of their opponents within their range losing it. Under an unlimited
-- range that is every opponent, and CR 104.2a then settles the win itself
-- (Departure.outcomeAfterLeaving). One departure set over every winner, the
-- LoseGame arm's reason.
--
-- Under an unlimited range a winner an effect says can't win the game wins
-- nothing, and an opponent who can't lose leaves all the same: the win ends
-- the game (CR 104.1), and the departure is only how parun spells it. Under a
-- limited one CR 104.3h makes the effect those opponents LOSING instead, so
-- nobody wins: a can't-lose effect stops it and a can't-win one does not.
-- Only those losses meet a loss replacement; Lich's Mirror's ruling gives it
-- no effect against a win.
winGame :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerRef -> Game ()
winGame resolving source controller legal ref = do
  gs <- State.get
  let limited winner = Maybe.isJust (RangeOfInfluence.rangeOf (GameSettings.rangeOfInfluence (GameState.settings gs)) winner)
      winners = filter (\pid -> pid `elem` Game.stillPlaying gs && (limited pid || not (PlayerEffect.precludes GameOutcome.Win pid gs))) (playerRefPlayers legal resolving source controller gs ref)
      losers = Set.fromList [pid | winner <- winners, pid <- Players.offer winner gs PlayerRelation.Opponent, not (limited winner && PlayerEffect.precludes GameOutcome.Lose pid gs)]
  Departure.leaveGameTogether (all limited winners) Departure.Type.Lost (filter (`Set.member` losers) (Game.apnapOrder gs))

-- CR 104.4c with CR 801.15: the game is a draw for the controller and each
-- player within their range, who leave it; everyone else plays on. Under an
-- unlimited range, or for CR 801.18's planar source, that is the whole
-- table, which CR 104.2a's settle then records as the draw.
drawGame :: ObjectId -> PlayerId -> Game ()
drawGame source controller = do
  gs <- State.get
  let drawn = Players.table (Plane.rangePerspective source controller gs) gs
  Departure.leaveGameTogether True Departure.Type.Drew (filter (`elem` drawn) (Game.apnapOrder gs))

-- CR 119.7 / 119.8: redistribute life totals, each new total being CR 119.5's
-- gain or loss of the necessary amount. The roster is CR 102.1's players IN the
-- game, not the keys of GameState.players, which keep a departed seat's row,
-- within the controller's range but for CR 801.18's planar source
-- (Plane.rangePerspective). That exemption is unobserved: The Doctor's Tomb,
-- the plane that redistributes, is not yet expressible (gap #5196).
-- Every total is read ONCE, before the prompt and before any life moves (CR
-- 608.2h); a rotation would otherwise leave two seats on one number.
--
-- FILTERED, NOT TRUSTED, all-or-nothing: only a whole permutation is a
-- legal answer, so a bad one falls back to redistributing among nobody.
--
-- Every total goes through changeLifeByDelta, the ExchangeLifeTotals arm's
-- road: rule 119.5's loss or gain, proposed so a replacement reaches it (CR
-- 614.1).
--
-- CR 119.7-8's own restrictions ride beside `isPermutation` below, both rules
-- saying a player "can't receive a new life total" that a "can't" forbids: an
-- assignment naming one is not a legal answer, so the existing all-or-nothing
-- filter is where it belongs. Parun.ZoneChangeSpec's RedistributeLifeTotals
-- group is the proof.
--
-- Not implemented: CR 810.9f's "not more than one member of each team"
-- (#4493).
redistributeLifeTotals :: ObjectId -> PlayerId -> Game ()
redistributeLifeTotals source controller = do
  gs <- State.get
  let candidates = Players.table (Plane.rangePerspective source controller gs) gs
      lifeOf pid = maybe 0 Player.life (Map.lookup pid (GameState.players gs))
      offered = fmap (\pid -> (pid, lifeOf pid)) candidates
  -- With one candidate or none every assignment is the same, so there is
  -- nothing to ask.
  Monad.when (length candidates > 1) $ do
    assignment <- Game.choose (Prompt.ChooseRedistribution (Decide.deciderFor controller gs) controller offered)
    let takers = Map.keysSet assignment
        givers = Set.fromList (Map.elems assignment)
        -- Set equality also settles injectivity: a repeated giver makes
        -- `givers` smaller than `takers`.
        isPermutation = Set.isSubsetOf takers (Set.fromList candidates) && takers == givers
        -- CR 119.7 / 119.8, read off the same pre-redistribution `gs` every
        -- total is: a taker whose new total would rise while they can't gain
        -- life, or fall while they can't lose it, is not a taker this
        -- permutation may name.
        reachable (taker, giver) = case compare (lifeOf giver) (lifeOf taker) of
          GT -> not (PlayerEffect.prohibitsGainingLife taker gs)
          LT -> not (PlayerEffect.prohibitsLosingLife taker gs)
          EQ -> True
    -- CR 608.2f's bracket, the ExchangeLifeTotals arm's: one redistribution is
    -- one action taken on every seat it names, so the whole permutation's gains
    -- and losses share one Parun.Types.EventGroup.
    Monad.when (isPermutation && all reachable (Map.toList assignment)) . Event.simultaneously . Monad.forM_ (Map.toList assignment) $ \(taker, giver) ->
      Common.changeLifeByDelta taker (lifeOf giver - lifeOf taker)

-- CR 702.179c: each named player's speed increases by this much. Its two
-- readings -- a player who HAS speed goes up, a player with NONE has their
-- speed BECOME the value -- are spelled separately, since DecreaseSpeed below
-- must not create a speed out of nothing. No cap, which is a PROJECT DECISION
-- and not a rule: nothing in rule 702.179 bounds speed from above, and nothing
-- permits exceeding 4 either, so parun rules that an effect may push past it.
-- Parun.Engine.Speed.maxSpeed carries the decision and CR 702.178a's side of it.
increaseSpeed :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerQuantity.PlayerQuantity -> Game ()
increaseSpeed resolving source controller legal (PlayerQuantity.MkPlayerQuantity ref quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      revving = playerRefPlayers legal resolving source controller gs ref
  Monad.forM_ revving $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid quantity of
      Just n
        | n > 0 ->
            let by :: Natural
                by = Integer.toNaturalSaturating n
                faster p = p {Player.speed = Just (maybe by (+ by) (Player.speed p))}
             in State.modify' (\g -> g {GameState.players = Map.adjust faster pid (GameState.players g)})
      _ -> pure ()

-- CR 702.179: speed drops by this much, never below the floor the CARD prints
-- (rule 702.179 states none). Not the mirror arm's negation: a player with NO
-- SPEED (CR 702.179b) stays that way, so the Maybe is traversed rather than
-- defaulted.
--
-- The REFERENCE reads the LEGAL slots, as every sibling arm does. CR 608.2b's
-- filter is judged once against the state resolution BEGAN in (Resolve's
-- legalSlot closes over that snapshot), so a permanent an earlier clause of
-- this same resolution moved is still in `legal` and CR 608.2h's last known
-- information answers for it -- Parun.ResolveSpec's "bob, who controlled the
-- bounced creature, went 20 -> 19" (Vapor Snag) is what proves it. This arm's
-- own board, Parun.SpeedSpec's "bob's 4 became 3", cannot tell the two maps
-- apart: Spikeshell Harrier targets once, so a target already illegal when the
-- trigger began resolving fizzles it (CR 608.2b) instead.
decreaseSpeed :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> SpeedDecrease.SpeedDecrease -> Game ()
decreaseSpeed resolving source controller legal d = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      slowing = playerRefPlayers legal resolving source controller gs (SpeedDecrease.player d)
      atLeast = toInteger (SpeedDecrease.floor d)
  Monad.forM_ slowing $ \pid ->
    case Common.evaluateForRecipient viewOf context gs resolving source pid (SpeedDecrease.quantity d) of
      Just n
        | n > 0 ->
            let slower p = p {Player.speed = fmap (\was -> Integer.toNaturalSaturating (max atLeast (toInteger was - n))) (Player.speed p)}
             in State.modify' (\g -> g {GameState.players = Map.adjust slower pid (GameState.players g)})
      _ -> pure ()

-- CR 701.21a: the players the slot names each sacrifice `quantity` permanents
-- matching the filter, and EACH OF THEM chooses which -- the whole difference
-- between this and Sacrifice above. CR 609.3: only a genuine surplus prompts.
--
-- CR 101.4's example is this instruction verbatim -- "Each player sacrifices a
-- creature. First, the active player chooses a creature they control. Then each
-- of the nonactive players, in turn order, chooses ... Then all creatures
-- chosen this way are sacrificed simultaneously" -- so every pick is taken
-- first, in APNAP order, and only then does anything leave the battlefield.
-- The candidate lists are read off ONE `gs` for the same reason.
playerSacrifices :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> PlayerSacrifices.PlayerSacrifices -> Game ()
playerSacrifices resolving source controller legal (PlayerSacrifices.MkPlayerSacrifices players filter_ quantity) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      -- Every player the reference names, in APNAP order.
      named = playerRefPlayers legal resolving source controller gs players
      victims = filter (\pid -> List.elem pid named) (Game.apnapOrder gs)
      -- `made` is every earlier victim's pick, which CR 101.4b lets a later
      -- victim know.
      pickFor made victim = fmap (made Seq.|>) $
        -- Read against the VICTIM: "half the permanents they control" is a
        -- number of the sacrificing player's own.
        case Common.evaluateForRecipient viewOf context gs resolving source victim quantity of
          Just n
            | n > 0 -> do
                -- Candidates are what the VICTIM controls, ascending, so both the
                -- elision and a short transcript are deterministic. Through
                -- Replacement.sacrificeCandidates, which is what puts CR 101.2's
                -- "can't be sacrificed" on this path: a prohibited permanent is
                -- never the pick that satisfies the edict. Framed by `source`,
                -- so Lord of the Pit's "a creature other than this creature"
                -- never offers the Lord itself.
                let candidates = Replacement.sacrificeCandidates (Filter.perspective context) (Binding.recipientsBySlot legal (slotBindings resolving gs)) victim (Just source) filter_ gs
                    decider = Decide.deciderFor victim gs
                    -- `n > 0` above, so the clamp never decides anything here.
                    count = Integer.toNaturalSaturating n
                picked <-
                  if Natural.length candidates <= count
                    then pure (Set.fromList candidates)
                    else Game.choose (Prompt.ChooseSacrifices decider victim source candidates count (fmap (Bifunctor.second Set.fromList) made))
                -- FILTERED AND COMPLETED, not merely filtered: an edict is not
                -- "may", so an answer naming too few would cheat it, and CR 609.3
                -- caps it at "as much as possible". Valid picks are honoured
                -- first, the rest made up from the remaining candidates in the
                -- order offered.
                let wanted = min count (Natural.length candidates)
                    valid = filter (\oid -> Set.member oid picked) candidates
                    filler = filter (\oid -> List.notElem oid valid) candidates
                -- CR 603.12 / 609.3: too few to sacrifice is an instruction
                -- that fell short, which Lich's "if you can't" reads.
                Monad.when (wanted < count) Common.fallShort
                pure (victim, List.genericTake wanted (valid <> filler))
          _ -> pure (victim, [])
  doomed <- fmap Foldable.toList (Monad.foldM pickFor Seq.empty victims)
  -- CR 101.4's "then the actions happen simultaneously", which its own Example
  -- writes out for this very instruction, so the picks from every seat go to the
  -- funnel as ONE batch against one board. Parun.EventSpec's Rishadan Cutpurse
  -- case is the proof, on three seats: a Rest in Peace sacrificed by one
  -- opponent still exiles what the other's pick would otherwise bury.
  Event.sacrificeAll (concatMap (\(victim, oids) -> fmap (\oid -> (victim, oid)) oids) doomed)

-- CR 701.38a: each player, starting with the seat the payload specifies and
-- proceeding in turn order, votes for one of the listed choices. What the
-- tally then binds is rule 701.38b's business and splits below -- the objects
-- tied for most votes at one slot (Council's Judgment's exile), or one tally
-- per word for the clause each word is connected to (Plea for Power).
--
-- An object vote's listed choices are swept ONCE, off the board as the vote
-- begins, so every voter chooses from the same list -- rule 701.38a votes "for
-- one choice from a list", singular -- less what lies outside their own range
-- (CR 801.5a). Through battlefieldMatching, so the sweep
-- reads the projection and a permanent that is a copy of something is judged
-- by the characteristics it copied.
--
-- Nothing on the board changes while the seats vote, so the decider, the
-- candidate list and rule 701.38d's ballot counts are all read off this one
-- `gs`.
vote :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Vote.Vote -> Game ()
vote resolving source controller legal (Vote.MkVote starter choices secret) = do
  gs <- State.get
  let -- Rule 701.38a's "specified player". A reference naming several names the
      -- first in PlayerId order, and one naming nobody falls back to CR 109.5's
      -- "you" -- which is the starter every printing in the pool states anyway.
      begin = case playerRefPlayers legal resolving source controller gs starter of
        pid : _ -> pid
        [] -> controller
      -- turnOrderFrom answers the SEATING roster (CR 800.5), so stillPlaying
      -- is what keeps a departed seat from being asked to vote. Within the
      -- controller's range (CR 801.10), every seat for a planar source (CR
      -- 801.18): Parun.PlanechaseSpec's "Prime Minister's Cabinet Room's vote
      -- is cast by a player outside" proves it.
      voters = filter (\pid -> List.elem pid (Players.table (Plane.rangePerspective source controller gs) gs)) (Game.turnOrderFrom begin gs)
      -- CR 701.38d: a seat given extra votes casts them ALL here, before the
      -- next seat votes -- "at the same time the player would otherwise have
      -- voted" (Brago's Representative). Each is its own prompt: that card's
      -- reminder text has the votes go to different choices or the same one, so
      -- nothing lets the engine answer the second from the first.
      --
      -- The votes a grant only OFFERS (Ballot Broker's "you may vote an
      -- additional time") come after the seat's own, each grant's "may" asked on
      -- its own and its ballots cast at once, still before the next seat votes.
      ballotsOf ask voter = do
        own <- Monad.replicateM (Natural.toIntSaturating (PlayerEffect.votesAllowed voter gs)) (ask voter)
        offered <- Monad.forM [(grant, grantEffect, count) | (grant, grantEffect@(PlayerEffect.Type.AdditionalVotes (ExtraVotes.Optional count))) <- PlayerEffect.offeredExtras voter gs] $ \(grant, grantEffect, count) -> do
          answer <- Game.choose (Prompt.OfferedExtra (Decide.deciderFor voter gs) voter grant grantEffect)
          case answer of
            OptionalDecision.Exercises -> Monad.replicateM (Natural.toIntSaturating count) (ask voter)
            OptionalDecision.Declines -> pure []
        pure (own <> concat offered)
      -- Through Game.chooseAmong, rule 701.38a stating no way to abstain.
      ballotAmong = Game.chooseAmong (\decider who -> Prompt.ChooseVote decider who resolving)
      -- Each ballot is logged as it is cast, an object snapshotted as it is
      -- voted for, and a secret vote's are revealed together once the last
      -- is in, in voting order.
      cast ask = do
        let logged voter = do
              picked <- ask voter
              let ballot = fmap (Ballot.MkBallot voter) (picked >>= traverse (`Projection.objectSnapshot` gs))
              Monad.forM_ ballot (Common.logBallot secret)
              pure (picked, ballot)
        ballots <- fmap concat (Monad.forM voters (ballotsOf logged))
        Monad.when secret (State.modify' (Event.recordEvent (GameEvent.VotesRevealed (Seq.fromList (Maybe.mapMaybe snd ballots)))))
        pure (fmap fst ballots)
  case choices of
    VoteChoices.Objects objects -> do
      let candidates = battlefieldMatching legal resolving controller source gs (VoteObjects.filter objects)
          grants = Projection.controlGrants gs
          -- CR 801.5a: each voter's share of the list is what lies in their
          -- own range as well, a voter left with none casting no ballot (CR
          -- 101.3).
          candidatesFor voter = filter (\oid -> all (\you -> Projection.objectInRangeGiven grants you oid gs) (Plane.rangePerspective source voter gs)) candidates
      case candidates of
        -- CR 101.3: an empty list of choices, so nobody votes and nothing is bound.
        [] -> pure ()
        _ : _ -> do
          ballots <- cast $ \voter -> ballotAmong voter (fmap BallotChoice.ForObject (candidatesFor voter))
          let tallyOf oid = List.length (filter (== Just (BallotChoice.ForObject oid)) ballots)
              best = List.maximum (0 : fmap tallyOf candidates)
              -- Every candidate on the winning tally, and none at all where nobody
              -- voted. Rule 701.38a's vote determines "some aspect of the effect",
              -- and the aspect this arm determines is which objects the slot names.
              winners = if best <= 0 then [] else filter (\oid -> tallyOf oid == best) candidates
          State.modify' (Common.bindObjectsSlot resolving (VoteObjects.slot objects) (Seq.fromList winners))
    -- CR 701.38b's words. No sweep and no empty case: the listed choices are
    -- printed on the card, so the list cannot come up empty the way a
    -- battlefield sweep can.
    VoteChoices.Words voteWords -> do
      let offered = fmap BallotChoice.ForWord (NonEmpty.toList voteWords)
      ballots <- cast (`ballotAmong` offered)
      -- The aspect rule 701.38a's vote determines here is a NUMBER per word,
      -- bound on the SOURCE as Effect.FlipCoin's tallies are, for the clause
      -- rule 701.38b connects to that word to read as Quantity.InSlot.
      --
      -- Every word, including the ones nobody voted for: Plea for Power's "if
      -- knowledge gets more votes or the vote is tied" compares the two tallies,
      -- and an absent slot would read as no answer rather than as zero.
      --
      -- Rule 701.38a's tie-break is arithmetic and not an outcome of its own,
      -- which is why no tie is recorded anywhere.
      Foldable.for_ voteWords $ \word ->
        State.modify' (Common.bindAmountSlot resolving source word (Natural.length (filter (== Just (BallotChoice.ForWord word)) ballots)))
    -- CR 701.38b's players: every player still in the game, less the voter
    -- for Mob Verdict's "another player". A voter left with no candidate casts
    -- no ballot, Objects' CR 101.3 answer.
    --
    -- CR 801.5a: within the voter's range as well as the controller's,
    -- neither applying to a planar source (CR 801.18).
    --
    -- The tally keys every candidate, zeros included, and is bound on the
    -- resolving object, where effectContext's slotVotes reads it.
    VoteChoices.Players (VotePlayers.MkVotePlayers another slot) -> do
      let table = Players.table (Plane.rangePerspective source controller gs) gs
          candidatesFor voter = filter (\pid -> not (another && pid == voter) && List.elem pid (Players.table (Plane.rangePerspective source voter gs) gs)) table
      picks <- cast $ \voter -> ballotAmong voter (fmap BallotChoice.ForPlayer (candidatesFor voter))
      let tally = Map.fromList (fmap (\pid -> (pid, Natural.length (filter (== Just (BallotChoice.ForPlayer pid)) picks))) (concatMap candidatesFor voters))
      State.modify' (Common.overHolderBindings resolving (Map.insert slot (Binding.toVotes tally)))

-- CR 608.2d: CR 109.5's "you" holds the opening bid, then each other seat in
-- turn order may top the high bid, round after round, until every seat but
-- the high bidder has declined to top it (Pain's Reward's ruling), so a seat
-- that passed may top a later bid. The bidders are the seats still playing
-- within the controller's range (CR 801.10), Vote's roster.
--
-- A bid is a number with no ceiling: Illicit Auction's ruling has the high
-- bidder LOSE that much life rather than pay it, so a bid past the bidder's
-- life total is legal. Through Prompt.ChooseNumber with the high bid as its
-- floor; an answer at or below it declines to top it.
--
-- Nothing on the board changes while the seats bid, so the roster and the
-- deciders are read off this one `gs`.
bid :: ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Bid.Bid -> Game ()
bid resolving source controller legal (Bid.MkBid opening highBidSlot highBidderSlot) = do
  gs <- State.get
  let viewOf = effectViewOf source legal gs
      context = effectContext gs resolving controller source legal (slotBindings resolving gs)
      start = maybe 0 Integer.toNaturalSaturating (Quantity.evaluateFor viewOf context gs resolving source opening)
      bidders = filter (\pid -> List.elem pid (Players.table (Plane.rangePerspective source controller gs) gs)) (Game.turnOrderFrom controller gs)
      -- The seats after `holder` in turn order, wrapping, `holder` left out.
      after holder = case List.break (== holder) bidders of
        (before, _ : rest) -> rest <> before
        (before, []) -> before
      -- `waiting` are the seats still to be asked since the last bid; the
      -- bidding ends when none is left.
      auction high holder waiting = case waiting of
        [] -> pure (high, holder)
        bidder : rest -> do
          answer <- Game.choose (Prompt.ChooseNumber (Decide.deciderFor bidder gs) bidder resolving high Nothing)
          if answer > high
            then auction answer bidder (after bidder)
            else auction high holder rest
  (high, winner) <- auction start controller (after controller)
  State.modify' (Common.bindAmountSlot resolving source highBidSlot high)
  State.modify' (Common.bindPlayerSlot resolving highBidderSlot (Set.singleton winner))
