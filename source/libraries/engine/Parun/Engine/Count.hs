-- CR 613 / CR 608.2h: the one place a Parun.Types.Count is interpreted. A pure
-- fold -- enumerate the scope, keep by the Filter, aggregate -- that never
-- learns which effect or card produced the count.
--
-- Parameterized by the view builder AND by the per-member quantity reader
-- rather than importing Parun.Engine.Projection or Parun.Engine.Quantity, both of
-- which sit above this module and call into the layer fold. The caller supplies
-- characteristics as of whatever layers it has already applied, which is what
-- lets a count read the projection without the module cycle or the recursion.
module Parun.Engine.Count where

import qualified Control.Monad as Monad
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Engine.AbilityZone as AbilityZone
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Deploy as Deploy
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Loyalty as Loyalty
import qualified Parun.Engine.ManaAbility as ManaAbility
import qualified Parun.Engine.Players as Players
import qualified Parun.Engine.Sector as Sector
import qualified Parun.Engine.Subtype as Subtype
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlocksDeclared as BlocksDeclared
import qualified Parun.Types.BoundReading as BoundReading
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardArrivedIn as CardArrivedIn
import qualified Parun.Types.Combat as Combat
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.ControlMargin as ControlMargin
import qualified Parun.Types.Convoking as Convoking
import qualified Parun.Types.Count as Count.Type
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Crewing as Crewing
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.DistinctOf as DistinctOf
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameSettings as GameSettings
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LeftTheGame as LeftTheGame
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.LoyaltyKind as LoyaltyKind
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Milled as Milled
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.MovedBetween as MovedBetween
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Types.PastActivation as PastActivation
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.Saddling as Saddling
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.Trait as Trait
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

-- The characteristics of a candidate, as of the layers the CALLER has already
-- applied. Nothing when the candidate has no view -- an unknown id, or an
-- object the caller's bound projection cannot describe.
type ViewOf = ObjectId -> Maybe Filter.View

-- Reads a per-member quantity off one candidate. INJECTED for the same
-- module-cycle reason ViewOf is: Parun.Engine.Quantity imports this module and
-- ties the knot at its own Count arm. Only Aggregation.Greatest and
-- Aggregation.Total read it; the others ignore it.
--
-- BOTH the candidate's object and its view, because an InHistory candidate has
-- only the second: its view is a CR 608.2h snapshot of a past event, so a
-- reader demanding an object could never answer one. For an InZone
-- candidate the view IS `viewOf` of the id beside it, so the two agree.
type QuantityOf quantity = Maybe ObjectId -> Filter.View -> quantity -> Maybe Integer

-- Nothing when the count cannot be determined -- an unresolvable PlayerRef, a
-- maximum over a set that is empty or holds a member with no value
-- (Aggregation.Greatest), or a sum over a set holding one (Aggregation.Total).
-- It propagates, which is what every caller but one wants: CR 208.2a's substituted 0 is a different rule, scoped to a
-- characteristic-defining ability and applied by
-- Parun.Engine.Quantity.determine.
evaluate :: ViewOf -> QuantityOf quantity -> Filter.Context -> GameState -> Count.Type.Count quantity -> Maybe Integer
evaluate viewOf quantityOf context gs count =
  let predicate = Count.Type.filter count
      aggregation = Count.Type.aggregation count
   in case Count.Type.scope count of
        Scope.InZone (InZone.MkInZone zone ref) -> do
          pids <- playersFor viewOf context gs ref
          let ids = concatMap (\pid -> Game.zoneMembers zone pid gs) pids
              kept = Maybe.mapMaybe (\oid -> fmap ((,) (Just oid)) (keep predicate context (viewOf oid))) ids
          aggregate quantityOf aggregation kept
        -- CR 608.2i: the event log. Views of the object that MOVED come from each
        -- event's stored snapshot (CR 608.2h last-known information), never from a
        -- live object -- a token has no printed card at all (CR 111.3) and an
        -- animated land died as a creature. The shape whose unit is the CARD that
        -- ARRIVED reads the arriving object instead (see the CardArrived arm), which is why
        -- the fold hands snapshotView the same reader the zone arm uses.
        --
        -- SpellCastThisGame's window reaches back past the log to the earlier
        -- turns' casts, which GameState.castsBeforeThisTurn keeps as the same
        -- record the log's SpellCast entries carry.
        Scope.InHistory shape ->
          let logged = fmap LoggedEvent.event (Foldable.toList (GameState.events gs))
              earlier = case shape of
                EventShape.SpellCastThisGame -> fmap GameEvent.SpellCast (Foldable.toList (GameState.castsBeforeThisTurn gs))
                EventShape.SpellCast -> []
                EventShape.MovedBetween {} -> []
                EventShape.MovedFrom {} -> []
                EventShape.CardArrivedIn {} -> []
              views = Maybe.mapMaybe (snapshotView viewOf gs shape) (earlier <> logged)
              kept = fmap ((,) Nothing) (Maybe.mapMaybe (keep predicate context . Just) views)
           in aggregate quantityOf aggregation kept
        -- CR 102.1: the players themselves. Candidates come from the same
        -- playersFor the zone arm indexes by, so CR 800.4a's departed seat is
        -- uncountable here without a second reading of who is in the game -- and
        -- unlike there, that IS observable: a departed player's zones were emptied,
        -- so naming them cost nothing, while naming the player costs one.
        --
        -- Each candidate is seen through playerView below rather than through the
        -- injected ViewOf, which answers about OBJECTS (CR 109.1) and has no id to
        -- be asked with here. So the members are objectless, as InHistory's are, and
        -- an Aggregation.Greatest over this scope folds a per-OBJECT quantity against
        -- a player, which CR 208.1 and CR 202.3 give no answer to.
        --
        -- A per-PLAYER quantity DOES answer, and reaches the candidate through that
        -- same view: it records the player's identity, and
        -- Parun.Types.PlayerRef.Candidate is what a card writes to read it -- Malignus'
        -- "the highest life total among your opponents". So nothing here carries the
        -- candidate beside the view: the view already names it.
        Scope.OverPlayers ref -> do
          pids <- playersFor viewOf context gs ref
          -- The predicate is baked PER CANDIDATE (see bakePerspective): CR 110.2's
          -- comparison is answered here, where the board is, and the match below is the
          -- same pure one every other scope makes.
          --
          -- playerView rather than Filter.playerView is a REGRESSION FENCE on this road
          -- and a proof on the other: routing the fold through the board-aware builder
          -- leaves the suite green, no card spelling Filter.DealtDamageThisTurn under a
          -- count over players -- Quantity.PlayersDealtDamageThisTurn is how a card asks
          -- that (#1577). The target road, which Parun.DamageSpec's Needle Drop case
          -- covers, is what pays for the builder.
          let kept = fmap ((,) Nothing) (Maybe.mapMaybe (\pid -> keep (bakePerspective viewOf context gs pid predicate) context (Just (playerView gs pid))) pids)
          aggregate quantityOf aggregation kept
        -- CR 400.7j: the objects one of the surrounding announcement's slots names,
        -- wherever they wound up. The one scope whose candidates come from the
        -- resolution's bindings rather than from the board, which is what lets it
        -- follow a CR 614 redirect that moved them out of the zone the effect aimed
        -- them at: Psychic Miasma's "if a land card is discarded this way" asked
        -- under Rest in Peace.
        --
        -- Candidates are LIVE objects, so the injected ViewOf answers them exactly as
        -- it answers the zone arm's -- and the two agree on any candidate they share,
        -- since Filter.IsBound over a zone fold reaches the same ids.
        --
        -- A card discarded unrevealed into a hidden zone is still discarded (CR
        -- 701.9c; Library of Leng's 2004-10-04 rulings), and only its
        -- characteristics are undefined, so a plain count asking nothing of them
        -- (countsWithoutCharacteristics) keeps it: Flux's and Jace's Archivist's
        -- "discarded this way" under Library of Leng (data/scenarios'
        -- windfall-counts-the-cards-library-of-leng-put-on-top).
        --
        -- BoundReading.BeforeMove swaps each arrival for the id it departed as,
        -- found by nothing, so read by CR 608.2h last known information:
        -- Flood of Tears' "nontoken permanents you control" returned to a hand,
        -- whatever zone a CR 614 redirect put one in instead (its 2019-07-12
        -- ruling). A member no move arrived as is already its own departure.
        Scope.OverBound reading slot ->
          let bound = Set.toList (Map.findWithDefault Set.empty slot (Filter.slotObjects context))
              ids = case reading of
                BoundReading.AsBound -> bound
                BoundReading.BeforeMove -> fmap (\oid -> Maybe.fromMaybe oid (departedAs gs oid)) bound
              member oid
                | findableAfterMove gs oid = True
                | otherwise = countsWithoutCharacteristics aggregation predicate && wasDiscarded gs oid
              kept = Maybe.mapMaybe (\oid -> if member oid then fmap ((,) (Just oid)) (keep predicate context (viewOf oid)) else Nothing) ids
           in aggregate quantityOf aggregation kept
        -- CR 401.2 / 404.1: one card per named library or graveyard, narrowed by
        -- POSITION before the Filter is asked -- the zone arm above answers "any
        -- matching card" instead. Order-insensitive like every Aggregation, so no
        -- APNAP walk. An empty library has no top card, so Vampire Nocturnus'
        -- "is black" counts nothing.
        Scope.TopOf (InZone.MkInZone zone ref) -> do
          pids <- playersFor viewOf context gs ref
          let ids = Maybe.mapMaybe (\pid -> Game.topOf zone pid gs) pids
              kept = Maybe.mapMaybe (\oid -> fmap ((,) (Just oid)) (keep predicate context (viewOf oid))) ids
          aggregate quantityOf aggregation kept

-- CR 400.7j / CR 400.2: may a later part of the effect that moved this object
-- FIND it? Where it landed in a public zone, which is what Game.isHiddenZone
-- classifies, or where it was REVEALED on the way into a hidden one. CR 701.9c
-- undefines a discarded card's characteristics only when it reaches the hidden
-- zone "without being revealed", so a revealed redirect leaves every Filter an
-- honest answer and an unrevealed one leaves none.
--
-- The reveal is read off the log: Parun.Engine.Event.apply's ZoneChangeR arm
-- reveals the DEPARTING id (CR 701.20a, shown in the zone it leaves), and the
-- Moved entry the same change records pairs that id with the incarnation the
-- binding holds, so the two are joined through Moved rather than by id.
--
-- All three legs are proven in Parun.ZoneChangeSpec's Psychic Miasma cases:
-- under Rest in Peace the discarded land is read out of exile, and under Wheel
-- of Sun and Moon it is revealed on its way to the bottom of the discarding
-- player's library, so the spell returns in both; under Library of Leng it goes
-- to the top of that library unrevealed, and the spell does not.
--
findableAfterMove :: GameState -> ObjectId -> Bool
findableAfterMove gs oid = case Game.lookupObject oid gs of
  -- The id is the one that DEPARTED, which is the shape a slot bound before the
  -- move has -- Hour of Glory's "if that creature was a God", read off the
  -- target slot after the first clause exiled it, and Soulblast's and
  -- Shadowgrange Archfiend's sacrificed creatures. Nothing is FOUND here, so CR
  -- 400.7j has no say: the caller reads the departed object's last known
  -- information, which CR 608.2h gives wherever it went, a hidden zone included.
  -- data/scenarios' Gravebane Zombie cases, which a CR 614 replacement puts on
  -- top of its owner's library, are the proof.
  Nothing -> True
  Just _ -> arrivedFindable gs oid

-- CR 701.9a: did a discard put this incarnation where it is? Event.discard
-- records the id its move minted, which is the id a discard's slot binds.
wasDiscarded :: GameState -> ObjectId -> Bool
wasDiscarded gs oid =
  let discarded event = case event of
        GameEvent.Discarded d -> Discarded.card d == oid
        _ -> False
   in any (discarded . LoggedEvent.event) (GameState.events gs)

-- CR 701.9c / 109.3: does this count ask nothing of its members' characteristics,
-- so that a member whose characteristics are undefined still answers it? A tally
-- of members narrowed by identity and ownership alone (CR 108.3: an owner is not
-- a characteristic). Any other atom answers False, keeping CR 400.7j's gate --
-- Psychic Miasma's "a land card" among them.
countsWithoutCharacteristics :: Aggregation.Aggregation quantity -> Filter.Type.Filter keyword -> Bool
countsWithoutCharacteristics aggregation predicate =
  let identityOnly f = case f of
        Filter.Type.And fs -> all identityOnly fs
        Filter.Type.Or fs -> all identityOnly fs
        Filter.Type.Not g -> identityOnly g
        Filter.Type.HeldByRecipient Holder.Owner -> True
        Filter.Type.HeldByBound Holder.Owner _ -> True
        Filter.Type.HeldByPlayer Holder.Owner _ -> True
        Filter.Type.HeldBy Holder.Owner _ -> True
        Filter.Type.IsBound _ -> True
        Filter.Type.IsObject _ -> True
        _ -> False
   in case aggregation of
        Aggregation.Members -> identityOnly predicate
        _ -> False

-- The arm above's public-zone question about an id that IS live: a binding that
-- holds the arrival.
arrivedFindable :: GameState -> ObjectId -> Bool
arrivedFindable gs oid = case Game.lookupObject oid gs of
  Nothing -> False
  Just object -> not (Game.isHiddenZone (Object.zone object)) || revealedArriving gs oid || revealedInPlace gs oid

-- Was this incarnation revealed where it lies (CR 701.20a)? A reveal moves
-- nothing, so the slot binds the live id: Diviner's Lockbox's top card
-- (data/scenarios' diviners-lockbox cases).
revealedInPlace :: GameState -> ObjectId -> Bool
revealedInPlace gs oid =
  let revealed event = case LoggedEvent.event event of
        GameEvent.Revealed r -> Revealed.card r == oid
        _ -> False
   in any revealed (GameState.events gs)

-- Was the card revealed as it left the zone this incarnation arrived from?
-- The Moved entry naming this id as its arrival gives the departed id; a
-- Revealed entry naming that id is the reveal (CR 701.20a).
revealedArriving :: GameState -> ObjectId -> Bool
revealedArriving gs oid =
  let departed = departedAs gs oid
      revealed event = case LoggedEvent.event event of
        GameEvent.Revealed r -> Just (Revealed.card r) == departed
        _ -> False
   in any revealed (GameState.events gs)

-- CR 400.7: the id this incarnation had before the move that made it, off the
-- Moved entry naming it as an arrival; Nothing if no move this turn made it.
departedAs :: GameState -> ObjectId -> Maybe ObjectId
departedAs gs oid =
  let departure event = case LoggedEvent.event event of
        GameEvent.Moved m | Foldable.elem oid (Moved.arrivals m) -> Just (ZoneChange.departed (Moved.change m))
        _ -> Nothing
   in Maybe.listToMaybe (Maybe.mapMaybe departure (Foldable.toList (GameState.events gs)))

-- CR 109.1 / 120.1: THE player candidate's view -- Parun.Engine.Filter.playerView
-- with the one field a bare PlayerId cannot answer filled from the board.
-- Parun.Engine.Projection.View.viewOfCharacteristics fills Filter.dealtDamageThisTurn
-- for an object off Game.damagedObject; this is its player half, off
-- Game.wasDealtDamageThisTurn, so CR 120.1's four recipients are read back
-- through one event reader (#2157).
--
-- Here rather than in Parun.Engine.Filter, which holds no game state, and here
-- rather than in Parun.Engine.Projection, which sits above this module: the two
-- callers are the Scope.OverPlayers fold above and
-- Parun.Engine.Target.admittedGiven's Recipient.ToPlayer arm, so this is the
-- lowest module both can see. Every other field stays as Filter.playerView
-- leaves it, and each says there why.
--
-- A BOARD-SHAPED atom still baked rather than filled: bakePerspective below
-- rewrites the three that ask about a zone or a comparison, because none of them
-- is a characteristic of the candidate. This one is -- "was dealt damage this
-- turn" is asked of the candidate itself -- which is why it rides the view and
-- so answers on the target path too, where nothing bakes.
playerView :: GameState -> PlayerId -> Filter.View
playerView gs pid =
  (Filter.playerView pid)
    { Filter.dealtDamageThisTurn = Game.wasDealtDamageThisTurn Nothing gs pid,
      -- CR 508.3b: the same division, one record over -- a player IS one of that
      -- rule's three subjects, and Parun.Engine.Filter.playerView holds no combat
      -- record to read the answer from.
      Filter.declaredAttackedThisCombat =
        Set.member (AttackTarget.OfPlayer pid) (Combat.declaredAttacked (GameState.combat gs))
    }

-- CR 109.1: does a player Filter match this player? The Scope.OverPlayers
-- fold's match, one candidate at a time, for a reference that narrows players
-- rather than counting them (ObjectRef.Players, Disorder).
playerMatches :: ViewOf -> Filter.Context -> GameState -> Filter.Type.Filter Keyword.Type.Keyword -> PlayerId -> Bool
playerMatches viewOf context gs predicate pid =
  Filter.matches context (playerView gs pid) (bakePerspective viewOf context gs pid predicate)

-- CR 110.2 / 109.5: answer every perspective-reframing atom in a predicate
-- against ONE candidate player, rewriting each to a trivially true or trivially
-- false predicate so the match itself stays the pure fold Parun.Engine.Filter
-- performs. That module cannot answer the atom: it holds no game state, and
-- "controls more lands than you" is a question about the board rather than about
-- the candidate. This is Filter.bakeBound's shape, with a board where that one has
-- a binding map.
--
-- The candidate is held as "you" for the INNER count only; the outer context rides
-- through unchanged, so a nested atom reading the perspective still reads the real
-- one. That is the asymmetry the whole atom exists for.
--
-- Exhaustive rather than a catch-all, bakeBound's posture: a later atom that must
-- be answered against the board has to fail to compile here rather than silently
-- go unbaked and answer False.
bakePerspective :: ViewOf -> Filter.Context -> GameState -> PlayerId -> Filter.Type.Filter Keyword.Type.Keyword -> Filter.Type.Filter Keyword.Type.Keyword
bakePerspective viewOf context gs candidate predicate =
  let recur = bakePerspective viewOf context gs candidate
   in case predicate of
        -- At least the margin outright, or at least that many more than "you",
        -- which is False when no perspective frames the match (CR 109.5) -- the
        -- vacuous posture every player-referencing atom takes.
        Filter.Type.Controls margin inner ->
          let theirs = controlledMatching viewOf context gs inner candidate
              yours = fmap (controlledMatching viewOf context gs inner) (Filter.perspective context)
           in truth $ case margin of
                ControlMargin.AtLeast n -> theirs >= toInteger n
                ControlMargin.MoreThanYou n -> maybe False (\mine -> theirs >= mine + toInteger n) yours
        -- CR 108.4 / 608.2h: is this candidate the player who controls the object the
        -- slot names? Baked here for Controls' reason -- projecting a
        -- controller is a question about the board -- and off the same view the fold
        -- reads everything else through, which is what carries CR 608.2h in: the caller
        -- that has already moved the object supplies a last-known-aware view, and
        -- Parun.Engine.Filter.View.controller then answers for a permanent that is gone.
        --
        -- False when the slot names no object or the view cannot describe it, the
        -- vacuous posture above: an unanswerable atom admits no candidate rather than
        -- admitting every one.
        Filter.Type.IsControllerOfBound slot ->
          truth (Just candidate == (Filter.slotOneObject slot context >>= viewOf >>= Filter.controller))
        -- CR 400.1 / 404.1: how big is THIS candidate's graveyard? Baked here for the
        -- two atoms above's reason, one rule further out -- the question is about a
        -- ZONE rather than about the candidate's characteristics, and
        -- Parun.Engine.Filter holds no game state to size one with.
        --
        -- OWNER-SLICED, which is right here where it is wrong for the battlefield
        -- (see #161): rule 400.1 gives each player their own graveyard and CR 404.1 puts
        -- an object on top of its OWNER's, so Game.zoneMembers asks exactly the rule's
        -- question rather than approximating it, and the projected control
        -- controlledMatching below reads has nothing to say about a card in a
        -- graveyard. CR 608.2h fixes the moment: the answer is determined once, as the
        -- effect is applied, which is when this fold runs.
        Filter.Type.CardsInGraveyardAtLeast n ->
          truth (toInteger (length (Game.zoneMembers Zone.Graveyard candidate gs)) >= toInteger n)
        Filter.Type.And fs -> Filter.Type.And (fmap recur fs)
        Filter.Type.Or fs -> Filter.Type.Or (fmap recur fs)
        Filter.Type.Not f -> Filter.Type.Not (recur f)
        Filter.Type.Unwritten f -> Filter.Type.Unwritten (recur f)
        Filter.Type.HasCardType _ -> predicate
        Filter.Type.HasSupertype _ -> predicate
        Filter.Type.HasColor _ -> predicate
        Filter.Type.Shares _ _ -> predicate
        Filter.Type.HasSubtype _ -> predicate
        Filter.Type.HasName _ -> predicate
        Filter.Type.NameWordsAtLeast _ -> predicate
        Filter.Type.HasNameOriginallyPrintedIn _ -> predicate
        Filter.Type.HasKeyword _ -> predicate
        Filter.Type.HasKeywordFamily _ -> predicate
        Filter.Type.Measures _ -> predicate
        Filter.Type.ManaValueIsEven -> predicate
        Filter.Type.ControllerIsOwner -> predicate
        Filter.Type.HeldBy _ _ -> predicate
        Filter.Type.ControlledByRole _ -> predicate
        Filter.Type.HeldByBound _ _ -> predicate
        Filter.Type.HeldByPlayer _ _ -> predicate
        Filter.Type.HeldByRecipient _ -> predicate
        Filter.Type.IsSource -> predicate
        Filter.Type.IsObject _ -> predicate
        Filter.Type.TargetsSource -> predicate
        Filter.Type.HasSingleTarget -> predicate
        -- NOT descended into, for the reason AttachedTo below is not: `candidate` here
        -- is a PLAYER, and CR 115.1 puts no player on the stack, so
        -- Parun.Engine.Filter answers this atom False for a player candidate whatever
        -- the nest says and never evaluates it.
        Filter.Type.TargetsOnlyOne _ -> predicate
        -- Not descended into for the atom above's reason.
        Filter.Type.TargetsMatching _ -> predicate
        Filter.Type.TargetsPlayer _ -> predicate
        Filter.Type.IsBound _ -> predicate
        Filter.Type.IsTarget -> predicate
        Filter.Type.ControllerRelatesToBound _ _ -> predicate
        Filter.Type.SameControllerAsHostOfBound _ -> predicate
        Filter.Type.HasChosenName {} -> predicate
        Filter.Type.HasChosenColor -> predicate
        Filter.Type.HasChosenSubtype -> predicate
        Filter.Type.IsExiledWithSource _ -> predicate
        Filter.Type.IsLastExiledWithSource -> predicate
        Filter.Type.OfChosenPlayer -> predicate
        Filter.Type.OfRelatedPlayer _ -> predicate
        Filter.Type.IsPlayer _ -> predicate
        Filter.Type.IsAttacking -> predicate
        -- Untouched for HeldBy's reason: the relation is answered against the
        -- perspective at Parun.Engine.Filter.matches, which holds one.
        Filter.Type.IsAttackingPlayer _ -> predicate
        -- Untouched for the atom above's reason.
        Filter.Type.IsAttackingPlaneswalker _ -> predicate
        -- Untouched for the two atoms above's reason.
        Filter.Type.IsAttackingBattle _ -> predicate
        Filter.Type.DeclaredAttackedThisCombat -> predicate
        Filter.Type.IsBlocking -> predicate
        Filter.Type.HasBlockStatus _ -> predicate
        Filter.Type.DeclaredThisTurn _ -> predicate
        Filter.Type.CouldAttackThisTurn -> predicate
        Filter.Type.DeclaredAttackerThisCombat -> predicate
        Filter.Type.DeclaredBlockerThisCombat -> predicate
        Filter.Type.MilledThisTurn -> predicate
        Filter.Type.CantCrewVehicles -> predicate
        Filter.Type.DealtDamageThisTurn -> predicate
        Filter.Type.DealtDamageTo _ -> predicate
        Filter.Type.EnteredThisTurn _ -> predicate
        Filter.Type.CrewedSourceThisTurn -> predicate
        Filter.Type.ConvokedSourceThisTurn -> predicate
        Filter.Type.SaddledSourceThisTurn -> predicate
        Filter.Type.ControlledSinceTurnBegan -> predicate
        -- NOT descended into, unlike And/Or/Not above, and that is the load-bearing
        -- call rather than an omission: `candidate` here is a PLAYER (the sole caller
        -- folds this over playerView), and CR 303.4b makes a player enchanted by
        -- an Aura rather than attached to one, so Parun.Engine.Filter answers this atom
        -- False for a player candidate whatever the nest says and never evaluates it.
        -- Baking the nest against this candidate would bake a question about the HOST
        -- against a player who is not it.
        Filter.Type.AttachedTo _ -> predicate
        -- CR 303.4b / 301.5a: something the nested Filter admits is attached TO this
        -- PLAYER candidate. Baked here for CardsInGraveyardAtLeast's reason -- CR
        -- 109.3 keeps attachment off the characteristics, so this is a board
        -- question rather than one `viewOf` can answer -- and swept the same way
        -- Parun.Engine.Projection's attachedViews sweeps for an object: parun stores
        -- the attachment on the ATTACHED permanent, so there is nothing to index
        -- from this side.
        Filter.Type.HasAttached f ->
          truth (any (\view -> Filter.matches context view f) (Maybe.mapMaybe viewOf (attachersOfPlayer gs candidate)))
        Filter.Type.IsAttachedTo _ -> predicate
        Filter.Type.IsEvaluated -> predicate
        Filter.Type.IsHostOfSource -> predicate
        Filter.Type.EnteredWithSource -> predicate
        Filter.Type.AttachedNoLaterThanSource -> predicate
        Filter.Type.CanHostSubject -> predicate
        Filter.Type.CanAttachToSubject -> predicate
        Filter.Type.HostOfSubjectHasCardType _ -> predicate
        Filter.Type.IsCommander -> predicate
        Filter.Type.IsToken -> predicate
        Filter.Type.IsActivatedAbility _ -> predicate
        Filter.Type.IsAbility -> predicate
        Filter.Type.IsEmblem -> predicate
        -- NOT descended into, RepresentedByCard's reason below: CR 113.7's subject is
        -- an ability on the stack, which a player is not.
        Filter.Type.FromSource _ -> predicate
        Filter.Type.IsTapped -> predicate
        Filter.Type.IsFaceDown -> predicate
        -- NOT descended into, for AttachedTo's reason: CR 708.12's subject is the card
        -- representing an OBJECT, so Parun.Engine.Filter answers the atom False for a
        -- player candidate whatever the nest says, and baking the nest here would bake
        -- a question about that card against a player who is not one.
        Filter.Type.RepresentedByCard _ -> predicate
        Filter.Type.IsExiledFaceDown -> predicate
        Filter.Type.Transformed -> predicate
        Filter.Type.IsRingBearer -> predicate
        Filter.Type.IsPaired -> predicate
        Filter.Type.IsPairedWithSource -> predicate
        Filter.Type.BlockPartnerOfSource _ -> predicate
        Filter.Type.HasDesignation _ -> predicate
        Filter.Type.HasCounters _ -> predicate
        Filter.Type.HasCountersOfAnyKind -> predicate
        Filter.Type.HasSticker _ -> predicate
        Filter.Type.Stickered -> predicate
        Filter.Type.HasActivatedAbility _ -> predicate
        Filter.Type.IsInZone _ -> predicate
        Filter.Type.WasCastFrom _ -> predicate
        Filter.Type.TagWasSpent _ -> predicate
        Filter.Type.Paid _ -> predicate
        Filter.Type.IsPrototyped -> predicate

-- A baked answer as a Filter. `And []` is the trivial predicate by
-- Parun.Types.Filter's own note, so its negation is the trivially false one --
-- there is no Always atom to reach for and deliberately so.
truth :: Bool -> Filter.Type.Filter keyword
truth b = if b then Filter.Type.And [] else Filter.Type.Not (Filter.Type.And [])

-- CR 110.2: how many permanents that player CONTROLS match the filter.
--
-- Control is read off the projected view rather than off Game.zoneMembers, which
-- slices the shared battlefield by OWNER (see #161): rule 110.2 makes the two come
-- apart, and control is what the card asks about. The view is the injected one
-- every other candidate is seen through, so a land animated or taken at CR 613's
-- layers counts as the layers leave it, and an object the caller's projection
-- cannot describe counts for nobody.
--
-- The inner filter is matched under the UNCHANGED context, so what it says about
-- CR 109.5's "you" or about the source is still said about the real ones. The
-- candidate's own board is expressed by the controller test here rather than by a
-- HeldBy Controller conjunct, which could only ever name a relation.
controlledMatching :: ViewOf -> Filter.Context -> GameState -> Filter.Type.Filter Keyword.Type.Keyword -> PlayerId -> Integer
controlledMatching viewOf context gs inner pid =
  let matching oid = case viewOf oid of
        Nothing -> False
        Just view -> Filter.controller view == Just pid && Filter.matches context view inner
   in toInteger (length (Prelude.filter matching (Set.toList (GameState.battlefield gs))))

-- CR 303.4b / 301.5a: the permanents attached TO player `candidate` --
-- HasAttached's reverse of AttachedTo, and `bakePerspective`'s door onto the
-- board for it. Narrowed to the battlefield, as Parun.Engine.Projection's
-- attachedViews narrows for the object-side sweep.
attachersOfPlayer :: GameState -> PlayerId -> [ObjectId]
attachersOfPlayer gs candidate =
  filter
    (\attacher -> (Game.lookupObject attacher gs >>= Object.attachedTo >>= Recipient.playerOf) == Just candidate)
    (Set.toList (GameState.battlefield gs))

-- What makes two mana costs the same cost: their generic symbols summed and
-- the rest as a multiset, so a split card's {1}{R} and {1}{U} combine (CR
-- 709.4b) to {2}{U}{R}, while {X} is not {0} and {B/R} is neither {B} nor {R}.
-- No symbols at all is {0}, as data/cards writes Ornithopter's cost.
manaCostKey :: ManaCost.ManaCost -> (Natural.Natural, [ManaSymbol.ManaSymbol])
manaCostKey cost =
  let symbols = ManaCost.unwrap cost
      generic symbol = case symbol of
        ManaSymbol.Generic n -> Just n
        _ -> Nothing
   in (sum (Maybe.mapMaybe generic symbols), List.sort (filter (Maybe.isNothing . generic) symbols))

keep :: Filter.Type.Filter Keyword.Type.Keyword -> Filter.Context -> Maybe Filter.View -> Maybe Filter.View
keep predicate context mv = case mv of
  Nothing -> Nothing
  Just v -> if Filter.matches context v predicate then Just v else Nothing

-- CR 208.2a: Tarmogoyf counts card TYPES, so Distinct is the size of the
-- union, not the length of the list.
--
-- Each member carries the object it came from when there is one, and its view
-- either way. An InHistory member has no object -- its view is a CR 608.2h
-- snapshot of a past event rather than of anything on the battlefield now --
-- so Greatest and Total hand the reader both and let it answer from whichever
-- it can.
aggregate :: QuantityOf quantity -> Aggregation.Aggregation quantity -> [(Maybe ObjectId, Filter.View)] -> Maybe Integer
aggregate quantityOf aggregation members = case aggregation of
  Aggregation.Members -> Just (toInteger (length members))
  Aggregation.Distinct DistinctOf.CardTypes -> Just (toInteger (Set.size (Set.unions (fmap (Filter.cardTypes . snd) members))))
  -- CR 105.2c: a colorless member adds nothing.
  Aggregation.Distinct DistinctOf.Colors -> Just (toInteger (Set.size (Set.unions (fmap (Filter.colors . snd) members))))
  -- CR 305.6: a land's other subtypes (Gate, Desert, Urza's) add nothing, and a
  -- land with two basic land types (Tundra) adds both.
  Aggregation.Distinct DistinctOf.BasicLandTypes -> Just (toInteger (Set.size (Set.filter Subtype.isBasicLandType (Set.unions (fmap (Filter.subtypes . snd) members)))))
  -- CR 202.3a: a member with no mana cost still has mana value 0.
  Aggregation.Distinct DistinctOf.ManaValues -> Just (toInteger (Set.size (Set.fromList (Maybe.mapMaybe (Filter.manaValue . snd) members))))
  -- CR 202.1b: a member with no mana cost adds nothing; {0} is a cost.
  Aggregation.Distinct DistinctOf.ManaCosts -> Just (toInteger (Set.size (Set.fromList (Maybe.mapMaybe (fmap manaCostKey . Filter.manaCost . snd) members))))
  -- The size of the largest group of members holding one value in common --
  -- not "pairwise sharing", which is not transitive (a Human Cleric, a Human
  -- Rogue and an Elf Rogue are no three sharing a type). A member joins a group
  -- per value: an artifact creature both card-type groups (CR 205.2b), a
  -- multicoloured card each colour's (CR 105.2b), a changeling every creature
  -- type's through its projected subtypes (CR 702.73a). A member with no value
  -- (a colourless one, CR 105.2c) joins none, nor does a land type or other
  -- non-creature subtype (CR 205.3m). 0 over an empty set.
  Aggregation.MostSharing trait -> Just $ case trait of
    Trait.CreatureType -> largestGroup (Set.filter Subtype.isCreatureType . Filter.subtypes)
    Trait.CardType -> largestGroup Filter.cardTypes
    Trait.Color -> largestGroup Filter.colors
    Trait.Name -> largestGroup Filter.names
    Trait.Owner -> largestGroup (foldMap Set.singleton . Filter.owner)
    Trait.Sector -> largestGroup (Sector.sectorsIn . Filter.designations)
  -- CR 201.2b: the largest group in which every member has a name and no two
  -- share one. Single-named members contribute one per distinct name; a
  -- member with several names is tried in and out of the group, since taking
  -- it spends all of them. Parun.ConditionSpec's The Necrobloom case proves the
  -- single-named count; the several-names branch is a regression fence, since
  -- no card in data/cards counts names over objects that can have two.
  Aggregation.DistinctNames ->
    let named = filter (not . Set.null) (fmap (Filter.names . snd) members)
        (single, multiple) = List.partition ((== 1) . Set.size) named
        best used rest = case rest of
          [] -> Set.size (Set.difference (Set.unions single) used)
          these : others ->
            let without = best used others
             in if Set.null (Set.intersection these used)
                  then max without (1 + best (Set.union these used) others)
                  else without
     in Just (toInteger (best Set.empty multiple))
  -- Undeterminable in both directions. A member whose quantity cannot be
  -- determined makes the whole maximum undeterminable rather than being dropped, which
  -- would report the maximum of a set the card never named; and an EMPTY
  -- matched set has no maximum. Nothing, NOT 0: no rule gives a maximum over
  -- nothing a value, and where the CR wants an empty maximum to be 0 it
  -- legislates it case by case (CR 714.2d). CR 208.2a is one such case, applied
  -- where it is scoped -- at the characteristic-defining ability that consumes
  -- this count, never here. docs/decisions.md, "What the greatest value is
  -- over an empty or undeterminable set".
  -- Parun.CountSpec's Rootha, Mastering the Moment group is what proves the
  -- objectless member really is read off its snapshot.
  Aggregation.Greatest quantity -> do
    values <- traverse (\(identity, view) -> quantityOf identity view quantity) members
    case values of
      [] -> Nothing
      value : rest -> Just (Foldable.foldl' max value rest)
  -- Undeterminable in the same direction as Greatest, and for the same reason:
  -- a member whose quantity has no value makes the whole sum a sum over a set
  -- the card never named. The EMPTY set differs -- 0, not Nothing -- because a
  -- sum has an identity where a maximum has none, and "the total mana value of
  -- cards you own in exile" with an empty exile is a number the card can use.
  Aggregation.Total quantity -> do
    values <- traverse (\(identity, view) -> quantityOf identity view quantity) members
    pure (sum values)
  where
    largestGroup :: (Ord a) => (Filter.View -> Set.Set a) -> Integer
    largestGroup valuesOf = Foldable.foldl' max 0 (Map.fromListWith (+) [(value, 1 :: Integer) | (_, view) <- members, value <- Set.toList (valuesOf view)])

-- CR 400.1: whose copy of the zone -- and, for Parun.Engine.ManaCount, whose
-- mana pool, which CR 106.4 attaches to a player the same way. Nothing when the
-- reference cannot be resolved: a relation with no perspective, or a slot the
-- arm reading it can make no player of.
--
-- Parun.Engine.Players.named's reading, the one every "which players" question
-- shares; what is this position's own is how it reads a slot (slotPlayers
-- below, and Filter.slotOneObject) and a controller or owner -- off the
-- caller's view, since CR 613.1b makes control a layer-2 question.
--
-- Observable through Scope.OverPlayers, which folds the players this returns
-- rather than their objects, and Parun.CountSpec's Tyranid Invasion group is
-- what proves CR 102.1's departed seat stays out. Through Scope.InZone it still
-- is not: CR 800.4a already emptied every zone a departing player owned.
playersFor :: ViewOf -> Filter.Context -> GameState -> PlayerRef.PlayerRef -> Maybe [PlayerId]
playersFor viewOf context gs =
  Players.named
    Players.MkReads
      { Players.perspective = Filter.perspective context,
        Players.bound = Maybe.isJust (Filter.source context),
        Players.slotPlayers = slotPlayers context gs,
        Players.slotObject = (`Filter.slotOneObject` context),
        Players.controllerOf = viewOf Monad.>=> Filter.controller,
        Players.ownerOf = viewOf Monad.>=> Filter.owner,
        Players.acquisitionOf = (`Game.acquisitionOf` gs),
        Players.roster = Players.table (Filter.perspective context) gs,
        Players.reaches = const True
      }
    gs

-- CR 800.4i: playersFor for a tally of what HAPPENED to players, judged over
-- every seat that began the game rather than over those still in it: a player
-- who lost life and then left still lost it (Skewer the Critics' ruling,
-- 2024-01-12; Florian, Voldaren Scion's, 2021-09-24).
historyPlayersFor :: ViewOf -> Filter.Context -> GameState -> PlayerRef.PlayerRef -> Maybe [PlayerId]
historyPlayersFor viewOf context gs =
  Players.named
    Players.MkReads
      { Players.perspective = Filter.perspective context,
        Players.bound = Maybe.isJust (Filter.source context),
        Players.slotPlayers = slotPlayers context gs,
        Players.slotObject = (`Filter.slotOneObject` context),
        Players.controllerOf = viewOf Monad.>=> Filter.controller,
        Players.ownerOf = viewOf Monad.>=> Filter.owner,
        Players.acquisitionOf = (`Game.acquisitionOf` gs),
        Players.roster = GameState.turnOrder gs,
        Players.reaches = const True
      }
    gs

-- CR 102.1: the players a TurnScope.PlayersTurn reference names, which is
-- playersFor with CR 113.7's source slot naming the context's source where
-- nothing bound it already -- a step trigger is matched before its bindings
-- exist, and Soul Bleed's "enchanted creature's controller" reads the host of
-- the Aura through that slot. Turn.turnScopeAdmits takes this as its reader.
scopePlayers :: ViewOf -> Filter.Context -> GameState -> PlayerRef.PlayerRef -> Maybe [PlayerId]
scopePlayers viewOf context =
  let withSource source = context {Filter.slotObjects = Map.insertWith (\_ bound -> bound) Binding.triggerSource (Set.singleton source) (Filter.slotObjects context)}
   in playersFor viewOf (maybe context withSource (Filter.source context))

-- CR 601.2c: the players one slot names at this position, or Nothing where no
-- slot of that name is bound here -- which every arm above reads as
-- "unanswerable" rather than as an empty fold.
--
-- TWO roads, and the first is why Filter.Context carries the map at all. A
-- resolution supplies its own CR 608.2b-filtered slots
-- (Parun.Engine.Resolve.Slots.effectContext), a trigger's intervening "if" its own
-- bindings (Parun.Engine.Event.Trigger.interveningHolds and CR 608.2a's re-check
-- in Parun.Engine.Stack), and that is the only read that answers for an ABILITY:
-- CR 113.7 makes Filter.source the ability's source permanent, while its targets
-- and its trigger's bindings are stamped on the ability object on the stack (see
-- #1783). Ebony Owl Netsuke's "if that player has seven or more cards in hand"
-- is what proves the intervening road (Parun.CountSpec). The SOURCE's own
-- bindings are the fallback, which is the honest read for a caller with no
-- announcement behind it at all -- a static ability's projection -- and for a
-- spell, whose source IS its stack object.
--
-- A replacement's CONDITION still takes the fallback, which for it is #1783's
-- failure over again: Parun.Types.ActiveReplacement.slots holds only the OBJECT
-- half of the installing resolution's slots. No printing asks it -- see
-- Filter.Context.slotPlayers for the query -- since a row's "if that player"
-- is its pattern, which ControllerRelation.InSlot bakes at install.
slotPlayers :: Filter.Context -> GameState -> SlotName.SlotName -> Maybe [PlayerId]
slotPlayers context gs name = case Map.lookup name (Filter.slotPlayers context) of
  Just pids -> Just (Set.toList pids)
  Nothing -> do
    src <- Filter.source context
    obj <- Game.lookupObject src gs
    recipients <- Map.lookup name (Binding.targetsOf (Object.bindings obj))
    Just (Maybe.mapMaybe Recipient.playerOf (Set.toList recipients))

-- CR 608.2h: the view of a past event, built from the snapshot the event
-- recorded rather than from any object that may no longer exist.
--
-- The snapshot fills the characteristic fields it records (see viewOfSnapshot
-- below). A move reads the rest off CR 608.2h's record filed under the id it
-- left behind, through lastKnownView -- the view a trigger takes of the same
-- departure, so the two cannot disagree. A cast has no such record: CR 601.2a
-- makes the caster its controller, and what is not a characteristic is
-- vacuously empty over it.
--
-- `viewOf` is the reader the CARD shape needs, and the one lastKnownView reads
-- the permanents attached to a departed object through: CR 400.7 makes the
-- object that ARRIVED a new object of its own, so "a creature card was put into
-- a graveyard" is a question about the card lying there and not about the
-- permanent that left. Injected rather than imported, for the reason ViewOf
-- itself is: Parun.Engine.Projection imports this module.
snapshotView :: ViewOf -> GameState -> EventShape.EventShape -> GameEvent.GameEvent -> Maybe Filter.View
snapshotView viewOf gs shape event = case event of
  GameEvent.Moved (Moved.MkMoved zc snapshot _ _ _ _ _ _) -> case shape of
    EventShape.MovedBetween (MovedBetween.MkMovedBetween from to) ->
      if ZoneChange.from zc == from && ZoneChange.to zc == to then Just (departedView viewOf gs zc snapshot) else Nothing
    -- CR 603.6c: to another zone, so Event.recordMintedEntry's Battlefield to
    -- Battlefield entry of a token or conjured card is not a departure, nor CR
    -- 400.8's re-exiled card (Game.leftOrigin).
    EventShape.MovedFrom from ->
      if ZoneChange.from zc == from && Game.leftOrigin zc then Just (departedView viewOf gs zc snapshot) else Nothing
    -- CR 712.21e's second half, whose unit is the CARD: this event announces the
    -- move's LEADING arrival (Parun.Engine.Event.changeZoneAttaching), so it is
    -- worth one card here and each arrival after it is worth another through the
    -- CardArrived arm below. An ordinary move has no arrival after the leading
    -- one, so the two shapes agree about everything but a melded permanent.
    --
    -- The DESTINATION, per the constructor's own note, and the origin only where
    -- the shape excludes one.
    EventShape.CardArrivedIn arrival ->
      if arrivalMatches arrival zc
        then Just (Maybe.fromMaybe (departedView viewOf gs zc snapshot) (orLastKnown viewOf gs (ZoneChange.object zc)))
        else Nothing
    EventShape.SpellCast -> Nothing
    EventShape.SpellCastThisGame -> Nothing
  GameEvent.DamageDealt _ -> Nothing
  -- CR 615.13's record names two ids, a recipient and an amount, and snapshots no
  -- characteristics, so there is nothing for a Filter to look at.
  GameEvent.DamagePrevented {} -> Nothing
  GameEvent.StepBegan {} -> Nothing
  -- CR 601.2i's cast, read from the snapshot the event took as the spell became
  -- cast rather than off the stack: by the time a look-back count folds the log
  -- that spell has usually resolved or been countered, so the live object is
  -- gone. TriggerCondition.SpellCast is the other reader and does read it live,
  -- which it can -- CR 601.2i's trigger is checked while the spell is still
  -- there. The CHARACTERISTICS, that is: Game.ownerWithLastKnown reads the live object
  -- for the one field a snapshot cannot carry, wherever there still is one.
  GameEvent.SpellCast (SpellWasCast.MkSpellWasCast caster spell snapshot _ _ lapsed) -> case shape of
    -- CR 601.2a: "that player becomes its controller", so the caster the event
    -- recorded IS the view's controller and Filter.HeldBy Holder.Controller You answers "a
    -- spell you've cast". The spell's id is deliberately left out of the view
    -- for the reason the Moved arm leaves its own out: a look-back view is of a
    -- past event rather than of an object, and Filter.IsSource asking about one
    -- would be asking about an incarnation that no longer exists.
    -- CR 111.1 / 111.7: a token represents a PERMANENT and ceases to exist
    -- anywhere else, so nothing on the stack to be cast was ever one.
    -- CR 122.1 places a counter on an OBJECT, and CR 122.2 makes the card that
    -- became this spell shed whatever it carried on its way to the stack, so a
    -- cast records none.
    --
    -- CR 108.3's owner comes from Game.ownerWithLastKnown, and is NOT `caster`
    -- again, whom CR 405.4 makes the spell's controller and no more: Dire Fleet
    -- Daredevil casts a card its owner never touched (Parun.CountSpec).
    EventShape.SpellCast -> Just castView
    EventShape.SpellCastThisGame -> Just castView
    EventShape.MovedBetween {} -> Nothing
    EventShape.MovedFrom {} -> Nothing
    -- CR 601.2a moves a card to the STACK, so a cast IS a card arriving there --
    -- but the Moved event the same cast emits is what says so, and answering here
    -- too would count one cast twice.
    EventShape.CardArrivedIn {} -> Nothing
    where
      -- CR 113.6 / 604.2: on the stack. A regression fence: nothing in
      -- data/cards/ asks a cast whether it had an activated ability.
      castView = viewOfSnapshot False (Just caster) (Game.ownerWithLastKnown spell gs) False Map.empty Zone.Stack Zone.Battlefield lapsed snapshot
  GameEvent.BecameMonarch _ -> Nothing
  GameEvent.TookInitiative _ -> Nothing
  -- CR 702.29c's cycling records no characteristics snapshot -- the Moved event
  -- the same discard emits is what carries one -- so there is nothing here for
  -- an EventShape to match against.
  GameEvent.Discarded {} -> Nothing
  GameEvent.Drew {} -> Nothing
  -- A reveal DOES carry a characteristics snapshot, as the two arms above do,
  -- and is still Nothing here: no EventShape names revealing. This becomes a
  -- real view the day one does (#162).
  GameEvent.Revealed {} -> Nothing
  -- A look (CR 701.20e) likewise: no EventShape names looking.
  GameEvent.Looked {} -> Nothing
  GameEvent.Voted {} -> Nothing
  GameEvent.VotesRevealed {} -> Nothing
  -- The same reason, with no snapshot to offer either: no EventShape names an
  -- attacker being declared (CR 508.2b).
  GameEvent.AttackerDeclared {} -> Nothing
  GameEvent.BecameBlocking {} -> Nothing
  GameEvent.BlocksDeclared {} -> Nothing
  GameEvent.AttackerBlocked {} -> Nothing
  GameEvent.AttackerUnblocked _ -> Nothing
  -- A countering (CR 701.6a) does move the spell, but this event is not that
  -- move: Event.counter records a Moved event alongside this one, and matching
  -- both would count one countering twice. It carries no snapshot either.
  -- Becomes a real view the day an EventShape names countering (#162).
  GameEvent.SpellCountered _ -> Nothing
  -- The sibling has no Moved event beside it either, CR 608.2n ceasing the
  -- ability rather than moving it, and carries no snapshot for the same reason.
  GameEvent.AbilityCountered _ -> Nothing
  GameEvent.HalfUnlocked {} -> Nothing
  GameEvent.TurnedFaceUp _ -> Nothing
  GameEvent.PermanentActed _ -> Nothing
  GameEvent.Transformed {} -> Nothing
  GameEvent.BecameDesignated {} -> Nothing
  GameEvent.Mentored {} -> Nothing
  GameEvent.Exploited {} -> Nothing
  GameEvent.BecameCrewed _ -> Nothing
  GameEvent.Convoked _ -> Nothing
  GameEvent.Saddled _ -> Nothing
  GameEvent.Crewed _ -> Nothing
  GameEvent.PermanentSacrificed {} -> Nothing
  GameEvent.AbilityTriggered {} -> Nothing
  GameEvent.AbilityActivated _ -> Nothing
  GameEvent.LifeLost {} -> Nothing
  GameEvent.LifeGained {} -> Nothing
  -- CR 122.6's placement names an object by id and snapshots no characteristics,
  -- and no EventShape names it either.
  GameEvent.CountersPut {} -> Nothing
  GameEvent.CountersRemoved {} -> Nothing
  -- A control change names two players and one object by id, snapshots no
  -- characteristics, and no EventShape names it.
  GameEvent.ControlChanged {} -> Nothing
  GameEvent.VentureMarkerEntered {} -> Nothing
  -- CR 601.2c's targeting names two objects by id and snapshots no
  -- characteristics, so no EventShape names it either.
  GameEvent.BecameTarget {} -> Nothing
  GameEvent.BecameAttached {} -> Nothing
  GameEvent.BecameUnattached {} -> Nothing
  -- CR 701.17a names its cards by id and snapshots no characteristics.
  GameEvent.Milled {} -> Nothing
  -- CR 603.6c's other road off the battlefield, and CR 729.4a's out of any
  -- main-game zone: this event answers MovedFrom the zone it records and nothing
  -- else, read off the CR 608.2h record filed under its id.
  GameEvent.LeftTheGame (LeftTheGame.MkLeftTheGame oid from) -> case shape of
    EventShape.MovedFrom zone | zone == from -> fmap (lastKnownView viewOf oid gs) (Map.lookup oid (GameState.lastKnown gs))
    _ -> Nothing
  GameEvent.PlayerActed _ -> Nothing
  GameEvent.LandPlayed {} -> Nothing
  GameEvent.LostTheGame _ -> Nothing
  GameEvent.ManifestedDread {} -> Nothing
  GameEvent.DieResultSettled _ -> Nothing
  GameEvent.RolledToVisit _ -> Nothing
  GameEvent.PlanarDieRolled _ -> Nothing
  GameEvent.TurnedUpOffDeck _ -> Nothing
  GameEvent.ChaosEnsued -> Nothing
  GameEvent.ClassLevelSet _ -> Nothing
  GameEvent.Plotted _ -> Nothing
  GameEvent.BecameAttacked _ -> Nothing
  GameEvent.AttackersDeclared _ -> Nothing
  GameEvent.BecameTapped _ -> Nothing
  GameEvent.BecameUntapped _ -> Nothing
  GameEvent.TappedForMana _ -> Nothing
  GameEvent.ManaAdded _ -> Nothing
  GameEvent.ManaAbilityResolved _ -> Nothing
  GameEvent.CoinFlipped {} -> Nothing
  GameEvent.SpellCopied _ -> Nothing
  GameEvent.StickerPut _ -> Nothing
  GameEvent.ActivatedAbilityResolved _ -> Nothing
  GameEvent.TriggeredAbilityResolved _ -> Nothing
  -- CR 712.21e's second half: every arrival AFTER the leading one, which is what
  -- makes a melded permanent two cards where the Moved arm above makes it one
  -- object. Read under the card shape alone -- answering it under MovedBetween
  -- would make Khabal Ghoul's "each creature that died this turn" see a melded
  -- creature three times.
  --
  -- Matched on this event's OWN destination and not the move's, which is CR
  -- 903.9c: a melded commander's component splits off to the command zone while
  -- the rest of the move goes where it was headed, and only the card that
  -- arrived in the named zone is counted (Parun.MeldSpec).
  GameEvent.CardArrived zc -> case shape of
    -- The ARRIVED card, which CR 712.21e is the whole point of here: each
    -- component of a melded permanent is a card of its own, and reading the
    -- record filed under the DEPARTED id would give both of them the melded
    -- permanent's characteristics.
    --
    -- The departed record is still the fallback, for the arrival that has no
    -- object to read: a token put into a graveyard ceases to exist (CR 111.7),
    -- and what it WAS is all there is to count it by. Nothing where neither
    -- answers, the honest blank for a card whose characteristics as it moved
    -- cannot be recovered.
    --
    -- Parun.CountSpec's Raphael group proves the reading, and Parun.MeldSpec's
    -- Case of the Gorgon's Kiss case proves its melded half.
    EventShape.CardArrivedIn arrival ->
      if arrivalMatches arrival zc
        then case orLastKnown viewOf gs (ZoneChange.object zc) of
          Just view -> Just view
          Nothing -> fmap (lastKnownView viewOf (ZoneChange.departed zc) gs) (Map.lookup (ZoneChange.departed zc) (GameState.lastKnown gs))
        else Nothing
    EventShape.MovedBetween {} -> Nothing
    EventShape.MovedFrom {} -> Nothing
    EventShape.SpellCast -> Nothing
    EventShape.SpellCastThisGame -> Nothing

-- CR 712.21e's destination narrowed by the printed clause's origin: the arrival
-- landed in the named zone, and it did not come from one this shape excludes. An
-- empty exclusion is "from anywhere", which is every producer but Dimir
-- Strandcatcher.
--
-- Read off the ARRIVAL's own zone change rather than the move's, which CR 903.9c
-- makes different for a melded commander (Parun.MeldSpec); the origin is the same
-- for every arrival of one move, CR 712.21 having one permanent leave.
arrivalMatches :: CardArrivedIn.CardArrivedIn -> ZoneChange.ZoneChange -> Bool
arrivalMatches arrival zc =
  ZoneChange.to zc == CardArrivedIn.to arrival
    && Set.notMember (ZoneChange.from zc) (CardArrivedIn.excluding arrival)

-- CR 608.2h: the moving object as the record the move funnel filed under the
-- DEPARTED id shows it -- the same pre-move state a Moved event's snapshot is
-- taken against (CR 400.7 makes that id name nothing else, ever) -- with the
-- event's own snapshot for its characteristics.
--
-- `snapshot` is a parameter rather than read from the record because the two
-- events that reach here carry it differently: a Moved event stamps its own, and
-- a CardArrived event has none of its own to stamp.
--
-- No record only where nothing departed: Event.recordMintedEntry's
-- battlefield-to-battlefield entry of a token or conjured card, which no shape
-- here counts as a departure. The bare snapshot answers there, with no
-- controller, owner, counters or lapsed CR 604.2 clauses to read. Only a
-- MovedBetween naming the battlefield as both ends reaches it, which no printed
-- look-back can, a token's creation (CR 111.2) being no move from the
-- battlefield; the MovedFrom arm refuses it (Game.leftOrigin). Once the token
-- has left, the CardArrivedIn arm reads the record its departure filed, clauses
-- and all (LastKnown.lapsedGrants).
departedView :: ViewOf -> GameState -> ZoneChange.ZoneChange -> PC.ProjectedCharacteristics -> Filter.View
departedView viewOf gs zc snapshot = case Map.lookup (ZoneChange.departed zc) (GameState.lastKnown gs) of
  Just lastKnown -> lastKnownView viewOf (ZoneChange.departed zc) gs lastKnown {LastKnown.characteristics = snapshot}
  Nothing -> viewOfSnapshot (deployIn gs (ZoneChange.from zc)) Nothing Nothing (Game.isToken (ZoneChange.object zc) gs) Map.empty (ZoneChange.from zc) Zone.Battlefield Set.empty snapshot

-- CR 113.7a / 608.2h: `live`'s view of an object that exists, else the view of
-- the record filed under its id once it has left (lastKnownView), else Nothing.
-- The one "live, else last known" fallback over a whole view: every single
-- characteristic a departed object is asked for is a field of this view
-- (Parun.Engine.Projection.controllerWithLastKnown) or of the record's projection
-- (Parun.Engine.Projection.projectWithLastKnown), never a fallback of its own.
--
-- Game.liveOrLastKnown rather than `live`'s Nothing decides which, because
-- Projection.fullView answers Just a blank view for an id naming nothing, and a
-- blank view is not a token (the CardArrived arm above).
orLastKnown :: ViewOf -> GameState -> ViewOf
orLastKnown live gs oid = Monad.join (Game.liveOrLastKnown (const (live oid)) (Just . lastKnownView live oid gs) oid gs)

-- CR 608.2h: an object that has ceased, as its record shows it -- the one view
-- of a LastKnown, read by a trigger or an intervening "if" asking about the
-- object an event named (Parun.Engine.Projection.viewWithLastKnownAnywhere), by
-- an ability whose source has left (CR 113.7a), and by a look-back count's
-- departures here, so that "attacking creatures that died this turn" sees what
-- Brazen Cannonade's trigger sees (CR 608.2i). The count's twin scenarios in
-- data/scenarios/count, cr-608-2i-an-attacking-giant-that-died-is-counted-as-attacking
-- and its kept-home control, are the board.
--
-- The record's characteristics through viewOfSnapshot, and over them what the
-- record keeps beside the characteristics because CR 109.3 counts none of it
-- one: the controller (CR 110.2), the owner (CR 108.3), tokenhood (CR 111.6),
-- the counters CR 122.2 destroyed and CR 613.4c had already consumed, the combat
-- status CR 506.4 took away as it left, and the costs paid for it (CR 400.7d).
--
-- Each record field is proved where a trigger reads it: the OWNER by
-- Parun.ConditionSpec's "the entrant killed between the two checks still grows
-- the Knight" (that it answers; WHICH player is a fence, the record's controller
-- leaving it green) and, over a departure, by Dimir Strandcatcher's "put into
-- your graveyard" (Parun.CountSpec), TOKEN status by Sunpearl Kirin's "if it
-- was a token",
-- BLOCKING by Guildsworn Prowler's intervening "if" and ATTACKING by Garna,
-- Bloodfist of Keld's "if it was attacking". The three fields that follow the
-- combat lookup on to the attacked permanent -- attackingPlayer,
-- attackingPlaneswalkerController and attackingBattleProtector -- answer
-- Nothing, and Parun.Types.LastKnown's `attacking` records the query behind
-- that; so does `blockStatus`, Nothing too, whose one printing asks a CR 608.2i
-- question.
--
-- `oid` is the id it had, so the turn's log still answers what it did while it
-- existed (CR 608.2i) -- it attacked, it was dealt damage, it entered -- and
-- IsSource still knows it. `peers` reads the record's attachments, at the
-- caller's depth, as viewOfCharacteristics' own `attachedViews` does.
--
-- The activated abilities are the snapshot's less those whose CR 604.2 grant
-- did not function in the zone it left, given its CR 113.6p home
-- (LastKnown.home), or whose clause the record says had lapsed
-- (LastKnown.lapsedGrants). Parun.VanguardSpec's departed Synthetic Steward
-- Avatar proves the home; the zone half is otherwise a regression fence here:
-- no card asks it of an object that left anywhere but the battlefield, where
-- every grant functions.
--
-- Every other object field is the snapshot's blank, which is what the live read
-- answers for an id naming nothing too: no zone, no targets, no designations.
lastKnownView :: ViewOf -> ObjectId -> GameState -> LastKnown.LastKnown -> Filter.View
lastKnownView peers oid gs lastKnown =
  let deploy = deployIn gs (LastKnown.zone lastKnown)
   in ( viewOfSnapshot
          deploy
          (Just (LastKnown.controller lastKnown))
          (Just (LastKnown.owner lastKnown))
          (Game.sourceIsToken (LastKnown.source lastKnown))
          (LastKnown.counters lastKnown)
          (LastKnown.zone lastKnown)
          (LastKnown.home lastKnown)
          (LastKnown.lapsedGrants lastKnown)
          (LastKnown.characteristics lastKnown)
      )
        { Filter.identity = Just oid,
          Filter.attacking = LastKnown.attacking lastKnown,
          Filter.blocking = LastKnown.blocking lastKnown,
          Filter.paidCosts = LastKnown.paidCosts lastKnown,
          -- CR 718.3d: the copiable record or the object's own, viewOfCharacteristics'
          -- disjunction. A regression fence: no card asks it of a departed object.
          Filter.prototyped = PC.prototyped (LastKnown.characteristics lastKnown) || LastKnown.prototyped lastKnown,
          Filter.declaredThisTurn = declaredThisTurn oid gs,
          Filter.couldAttackThisTurn = couldAttackThisTurn oid gs,
          Filter.declaredAttackerThisCombat = declaredAttackerThisCombat oid gs,
          Filter.declaredAttackedThisCombat = declaredAttackedThisCombat oid gs,
          Filter.declaredBlockerThisCombat = declaredBlockerThisCombat oid gs,
          Filter.milledThisTurn = milledThisTurn oid gs,
          Filter.dealtDamageThisTurn = dealtDamageThisTurn oid gs,
          Filter.arrivalThisTurn = Game.arrivalThisTurn oid gs,
          Filter.crewedThisTurn = crewedThisTurn oid gs,
          Filter.convokedThisTurn = convokedThisTurn oid gs,
          Filter.saddledThisTurn = saddledThisTurn oid gs,
          Filter.dealtDamageTo = dealtDamageTo oid gs,
          Filter.dealtDamageEarlier = dealtDamageEarlier oid gs,
          -- CR 603.10a: what was attached to it as it left, which the next CR
          -- 704.5m/n pass clears from the live board before triggers are placed.
          Filter.attachedViews = Maybe.mapMaybe peers (Set.toList (LastKnown.attached lastKnown)),
          -- CR 303.4b: the host's id as it left, the live builder's Game.hostOf.
          Filter.attachedTo = LastKnown.host lastKnown
        }

-- CR 608.2i: did this object attack or block this turn? From the turn's event
-- log, which CR 511.3 does not clear. Only Combat.declareAttackers appends
-- AttackerDeclared (CR 508.3a), and GameEvent.BlocksDeclared leaves out a
-- creature put onto the battlefield blocking (CR 509.3a), so neither CR 508.4's
-- arrival attacking nor its blocking twin counts.
declaredThisTurn :: ObjectId -> GameState -> Set.Set BlockRole.BlockRole
declaredThisTurn oid gs =
  let roleOf event = case event of
        GameEvent.AttackerDeclared (AttackerDeclared.MkAttackerDeclared declared _ _ _ _) | declared == oid -> Just BlockRole.Attacker
        GameEvent.BlocksDeclared (BlocksDeclared.MkBlocksDeclared blocker _) | blocker == oid -> Just BlockRole.Blocker
        _ -> Nothing
   in Set.fromList (Maybe.mapMaybe (roleOf . LoggedEvent.event) (Foldable.toList (GameState.events gs)))

-- CR 508.1a-d: could this object have been declared as an attacker in one of
-- this turn's declare attackers steps? The record those steps wrote as each
-- declaration began.
couldAttackThisTurn :: ObjectId -> GameState -> Bool
couldAttackThisTurn oid gs = Set.member oid (GameState.couldAttackThisTurn gs)

-- CR 508.1a / 509.1a: from the COMBAT record, which CR 511.3 does clear -- and
-- not from the log above, which cannot answer it: CR 508.1k and CR 509.1g put
-- the AttackerDeclared and BecameBlocking events after the payment these are
-- read during, so a fold over them would be False for exactly the creatures
-- being declared.
declaredAttackerThisCombat :: ObjectId -> GameState -> Bool
declaredAttackerThisCombat oid gs = Set.member oid (Combat.declaredAttackers (GameState.combat gs))

-- CR 508.3b: the same record's other half, indexed by TARGET rather than by
-- attacker. A permanent is named as AttackTarget.OfPlaneswalker or
-- AttackTarget.OfBattle; playerView answers CR 508.3b's third subject off the
-- same set.
declaredAttackedThisCombat :: ObjectId -> GameState -> Bool
declaredAttackedThisCombat oid gs =
  Set.member (AttackTarget.OfPlaneswalker oid) (Combat.declaredAttacked (GameState.combat gs))
    || Set.member (AttackTarget.OfBattle oid) (Combat.declaredAttacked (GameState.combat gs))

-- CR 509.1a: declaredAttackerThisCombat's record, for the blockers.
declaredBlockerThisCombat :: ObjectId -> GameState -> Bool
declaredBlockerThisCombat oid gs = Set.member oid (Combat.declaredBlockers (GameState.combat gs))

-- CR 701.17a / 608.2i: was this object one of a mill's cards this turn? Only
-- Resolve's Mill arm appends the event, so a surveil's or an explore's bin stays
-- out.
milledThisTurn :: ObjectId -> GameState -> Bool
milledThisTurn oid gs =
  let milledIt event = case event of
        GameEvent.Milled (Milled.MkMilled _ cards) -> Foldable.elem oid cards
        _ -> False
   in any (milledIt . LoggedEvent.event) (GameState.events gs)

-- CR 120.1 / 608.2i: was this object dealt damage this turn? Never
-- Object.damage -- CR 120.6 removes the marks on a regeneration, CR 701.69a heals
-- them away and CR 120.3d/120.3e mark none at all for wither or infect, and any
-- such creature was still dealt damage this turn.
dealtDamageThisTurn :: ObjectId -> GameState -> Bool
dealtDamageThisTurn oid gs = any ((== Just oid) . Game.damagedObject . LoggedEvent.event) (GameState.events gs)

-- CR 702.122c / 608.2i: the Vehicles this object crewed this turn -- the half of
-- the relation a candidate can answer; Parun.Engine.Filter's
-- CrewedSourceThisTurn compares them against the source it is evaluating for.
-- GameEvent.Crewed is written as the cost is paid, so a crew ability that never
-- resolves still leaves the relation behind.
crewedThisTurn :: ObjectId -> GameState -> Set.Set ObjectId
crewedThisTurn oid gs =
  let crewedByIt event = case event of
        GameEvent.Crewed crewed
          | Set.member oid (Crewing.crewedBy crewed) -> Just (Crewing.vehicle crewed)
        _ -> Nothing
   in Set.fromList (Maybe.mapMaybe (crewedByIt . LoggedEvent.event) (Foldable.toList (GameState.events gs)))

-- CR 702.171c: crewedThisTurn one keyword over, for the Mounts this object
-- saddled.
saddledThisTurn :: ObjectId -> GameState -> Set.Set ObjectId
saddledThisTurn oid gs =
  let saddledByIt event = case event of
        GameEvent.Saddled saddled
          | Set.member oid (Saddling.saddledBy saddled) -> Just (Saddling.mount saddled)
        _ -> Nothing
   in Set.fromList (Maybe.mapMaybe (saddledByIt . LoggedEvent.event) (Foldable.toList (GameState.events gs)))

-- CR 120.1 / 608.2i: whom this object dealt damage to this turn -- every
-- recipient of a damage event it was the source of, through
-- Game.damageRecipient so CR 120.8's zero is no damage here either. The
-- recipient is the one the damage was finally dealt to, so CR 614.9's
-- redirection counts against where it landed. Each recipient rides beside the
-- event's kind (CR 510 / 608), for a card that asks about combat damage alone.
dealtDamageTo :: ObjectId -> GameState -> Set.Set (Recipient.Recipient, DamageKind.DamageKind)
dealtDamageTo oid gs =
  let byIt event = case event of
        GameEvent.DamageDealt ev | DamageEvent.source ev == oid -> fmap (\recipient -> (recipient, DamageEvent.kind ev)) (Game.damageRecipient event)
        _ -> Nothing
   in Set.fromList (Maybe.mapMaybe (byIt . LoggedEvent.event) (Foldable.toList (GameState.events gs)))

-- CR 120.1 / 400.7: the same answer for every earlier turn of the game. An id
-- names one object for its whole life, so the earlier turns' damage by this id
-- is damage by this object.
dealtDamageEarlier :: ObjectId -> GameState -> Set.Set (Recipient.Recipient, DamageKind.DamageKind)
dealtDamageEarlier oid gs =
  Set.fromList [(DamageEvent.target ev, DamageEvent.kind ev) | ev <- Foldable.toList (GameState.damageBeforeThisTurn gs), DamageEvent.source ev == oid]

-- CR 702.51c: which spells did this object convoke, and which permanents did
-- those spells become? GameEvent.Convoked is written as the cast's cost is paid
-- and names the SPELL, which CR 400.7 ends the moment it resolves -- so a
-- permanent's own entry trigger asking "each creature that convoked it"
-- (Venerated Loxodon) would find nothing to compare against. The BECAME hop is
-- CR 400.7d -- "an ability of a permanent can reference information about the
-- spell that became that permanent as it resolved, including what costs were
-- paid to cast that spell" -- and the becoming is read off the same log:
-- Parun.Engine.Event records the stack-to-battlefield move as a GameEvent.Moved
-- whose `departed` is the spell.
--
-- Both ends are kept, so an effect that reads the relation while the spell is
-- still on the stack answers too. A spell that never resolved contributes only
-- itself. Parun.Engine.Filter's ConvokedSourceThisTurn compares the set against
-- the source it is evaluating for.
convokedThisTurn :: ObjectId -> GameState -> Set.Set ObjectId
convokedThisTurn oid gs =
  let events = fmap LoggedEvent.event (Foldable.toList (GameState.events gs))
      convokedByIt event = case event of
        GameEvent.Convoked convoked
          | Set.member oid (Convoking.convokedBy convoked) -> Just (Convoking.spell convoked)
        _ -> Nothing
      spells = Maybe.mapMaybe convokedByIt events
   in Set.fromList (concatMap (\spell -> spell : becamePermanents spell events) spells)

-- CR 400.7d's "the spell that became that permanent", asked the other way
-- round: the permanents one object became by resolving off the stack, read
-- off the move log. A list rather than a Maybe for CR 712.21's several arrivals,
-- which no permanent spell reaches today.
becamePermanents :: ObjectId -> [GameEvent.GameEvent] -> [ObjectId]
becamePermanents spell events =
  [ arrival
  | GameEvent.Moved m <- events,
    let zc = Moved.change m,
    ZoneChange.departed zc == spell,
    ZoneChange.to zc == Zone.Battlefield,
    -- "as it resolved": a countered card put onto the battlefield instead
    -- (Desertion) is not the permanent the spell became.
    Moved.duringResolution m,
    arrival <- Foldable.toList (Moved.arrivals m)
  ]

-- CR 602.1: every activated ability a set of characteristics gives,
-- Keyword.activatedAbilitiesOf over the projection's own list and rule 702's
-- battlefield mint, which no CR 612 text change reaches (Projection's
-- mintedTriggeredAbilitiesOf says why). CR
-- 804.2's where `deploys`, which the caller decides: Deploy.grants over the
-- characteristics, and only for a permanent (CR 109.2).
--
-- The hand and graveyard mints take no text change either.
abilitiesOf :: Bool -> PC.ProjectedCharacteristics -> [ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)]
abilitiesOf deploys pc =
  Keyword.activatedAbilitiesOf
    deploys
    (Map.keysSet (PC.keywords pc))
    (PC.activatedAbilities pc <> Keyword.battlefieldAbilitiesOf (PC.keywords pc))

-- CR 602.2 / 608.2i: an object one of the turn's past activations recorded
-- (Parun.Types.PastActivation), seen as it was when the activation began rather
-- than as it is now. The zone as recorded, so CR 109.2's "a creature you
-- control" passes over an earlier activation that targeted a creature SPELL.
-- CR 113.6p's home beside it is what Synthetic First Rehearsal's "whose source
-- has an activated ability" reads (data/scenarios/vanguard's past-activation
-- scenario); CR 604.2's lapsed sample is a regression fence.
pastView :: ObjectSnapshot.ObjectSnapshot -> Filter.View
pastView snapshot =
  (viewOfSnapshot False (ObjectSnapshot.controller snapshot) (Just (ObjectSnapshot.owner snapshot)) False Map.empty (ObjectSnapshot.zone snapshot) (ObjectSnapshot.home snapshot) (ObjectSnapshot.lapsedGrants snapshot) (ObjectSnapshot.characteristics snapshot))
    { Filter.identity = Just (ObjectSnapshot.object snapshot),
      Filter.zone = Just (ObjectSnapshot.zone snapshot)
    }

-- What only the ABILITY of a past activation can answer
-- (Parun.Types.ActivationCriteria): its rule-702 keyword, CR 605.1a's kind and
-- CR 606.2's loyalty, the last off the printed cost as
-- Parun.Engine.Loyalty.loyaltyKindOf reads it for the activation in progress.
-- CR 305.6's intrinsic mana route records no ability, and is no loyalty ability.
--
-- The loyalty conjunct is a regression fence for The Chain Veil's "loyalty
-- ability of a planeswalker": no card in data/cards/ gives a planeswalker a
-- non-loyalty activated ability. Kaito, Bane of Nightmares' ninjutsu would
-- (AtomicCards.json, 2026-10-27, planeswalkers whose text has such a line).
-- The planeswalker half of that phrase is the source filter's, which Luxior,
-- Giada's Gift observes (data/scenarios/the-chain-veil).
activationMeets :: ActivationCriteria.ActivationCriteria -> PastActivation.PastActivation -> Bool
activationMeets criteria past =
  maybe True (\g -> any (Keyword.designates g) (ActivatedAbility.keyword =<< PastActivation.ability past)) (ActivationCriteria.grantedBy criteria)
    && maybe True (== PastActivation.kind past) (ActivationCriteria.whichKind criteria)
    && maybe True (== maybe LoyaltyKind.NonLoyaltyAbility (Loyalty.loyaltyKindOf . ActivatedAbility.cost) (PastActivation.ability past)) (ActivationCriteria.whichLoyalty criteria)

-- The Filter.View a recorded snapshot yields, shared by every arm of
-- snapshotView above so that two shapes of event cannot disagree about what a
-- snapshot says. The `controller`, the OWNER, the tokenhood flag and the counters
-- are the arm's to supply, since they are the four fields no
-- ProjectedCharacteristics carries (CR 109.3 / CR 108.3 / CR 111.6 / CR 122.1)
-- and the events differ on where each is recoverable from.
--
-- `deploy` says whether CR 804.2 reaches the snapshot: the game uses the option
-- and the snapshot is of a permanent (CR 109.2).
--
-- `zone` with `home`, and `lapsed`, are CR 604.2's two halves of an "as long
-- as" grant, as they stood when the snapshot was taken: the zone the object was
-- in and the one its unstated abilities functioned in
-- (AbilityZone.grantFunctionsIn, CR 113.6 / 113.6p), and the clauses that did
-- not hold there
-- (Projection.View.lapsedGrantsOf), since the snapshot carries each granted
-- ability with its clause unasked.
viewOfSnapshot :: Bool -> Maybe PlayerId -> Maybe PlayerId -> Bool -> Map.Map (CounterKind.CounterKind Keyword.Type.Keyword) Natural.Natural -> Zone.Zone -> Zone.Zone -> Set.Set Condition.Condition -> PC.ProjectedCharacteristics -> Filter.View
viewOfSnapshot deploy mController mOwner isToken counters zone home lapsed snapshot =
  Filter.MkView
    { -- CR 201.1 off the snapshot, which carries the set: this reads what the
      -- object's names were AT THE EVENT, which is the whole point of a snapshot.
      Filter.names = PC.names snapshot,
      Filter.cardTypes = PC.cardTypes snapshot,
      -- CR 205.4a off the snapshot, beside the card types it qualifies: a
      -- supertype IS a characteristic (CR 109.3), so a past event has a real
      -- answer to give and Relic Runner's "historic" reads the Legendary
      -- disjunct off it (Parun.CountSpec).
      Filter.supertypes = PC.supertypes snapshot,
      Filter.colors = PC.colors snapshot,
      Filter.subtypes = PC.subtypes snapshot,
      Filter.keywords = Map.keysSet (PC.keywords snapshot),
      Filter.power = PC.power snapshot,
      Filter.toughness = PC.toughness snapshot,
      Filter.intensity = PC.intensity snapshot,
      -- CR 202.3 off the snapshot, which carries the number: a
      -- ProjectedCharacteristics records a mana value, so this reads what the
      -- object's was AT THE EVENT rather than throwing the question away.
      --
      -- Nothing means the snapshot recorded no mana value, which no projection
      -- writes: CR 202.3a gives even an object with no card behind it a 0
      -- (Projection.View.baseCharacteristics), so a Nothing here is a
      -- hand-built ProjectedCharacteristics rather than a rule's answer.
      Filter.manaValue = PC.manaValue snapshot,
      -- CR 202.1 off the snapshot beside the value it totals, so CR 700.5's
      -- devotion reads what the object's cost was AT THE EVENT.
      Filter.manaCost = PC.manaCost snapshot,
      Filter.controller = mController,
      -- CR 108.3: an owner is read off an OBJECT and a ProjectedCharacteristics
      -- carries none, so it is the arm's to supply off CR 608.2h's record, as
      -- `counters` below is. Dimir Strandcatcher's "put into YOUR graveyard" is
      -- what reads it, CR 400.3 keying that zone by owner (Parun.CountSpec).
      --
      -- The SpellCast arm supplies it too, off Game.ownerWithLastKnown rather than off a
      -- record alone, since a spell still on the stack has none.
      Filter.owner = mOwner,
      -- CR 400.1: a snapshot records characteristics (CR 608.2h) and no zone, and
      -- the object it was taken of has since moved or ceased to exist, so IsInZone
      -- is vacuously False against one.
      Filter.zone = Nothing,
      -- CR 601.2a: a snapshot records characteristics and no zone at all, so it
      -- cannot say where a cast came from either -- `zone` above's reason.
      Filter.castFrom = Nothing,
      -- CR 115.1: a snapshot is of an object that has left the stack or never
      -- was on it, and records no announcement -- `zone` above's reason.
      Filter.targets = Set.empty,
      Filter.targetViews = Map.empty,
      Filter.targetCount = 0,
      Filter.identity = Nothing,
      Filter.playerIdentity = Nothing,
      Filter.attacking = False,
      -- CR 508.1b: nothing a snapshot holds says what was attacked, for the
      -- reason `attacking` above is False.
      Filter.attackingPlayer = Nothing,
      -- CR 508.1b: nothing a snapshot holds says what was attacked, for the reason
      -- the field above is Nothing.
      Filter.attackingPlaneswalkerController = Nothing,
      -- CR 310.9d: nor who protected a battle, for the reason the field above is
      -- Nothing.
      Filter.attackingBattleProtector = Nothing,
      -- CR 508.3b: whether the candidate was declared attacked is no more a
      -- characteristic than `attacking` above is, so a snapshot has nothing to
      -- answer it with either.
      Filter.declaredAttackedThisCombat = False,
      Filter.blocking = False,
      Filter.blockStatus = Nothing,
      Filter.blockers = Set.empty,
      Filter.blocked = Set.empty,
      Filter.declaredThisTurn = Set.empty,
      Filter.couldAttackThisTurn = False,
      -- CR 508.1a / 509.1a: a snapshot is CR 608.2h's record of an object, and
      -- combat status is no characteristic of one (CR 109.3), so it has nothing
      -- to answer with -- `attacking` and `blocking` above take the same
      -- posture.
      Filter.declaredAttackerThisCombat = False,
      Filter.declaredBlockerThisCombat = False,
      -- CR 701.17a mills a CARD, and this view describes a snapshot rather than
      -- an object -- there is no id here for the turn's mills to have named.
      Filter.milledThisTurn = False,
      -- CR 120.1 damages an OBJECT, and this view describes a snapshot rather
      -- than one -- there is no id here for the turn's damage to have named.
      Filter.dealtDamageThisTurn = False,
      -- CR 400.7 enters an OBJECT, and this view describes a snapshot rather
      -- than one -- `milledThisTurn` above's reason again.
      Filter.arrivalThisTurn = Nothing,
      -- CR 702.122c relates two OBJECTS, and this view describes a snapshot
      -- rather than one -- `milledThisTurn` above's reason again.
      Filter.crewedThisTurn = Set.empty,
      Filter.convokedThisTurn = Set.empty,
      Filter.saddledThisTurn = Set.empty,
      Filter.dealtDamageTo = Set.empty,
      Filter.dealtDamageEarlier = Set.empty,
      -- CR 302.6 asks about an OBJECT under a player's control; this view
      -- describes a snapshot rather than one -- `milledThisTurn` above's reason.
      Filter.controlledSinceTurnBegan = False,
      -- CR 303.4 / 110.1: a snapshot is not an object on the battlefield and
      -- carries no attachment, so there is no host here for AttachedTo's nest.
      Filter.attachedToView = Nothing,
      -- CR 303.4b's mirror: nothing is attached to a snapshot either, there being
      -- no object here for a permanent's Object.attachedTo to have named.
      Filter.attachedViews = [],
      Filter.attachedTo = Nothing,
      -- CR 701.3a, both directions: a snapshot is neither an attach's destination
      -- nor a search's candidate, so nothing framed it as either.
      Filter.canHostSubject = False,
      Filter.canAttachToSubject = False,
      -- CR 111.6: "A token isn't a card", which is a fact about the OBJECT and
      -- not a characteristic, so the arm supplies it above.
      Filter.token = isToken,
      -- CR 903.3's designation is recoverable only from an OBJECT, which a
      -- ProjectedCharacteristics is not -- `owner` above's situation one rule
      -- over, and no arm passes one. So IsCommander is vacuously false of a
      -- snapshot, which no card in `data/cards/` notices: every printed
      -- "commander creatures you own" is a battlefield static ability.
      Filter.commander = False,
      -- CR 113.3b: CR 608.2h's record is of characteristics rather than of an
      -- object on the stack, so there is no ability here to be either kind.
      Filter.activatedAbility = Nothing,
      -- CR 113.1c, the line above widened: still no ability on the stack here to
      -- be one of either kind.
      Filter.ability = False,
      -- CR 114.5, the two lines above's reason one rule over: CR 608.2h's record
      -- is of CHARACTERISTICS, and being an emblem is none of the ones CR 109.3
      -- lists, so nothing a snapshot holds can say it was taken of one. NOT that
      -- an emblem has no characteristics -- CR 114.3 leaves it the abilities its
      -- creating effect defined, which CR 109.3 counts as characteristics.
      Filter.emblem = False,
      -- CR 113.7, for the line above's reason: no ability, so no source.
      Filter.abilitySource = Nothing,
      Filter.tapped = False,
      -- CR 110.5a says status is not a characteristic, and CR 608.2h's record is
      -- of characteristics -- so a snapshot holds nothing to answer this with,
      -- `tapped` above's reason one status category over.
      Filter.faceDown = False,
      -- CR 608.2h's record holds characteristics rather than the card that carried
      -- them, so there is no printed face here for CR 708.12 to read -- `faceDown`
      -- above's reason, one rule over.
      Filter.representedCard = Nothing,
      -- CR 406.3's exiled-face-down rider is written onto an OBJECT on its way
      -- into exile, and a snapshot holds no object -- `faceDown` above's reason,
      -- one rule over.
      Filter.exiledFaceDown = False,
      -- CR 701.27g asks about a permanent ON THE BATTLEFIELD, and a snapshot is
      -- a record of a past event rather than an object standing on one -- there
      -- is no id here to ask which face is up. No card in the pool counts
      -- transformed permanents through Scope.InHistory, so nothing observes the
      -- difference between this and an answer the rule could give.
      Filter.transformed = False,
      -- CR 122.1: a ProjectedCharacteristics records no counters -- CR 613.4c
      -- has already folded them into the power and toughness above, which is
      -- lossy in both directions -- so this comes from the arm, off CR 608.2h's
      -- record for a move and empty for a cast. Synthetic Charnel Tally's
      -- "greatest number of counters among creatures that died this turn"
      -- (Parun.CountSpec) is what reads it.
      Filter.counters = counters,
      -- Not implemented: CR 608.2h's record of a departed object's stickers
      -- (#4890).
      Filter.stickers = Seq.empty,
      -- CR 701.54b: a designation, which a ProjectedCharacteristics does not carry
      -- and never could -- CR 109.3's characteristic list has no room for one. So a
      -- past event records none, and no CR 608.2h record holds one for the arm to
      -- supply the way it supplies `counters` above -- `owner`'s position, one
      -- field of that record short. Nothing rather than a remembered player: an
      -- event snapshot is not an object, and "is your Ring-bearer" is a question
      -- about a permanent on the battlefield now (CR 701.54e), not about one at
      -- the moment of an event.
      Filter.ringBearerFor = Nothing,
      Filter.paired = Nothing,
      Filter.designations = Set.empty,
      -- CR 701.37c's X rides the designation, so a past event records none --
      -- `designations` above, same sentence.
      Filter.designationValues = Map.empty,
      Filter.storedResults = Map.empty,
      -- CR 716.2b: a designation too, which a ProjectedCharacteristics does not
      -- carry and never could, so a past event records none -- `designations`
      -- above, same sentence.
      Filter.classLevel = Nothing,
      Filter.paidCosts = Map.empty,
      -- CR 702.104b's record is a field of an OBJECT, which a
      -- ProjectedCharacteristics does not carry -- `designations` above, same
      -- sentence -- so a past event reports none.
      Filter.tributePaid = False,
      Filter.castUsing = Nothing,
      -- CR 702.143c's record is a field of an OBJECT -- `tributePaid` above.
      Filter.foretold = False,
      -- CR 718.3c / 718.3d off the snapshot, which carries a copy's answer. The
      -- object's own flag is a field of an OBJECT, which lastKnownView adds. A
      -- regression fence: no card asks it of a snapshot.
      Filter.prototyped = PC.prototyped snapshot,
      -- CR 400.7d's mana record is a field of an OBJECT, which a
      -- ProjectedCharacteristics does not carry -- `designations` above, same
      -- sentence -- so a past event reports none.
      Filter.manaSpentTagColors = Map.empty,
      -- The same field one question over -- `manaSpentTagColors` above, same sentence.
      Filter.manaSpentAmount = 0,
      -- CR 602.1 / 605.1a off the snapshot, which is what it reads for `keywords`
      -- and `power` too -- so this answers what the object HAD at the event,
      -- through abilitiesOf, the roster every view builder reads, less what CR
      -- 604.2 withheld (snapshotRoster).
      Filter.activatedAbilityKinds = ManaAbility.abilityKinds (Subtype.intrinsicManaAbilityOf snapshot) (snapshotRoster deploy zone home lapsed snapshot),
      -- CR 702.184c off the snapshot, which carries the field: the marker
      -- outlives the object exactly as a keyword or a P/T does.
      Filter.grantsStationToughness = PC.grantsStationToughness snapshot
    }

-- CR 604.2: a snapshot's activated abilities less those whose "as long as"
-- grant did not function in the zone it was taken in, given the `home` CR
-- 113.6p recorded beside it, or whose clause had lapsed there.
-- data/scenarios/vanguard's past-activation scenario, a Synthetic Steward
-- Avatar activated twice under Synthetic First Rehearsal, proves the home.
snapshotRoster :: Bool -> Zone.Zone -> Zone.Zone -> Set.Set Condition.Condition -> PC.ProjectedCharacteristics -> [ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)]
snapshotRoster deploy zone home lapsed snapshot =
  let functions = AbilityZone.grantFunctionsIn home (PC.delayedAbilities snapshot) zone
   in filter (\ability -> functions ability && grantHeld lapsed ability) (abilitiesOf (Deploy.grants deploy snapshot) snapshot)

-- CR 604.2: is this ability granted, given the "as long as" clauses a sample
-- recorded as lapsed? An ability with no clause always is.
grantHeld :: Set.Set Condition.Condition -> ActivatedAbility.ActivatedAbility card ability -> Bool
grantHeld lapsed = maybe True (`Set.notMember` lapsed) . ActivatedAbility.condition

-- | The live view of an object with a sample's CHARACTERISTICS written over it,
-- for an event whose object is still there to be asked about but whose
-- characteristics the rule pins to the moment of the event -- CR 701.27e's "has
-- the specified characteristic immediately after it does so", read by
-- Parun.Engine.Event's TriggerCondition.PermanentTransforms arm.
--
-- Not viewOfSnapshot alone, and that is the whole point: CR 109.3 names an
-- object's controller and what an Aura enchants among the things that are NOT
-- characteristics, and a zone is no more one (CR 400.1), so a snapshot has
-- nothing to say about them and a Filter naming one would go silently False.
-- Those come from the view this is handed, which CR 603.10 also pins to
-- immediately after the event: the PermanentTransforms arm writes the sampled
-- controller onto the live view BEFORE calling this, and the sampled attachments
-- over the result afterwards.
--
-- AN EDIT SITE, and the sampled half is built by calling viewOfSnapshot so that
-- the VALUES cannot disagree -- but the list of fields below is a second
-- hand-kept copy of which of them the snapshot answers. A field added to
-- viewOfSnapshot's PC-derived set and not to this record update is silently read
-- LIVE here, and neither -Werror nor any test says so. Keep the two in step.
--
-- `lapsed` is CR 604.2's sample beside the snapshot (viewOfSnapshot), and the
-- zone the battlefield, the only one a permanent turns over in.
overlaySnapshot :: Bool -> Set.Set Condition.Condition -> PC.ProjectedCharacteristics -> Filter.View -> Filter.View
overlaySnapshot deploy lapsed snapshot live =
  let sampled = viewOfSnapshot deploy (Filter.controller live) (Filter.owner live) (Filter.token live) (Filter.counters live) Zone.Battlefield Zone.Battlefield lapsed snapshot
   in live
        { Filter.names = Filter.names sampled,
          Filter.cardTypes = Filter.cardTypes sampled,
          Filter.supertypes = Filter.supertypes sampled,
          Filter.colors = Filter.colors sampled,
          Filter.subtypes = Filter.subtypes sampled,
          Filter.keywords = Filter.keywords sampled,
          Filter.power = Filter.power sampled,
          Filter.toughness = Filter.toughness sampled,
          Filter.intensity = Filter.intensity sampled,
          Filter.manaValue = Filter.manaValue sampled,
          Filter.manaCost = Filter.manaCost sampled,
          Filter.activatedAbilityKinds = Filter.activatedAbilityKinds sampled,
          Filter.grantsStationToughness = Filter.grantsStationToughness sampled
        }

-- Does CR 804.2 reach an object snapshotted as it left, or while it was in,
-- this zone? Only a permanent's (CR 109.2), and only in a game using the option.
deployIn :: GameState -> Zone.Zone -> Bool
deployIn gs zone = zone == Zone.Battlefield && GameSettings.deployCreatures (GameState.settings gs)
