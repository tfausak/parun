-- Parun.Engine.Card's lints over where a filter atom may appear: the context-
-- relative atoms from CanHostSubject to Specific PlayerRef, each admitted only
-- at the positions whose context fills what it reads, and the lints that catch
-- one elsewhere. Split out of Parun.CardSpec, which keeps the machinery and the
-- filter traversals these walk.
module Parun.FilterPositionLintSpec where

import qualified Control.Monad as Monad
import qualified Data.Foldable as Foldable
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Monoid as Monoid
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Parun.CardSpec (Framing (ActivationCostFramed, AffectedSetFramed, AttachDestination, ChosenSourceFramed, ClauseGateFramed, EntryAttachDestination, HandSweepFramed, InTargetSlot, KeywordFramed, LifeLossAmountFramed, ManaRestrictionFramed, MillTallyFramed, MintedTargetSlot, OutsideTheGameFramed, PlayerEffectFramed, ReplacementRowFramed, SearchFramed, SlotlessCostFramed, SourceHostFramed, StandingHostFramed, StoredClassFramed, StoredPlayerEffectFramed, TriggerConditionFramed, Unframed), anyFace, cardCounts, cardFilters, cardResolutionEffects, conditionFilters, counterKindFilters, durationFilters, effectFilters, entryRewriteFilters, filterSlotsReadSingly, framedSlotsReadSingly, keywordFilters, modalFilters, objectRefFilters, oneEffectTrigger, oneFaced, payGateFilters, quantityFilters, replacementEffectFilters, riderFilters, triggerConditionFilters, turnUpRewriteFilters)
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Face as Face.Codec
import qualified Parun.Codec.Filter as Filter.Codec
import qualified Parun.Codec.Keyword as Keyword.Codec
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator.Codec
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Keyword as Keyword.Engine
import qualified Parun.Engine.Mint as Mint
import qualified Parun.Json.Array as Array
import qualified Parun.Json.Object as Object
import qualified Parun.Json.Pair as Pair
import qualified Parun.Json.String as String
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.AffectPlayers as AffectPlayers
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AloneUnless as AloneUnless
import qualified Parun.Types.AlternativeCost as AlternativeCost
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.AttachTarget as AttachTarget
import qualified Parun.Types.AttackCost as AttackCost
import qualified Parun.Types.AttackCostScope as AttackCostScope
import qualified Parun.Types.BlockCost as BlockCost
import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.CantBlockCreatures as CantBlockCreatures
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChooseCardName as ChooseCardName
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.ChosenQuality as ChosenQuality
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition.Type
import qualified Parun.Types.Conjure as Conjure
import qualified Parun.Types.ConjureCards as ConjureCards
import qualified Parun.Types.ConjureDestination as ConjureDestination
import qualified Parun.Types.ConjureEntry as ConjureEntry
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.Count as Count.Type
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPattern as CounterPattern
import qualified Parun.Types.CounterPlacement as CounterPlacement
import qualified Parun.Types.CounterR as CounterR
import qualified Parun.Types.CounterRestriction as CounterRestriction
import qualified Parun.Types.CounterSubject as CounterSubject
import qualified Parun.Types.Create as Create
import qualified Parun.Types.Cycling as Cycling
import qualified Parun.Types.Destroy as Destroy
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.EachCardInHand as EachCardInHand
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntersWith as EntersWith
import qualified Parun.Types.EntryFlip as EntryFlip
import qualified Parun.Types.EntryOption as EntryOption
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.Equip as Equip
import qualified Parun.Types.EquipTarget as EquipTarget
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.FromReference as FromReference
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HandAction as HandAction
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.MillTally as MillTally
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveCounters as MoveCounters
import qualified Parun.Types.MovedKinds as MovedKinds
import qualified Parun.Types.NameChooser as NameChooser
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.PayBranch as PayBranch
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation
import qualified Parun.Types.PerCreature as PerCreature
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.PutCountersFrom as PutCountersFrom
import qualified Parun.Types.Quantity as Quantity.Type
import qualified Parun.Types.Regenerability as Regenerability
import qualified Parun.Types.RemovalCount as RemovalCount
import qualified Parun.Types.RemoveCounters as RemoveCounters
import qualified Parun.Types.RemoveCountersAmong as RemoveCountersAmong
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.Reveal as Reveal
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.SacrificeAnyNumber as SacrificeAnyNumber
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.Scaling as Scaling
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Search as Search
import qualified Parun.Types.SearchDestination as SearchDestination
import qualified Parun.Types.SelfCountersReached as SelfCountersReached
import qualified Parun.Types.SelfCountersRemoved as SelfCountersRemoved
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpecialAction as SpecialAction
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.Tap as Tap
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TopOfLibrary as TopOfLibrary
import qualified Parun.Types.TopOfLibraryUntil as TopOfLibraryUntil
import qualified Parun.Types.Trait as Trait
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnRole as TurnRole
import qualified Parun.Types.TurnUpRewrite as TurnUpRewrite
import qualified Parun.Types.WhichCounters as WhichCounters
import qualified Parun.Types.WithCounters as WithCounters
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneScope as ZoneScope

-- The zone set of every search a face authors (CR 701.23a). A wildcard rather
-- than one arm per effect, as storedPlayerScope takes: Parun.Types.Effect is the
-- open half's alphabet, and a new opcode is not a new search.
searchZoneSets :: Face.Face Card.Type.Card -> [Set.Set Zone.Zone]
searchZoneSets =
  let zonesOf effect = case effect of
        Effect.Search search -> Just (Search.zones search)
        _ -> Nothing
   in Maybe.mapMaybe zonesOf . cardResolutionEffects

-- CR 701.3a's Filter.CanHostSubject, counted wherever it appears inside ONE
-- Filter: under And/Or/Not, and inside the typecycling predicate a HasKeyword
-- atom's own keyword may carry (CR 702.29e).
--
-- Counted rather than merely detected, because the completeness cross-check below
-- compares this hand-maintained traversal against the codec's independent one,
-- and that comparison needs a number.
canHostSubjects :: Filter.Type.Filter Keyword.Keyword -> Int
canHostSubjects =
  Monoid.getSum
    . filterAtomsOf
      ( \atom -> case atom of
          Filter.Type.CanHostSubject -> Monoid.Sum 1
          _ -> Monoid.Sum 0
      )

-- Every ATOM inside ONE Filter, each handed to `leaf` and the answers combined:
-- under And/Or/Not and into every nest a card author can write a Filter into,
-- the keyword payloads included (CR 702.29e). The typed walk the per-atom lints
-- share (canHostSubjects, Parun.AbilitySlotLintSpec's exile-pile names).
--
-- Written out exhaustively rather than with a catch-all, so a later atom that can
-- hold a Filter fails to compile here instead of silently hiding one.
filterAtomsOf :: (Monoid m) => (Filter.Type.Filter Keyword.Keyword -> m) -> Filter.Type.Filter Keyword.Keyword -> m
filterAtomsOf leaf predicate = case predicate of
  Filter.Type.CanHostSubject -> leaf predicate
  Filter.Type.And fs -> foldMap (filterAtomsOf leaf) fs
  Filter.Type.Or fs -> foldMap (filterAtomsOf leaf) fs
  Filter.Type.Not f -> filterAtomsOf leaf f
  Filter.Type.Unwritten f -> filterAtomsOf leaf f
  -- A Filter position like the combinators above, and the only ATOM that is one:
  -- CR 110.2's comparison carries the description of what is being counted, which
  -- a card author writes exactly as they write any other filter.
  Filter.Type.Controls _ f -> filterAtomsOf leaf f
  -- CR 702.29e's "[type]cycling" carries a Filter of its own, and any Cost a
  -- keyword names can carry one through a Sacrifice component. Never EVALUATED
  -- against a candidate -- HasKeyword asks whether the key is present in the
  -- projection's keyword map, so what is inside the keyword is compared and not
  -- run -- but still a Filter position a card author can write the atom into,
  -- which is the only thing this lint is about.
  Filter.Type.HasKeyword keyword -> foldMap (filterAtomsOf leaf . snd) (keywordFilters keyword)
  -- CR 122.1b's keyword counter carries a whole Keyword, so a Filter can hide one
  -- level further down than the atom above -- and this lint is about the
  -- positions, not about which of them a card has used.
  Filter.Type.HasCounters kind -> case kind of
    CounterKind.Keyword keyword -> foldMap (filterAtomsOf leaf . snd) (keywordFilters keyword)
    CounterKind.PlusOnePlusOne -> leaf predicate
    CounterKind.MinusOneMinusOne -> leaf predicate
    CounterKind.Loyalty -> leaf predicate
    CounterKind.Lore -> leaf predicate
    CounterKind.Defense -> leaf predicate
    CounterKind.Time -> leaf predicate
    CounterKind.Fade -> leaf predicate
    CounterKind.Age -> leaf predicate
    CounterKind.Shield -> leaf predicate
    CounterKind.Finality -> leaf predicate
    CounterKind.Stun -> leaf predicate
    CounterKind.Level -> leaf predicate
    CounterKind.Hone -> leaf predicate
    CounterKind.UnsafePowerToughness _ _ -> leaf predicate
    CounterKind.Named _ -> leaf predicate
  -- A leaf for the reason the FAMILY below is: this atom is payload-free, so there
  -- is no Filter position inside it for a card author to reach -- the descent
  -- above exists only because a CounterKind can carry a Keyword.
  Filter.Type.HasCountersOfAnyKind -> leaf predicate
  Filter.Type.HasSticker _ -> leaf predicate
  Filter.Type.Stickered -> leaf predicate
  -- A leaf and not a descent, unlike the atom above: a family is payload-free, so
  -- there is no Filter position inside it for a card author to reach.
  Filter.Type.HasKeywordFamily _ -> leaf predicate
  Filter.Type.HasCardType _ -> leaf predicate
  Filter.Type.HasSupertype _ -> leaf predicate
  Filter.Type.HasColor _ -> leaf predicate
  Filter.Type.Shares _ _ -> leaf predicate
  Filter.Type.HasSubtype _ -> leaf predicate
  Filter.Type.HasName _ -> leaf predicate
  Filter.Type.NameWordsAtLeast _ -> leaf predicate
  Filter.Type.HasNameOriginallyPrintedIn _ -> leaf predicate
  Filter.Type.Measures _ -> leaf predicate
  Filter.Type.ControlledByRole _ -> leaf predicate
  -- A leaf: a Holder and a PlayerRelation hold no Filter for a card author to
  -- reach.
  Filter.Type.HeldBy _ _ -> leaf predicate
  -- A leaf for HeldBy's reason: one carries a slot name and the other a
  -- PlayerId, and neither holds a Filter for a card author to reach.
  Filter.Type.HeldByBound _ _ -> leaf predicate
  Filter.Type.HeldByPlayer _ _ -> leaf predicate
  -- A leaf for the two above's reason: a Holder holds no Filter for a card
  -- author to reach.
  Filter.Type.HeldByRecipient _ -> leaf predicate
  Filter.Type.ManaValueIsEven -> leaf predicate
  Filter.Type.IsSource -> leaf predicate
  Filter.Type.IsObject _ -> leaf predicate
  Filter.Type.TargetsSource -> leaf predicate
  Filter.Type.HasSingleTarget -> leaf predicate
  -- A DESCENT and not a leaf, for AttachedTo's reason below: CR 115.1's atom
  -- carries the one target's description, a Filter position a card author
  -- writes into like any other.
  Filter.Type.TargetsOnlyOne f -> filterAtomsOf leaf f
  Filter.Type.TargetsMatching f -> filterAtomsOf leaf f
  Filter.Type.TargetsPlayer _ -> leaf predicate
  Filter.Type.IsPlayer _ -> leaf predicate
  Filter.Type.IsBound _ -> leaf predicate
  Filter.Type.IsTarget -> leaf predicate
  Filter.Type.ControllerRelatesToBound _ _ -> leaf predicate
  Filter.Type.SameControllerAsHostOfBound _ -> leaf predicate
  Filter.Type.HasChosenName {} -> leaf predicate
  Filter.Type.HasChosenColor -> leaf predicate
  Filter.Type.HasChosenSubtype -> leaf predicate
  Filter.Type.IsExiledWithSource _ -> leaf predicate
  Filter.Type.IsLastExiledWithSource -> leaf predicate
  Filter.Type.OfChosenPlayer -> leaf predicate
  Filter.Type.OfRelatedPlayer _ -> leaf predicate
  Filter.Type.IsControllerOfBound _ -> leaf predicate
  -- A leaf for the nullary atoms' reason, a payload over: CR 400.1's card count is
  -- a Natural, which holds no Filter for a card author to reach.
  Filter.Type.CardsInGraveyardAtLeast _ -> leaf predicate
  Filter.Type.IsAttacking -> leaf predicate
  Filter.Type.IsAttackingPlayer _ -> leaf predicate
  Filter.Type.IsAttackingPlaneswalker _ -> leaf predicate
  Filter.Type.IsAttackingBattle _ -> leaf predicate
  Filter.Type.DeclaredAttackedThisCombat -> leaf predicate
  Filter.Type.IsBlocking -> leaf predicate
  Filter.Type.HasBlockStatus _ -> leaf predicate
  Filter.Type.AttackedThisTurn -> leaf predicate
  Filter.Type.CouldAttackThisTurn -> leaf predicate
  Filter.Type.DeclaredAttackerThisCombat -> leaf predicate
  Filter.Type.DeclaredBlockerThisCombat -> leaf predicate
  Filter.Type.MilledThisTurn -> leaf predicate
  Filter.Type.CantCrewVehicles -> leaf predicate
  Filter.Type.DealtDamageThisTurn -> leaf predicate
  Filter.Type.DealtDamageToThisTurn _ -> leaf predicate
  Filter.Type.EnteredThisTurn _ -> leaf predicate
  Filter.Type.CrewedSourceThisTurn -> leaf predicate
  Filter.Type.ConvokedSourceThisTurn -> leaf predicate
  Filter.Type.SaddledSourceThisTurn -> leaf predicate
  Filter.Type.ControlledSinceTurnBegan -> leaf predicate
  -- A DESCENT and not a leaf, unlike every other atom here: CR 303.4's atom
  -- carries the host's description, which a card author writes exactly as they
  -- write any other filter. A leaf would under-count against jsonAtoms, which counts
  -- the tag at any depth, and turn a legitimate card into a reported offence.
  Filter.Type.AttachedTo f -> filterAtomsOf leaf f
  -- A DESCENT for the atom above's reason, the nest describing the ATTACHER: CR
  -- 303.4b's atom is a Filter position a card author writes into like any other.
  Filter.Type.HasAttached f -> filterAtomsOf leaf f
  Filter.Type.IsAttachedTo _ -> leaf predicate
  Filter.Type.IsEvaluated -> leaf predicate
  Filter.Type.IsHostOfSource -> leaf predicate
  Filter.Type.EnteredWithSource -> leaf predicate
  Filter.Type.AttachedNoLaterThanSource -> leaf predicate
  -- A leaf: the MIRROR atom is not this one, and its own lint counts it through the
  -- codec (canAttachToSubjectCounts) rather than through this recursion.
  Filter.Type.CanAttachToSubject -> leaf predicate
  -- A leaf for the atom above's reason: CR 205.2a's read of the subject's host is
  -- a different atom with a lint of its own (hostOfSubjectCardTypeCounts), even
  -- though it is admitted in exactly the positions this one counts.
  Filter.Type.HostOfSubjectHasCardType _ -> leaf predicate
  Filter.Type.IsCommander -> leaf predicate
  Filter.Type.IsToken -> leaf predicate
  Filter.Type.IsActivatedAbility -> leaf predicate
  Filter.Type.IsAbility -> leaf predicate
  Filter.Type.IsEmblem -> leaf predicate
  -- A DESCENT for RepresentedByCard's reason below, the nest describing the
  -- ability's SOURCE.
  Filter.Type.FromSource f -> filterAtomsOf leaf f
  Filter.Type.IsTapped -> leaf predicate
  Filter.Type.IsFaceDown -> leaf predicate
  -- A DESCENT for AttachedTo's reason, the nest describing the CARD representing
  -- the candidate: CR 708.12's atom is a Filter position a card author writes
  -- into like any other.
  Filter.Type.RepresentedByCard f -> filterAtomsOf leaf f
  Filter.Type.IsExiledFaceDown -> leaf predicate
  Filter.Type.Transformed -> leaf predicate
  Filter.Type.HasActivatedAbility _ -> leaf predicate
  Filter.Type.IsInZone _ -> leaf predicate
  Filter.Type.WasCastFrom _ -> leaf predicate
  Filter.Type.TagWasSpent _ -> leaf predicate
  Filter.Type.Paid _ -> leaf predicate
  Filter.Type.IsPrototyped -> leaf predicate
  Filter.Type.IsRingBearer -> leaf predicate
  Filter.Type.IsPaired -> leaf predicate
  Filter.Type.IsPairedWithSource -> leaf predicate
  Filter.Type.BlockPartnerOfSource _ -> leaf predicate
  Filter.Type.HasDesignation _ -> leaf predicate

-- Does this position's evaluator frame its context by the SOURCE, through
-- Parun.Engine.SourceContext? Those are the positions that answer every
-- source-derived atom: CR 303.4b's host and CR 607.2d's choices alike.
sourceFramed :: Framing -> Bool
sourceFramed framing = case framing of
  SourceHostFramed -> True
  StandingHostFramed -> True
  PlayerEffectFramed -> True
  ReplacementRowFramed -> True
  InTargetSlot -> True
  MintedTargetSlot -> True
  SearchFramed -> True
  MillTallyFramed -> True
  HandSweepFramed -> True
  ClauseGateFramed -> True
  LifeLossAmountFramed -> True
  AffectedSetFramed -> True
  ActivationCostFramed -> True
  TriggerConditionFramed -> True
  ChosenSourceFramed -> True
  AttachDestination -> True
  EntryAttachDestination -> True
  -- The stored CR 611.2c row's: a resolved spell has no permanent behind it to
  -- be attached to anything.
  StoredPlayerEffectFramed -> False
  -- Parun.Engine.Mana.admitsUnder frames its context by no source: the mana's
  -- source may be gone by the time it is spent (CR 106.6).
  ManaRestrictionFramed -> False
  -- Conservative, KeywordFramed's posture: refusing the atom only narrows what
  -- a card may write. A keyword's own Filter is matched against an aiming
  -- object at CR 702.16b and CR 702.11d (Parun.Engine.Target.targetable), whose
  -- host is not the carrier's.
  KeywordFramed -> False
  -- The candidate is a printed face with no identity, so the atom is False
  -- whatever the context holds.
  OutsideTheGameFramed -> False
  -- Conservative for KeywordFramed's reason: everything else, some of it read
  -- with no source at all.
  Unframed -> False
  -- Matched through a bare Filter.contextFor, Unframed's posture.
  StoredClassFramed -> False
  -- Parun.Engine.Resolve.Effect.offerCastOnce pays CastOffer.payingInstead,
  -- which carries this tag, framed by the OFFERED card rather than by the
  -- offering object, so a source-derived atom there is a silent False.
  SlotlessCostFramed -> False

-- How many CR 701.3a atoms this card carries in a position framed by an attach
-- -- Effect.AttachTarget's destination, Effect.AttachTargetToEach's,
-- Effect.AttachAll's, or CR 614.1c's EntryRewrite.EntersAttachedTo host choice
-- -- and how many anywhere else. The second number is the offence; the first is
-- what Aura Graft, Synthetic Aura Diffusion, Grifter's Blade and Glamer
-- Spinners legitimately have one of each.
canHostSubjectCounts :: Face.Face Card.Type.Card -> (Int, Int)
canHostSubjectCounts card =
  let total wanted = sum (fmap (\(_, f) -> canHostSubjects f) (filter (\(framing, _) -> elem framing [AttachDestination, EntryAttachDestination] == wanted) (cardFilters card)))
   in (total True, total False)

-- Every occurrence of one atom's codec tag in an ENCODED face. The completeness
-- witness for the traversal above: Parun.Codec.Face.toJson visits every field
-- of a Face and every type under it, is round-tripped by
-- Parun.CodecIntegrationSpec's "honesty round-trip over allPrintings", and was
-- written for another purpose entirely -- so a Filter position cardFilters forgets
-- is one this still sees.
--
-- A tag and not a name: Parun.Codec.Filter spells a nullary atom
-- `Common.nullary "CanHostSubject"`, so the only string equal to one of these in
-- a card's encoding is that tag (a card NAMED "CanHostSubject" would be a false
-- positive, and a loud one rather than a silent miss).
--
-- Parameterized because several atoms want it: CR 701.3a's and CR 709.4a's,
-- counted here for their traversal cross-checks, and CR 702.134a's OfSource
-- operand, which a card may carry only in a wish, a trigger condition or a
-- pairwise combat restriction.
jsonAtoms :: Text.Text -> Value.Value -> Int
jsonAtoms = occurrences . Value.String . String.MkString

-- How many subtrees of a card's encoding equal `needle`: a bare tag string
-- (jsonAtoms), or a whole encoded atom where its payload is what tells two apart
-- -- Filter.Shares' trait and anchor.
occurrences :: Value.Value -> Value.Value -> Int
occurrences needle value
  | value == needle = 1
  | otherwise = case value of
      Value.Array a -> sum (fmap (occurrences needle) (Array.unwrap a))
      Value.Object o -> sum (fmap (occurrences needle . Pair.value) (Object.unwrap o))
      Value.String _ -> 0
      Value.Null _ -> 0
      Value.Boolean _ -> 0
      Value.Number _ -> 0

-- An atom's own encoding, as a needle for `occurrences`.
atomJson :: Filter.Type.Filter Keyword.Keyword -> Value.Value
atomJson = Codec.encode (Filter.Codec.codec Keyword.Codec.codec)

-- How many copies of `needle` sit in a TRIGGERED ability's own condition -- an
-- object carrying both a "condition" and a "modal", printed or granted --
-- counted off the encoding so a grant nested inside an effect is reached too.
triggerConditionAtoms :: Value.Value -> Value.Value -> Int
triggerConditionAtoms needle value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        named k = [Pair.value p | p <- pairs, String.unwrap (Pair.name p) == Text.pack k]
        triggered = not (null (named "modal"))
        own = if triggered then sum (fmap (occurrences needle) (named "condition")) else 0
        rest = sum [triggerConditionAtoms needle (Pair.value p) | p <- pairs, not (triggered && String.unwrap (Pair.name p) == Text.pack "condition")]
     in own + rest
  Value.Array a -> sum (fmap (triggerConditionAtoms needle) (Array.unwrap a))
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- How many copies of `needle` sit in a resolved "can't be blocked" row's
-- BLOCKER filter -- the "blockers" of a "ForbidBeingBlocked" payload -- which
-- Parun.Engine.CombatRestriction.storedEvasions matches in the attacker's
-- pairwise context (Space Beleren).
evasionBlockerAtoms :: Value.Value -> Value.Value -> Int
evasionBlockerAtoms needle value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        named k = [Pair.value p | p <- pairs, String.unwrap (Pair.name p) == Text.pack k]
        isEvasion = any (\v -> case v of Value.String t -> String.unwrap t == Text.pack "ForbidBeingBlocked"; _ -> False) (named "type")
        blockersOf v = case v of
          Value.Object inner -> sum [occurrences needle (Pair.value p) | p <- Object.unwrap inner, String.unwrap (Pair.name p) == Text.pack "blockers"]
          _ -> 0
     in if isEvasion
          then sum (fmap blockersOf (named "value"))
          else sum (fmap (evasionBlockerAtoms needle . Pair.value) pairs)
  Value.Array a -> sum (fmap (evasionBlockerAtoms needle) (Array.unwrap a))
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- How many copies of `needle` sit in a wish's filter -- the payload of a
-- "FromOutsideTheGame" arm, an effect's or a draw rewrite's -- the position
-- Parun.Engine.Event.eligible matches (Synthetic Wishful Djinn).
wishFilterAtoms :: Value.Value -> Value.Value -> Int
wishFilterAtoms needle value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        named k = [Pair.value p | p <- pairs, String.unwrap (Pair.name p) == Text.pack k]
        isWish = any (\v -> case v of Value.String t -> String.unwrap t == Text.pack "FromOutsideTheGame"; _ -> False) (named "type")
     in if isWish
          then sum (fmap (occurrences needle) (named "value"))
          else sum (fmap (wishFilterAtoms needle . Pair.value) pairs)
  Value.Array a -> sum (fmap (wishFilterAtoms needle) (Array.unwrap a))
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- The CR 601.2c announced-target tag, spelled once.
isTargetTag :: Text.Text
isTargetTag = Text.pack "IsTarget"

-- How many Filter.IsTarget atoms sit OUTSIDE a cost an announcement pays, the
-- only positions Binding.announcedTargets is stamped for: a spell's additional
-- costs, an activated ability's cost (an object with a "cost" beside a "modal"),
-- and the components a cost modifier's CostChange.Add adds. Anywhere else --
-- a triggered ability above all, which is never stamped -- the atom is a silent
-- False, isBoundOffends' offence one atom over. Counted off the encoding, so a
-- grant nested inside an effect is reached too.
isTargetStrays :: Value.Value -> Int
isTargetStrays value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        nameOf p = String.unwrap (Pair.name p)
        has k = any ((== Text.pack k) . nameOf) pairs
        activated = has "cost" && has "modal" && not (has "condition")
        adding = any (\p -> nameOf p == Text.pack "type" && Pair.value p == Value.String (String.MkString (Text.pack "Add"))) pairs
        paid p =
          elem (nameOf p) (fmap Text.pack ["additionalCosts", "additionalCostChoices"])
            || (activated && nameOf p == Text.pack "cost")
            || (adding && nameOf p == Text.pack "value")
        here = fromEnum (any (\p -> nameOf p == Text.pack "type" && Pair.value p == Value.String (String.MkString isTargetTag)) pairs)
     in here + sum [isTargetStrays (Pair.value p) | p <- pairs, not (paid p)]
  Value.Array a -> sum (fmap isTargetStrays (Array.unwrap a))
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- Does this face ask IsTarget where no announcement stamps the targets?
isTargetOffends :: Face.Face Card.Type.Card -> Bool
isTargetOffends = (/= 0) . isTargetStrays . Codec.encode (Face.Codec.codec Card.codec)

-- The CR 202.3 computed-bound operand's tag, spelled once.
enclosingAmountTag :: Text.Text
enclosingAmountTag = Text.pack "EnclosingAmount"

-- How many comparisons reading the candidate's MANA VALUE one encoded Filter
-- holds whose operand's tag `wanted` accepts, at any depth: a mana value measure,
-- or an Own ManaValue operand reading it from the other side.
manaValueComparisons :: (Text.Text -> Bool) -> Value.Value -> Int
manaValueComparisons wanted value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        named k = [Pair.value p | p <- pairs, String.unwrap (Pair.name p) == Text.pack k]
        tagOf v = case v of
          Value.Object x -> [t | p <- Object.unwrap x, String.unwrap (Pair.name p) == Text.pack "type", Value.String t <- [Pair.value p]]
          _ -> []
        isManaValue v = fmap String.unwrap (tagOf v) == [Text.pack "ManaValue"]
        operandTags = concatMap (fmap String.unwrap . tagOf) (named "operand")
        ownManaValue = case named "operand" of
          [Value.Object x] -> Text.pack "Own" `elem` operandTags && any isManaValue [Pair.value p | p <- Object.unwrap x, String.unwrap (Pair.name p) == Text.pack "value"]
          _ -> False
        measured = any isManaValue (named "measure") || ownManaValue
        here = if measured && any wanted operandTags then 1 else 0 :: Int
     in here + sum (fmap (manaValueComparisons wanted . Pair.value) pairs)
  Value.Array a -> sum (fmap (manaValueComparisons wanted) (Array.unwrap a))
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- CR 702.122d's atom, which no card may write.
cantCrewVehiclesTag :: Text.Text
cantCrewVehiclesTag = Text.pack "CantCrewVehicles"

-- How many CR 202.3 computed-bound atoms sit inside a target slot that NAMES an
-- amount, counted off the encoding rather than off cardFilters: the position this
-- atom needs is a property of the enclosing SLOT rather than of the Framing, and
-- a Framing tag cannot say which slot a filter came out of.
--
-- "pool" is the key that identifies a target slot -- Parun.Codec.TargetSlot is the
-- only codec in the tree that writes one -- and "amount" beside it is the slot
-- naming its bound. The other positions that fill the bound are a conjure's
-- reference pick (Parun.Types.FromReference), the "Reference" arm of
-- Parun.Codec.ConjureCards, whose value carries the same two keys, and a combat
-- restriction's affected set beside its "amount" (Parun.Types.AffectedUnless,
-- Ensnaring Bridge). Only that position's own "filter" or "affected" subtree is
-- counted, which is sound because neither holds a target slot, a reference pick
-- or a restriction: nothing nests below it to be double-counted.
amountedSlotAtoms :: Value.Value -> Int
amountedSlotAtoms value = case value of
  Value.Array a -> sum (fmap amountedSlotAtoms (Array.unwrap a))
  Value.Object o ->
    let pairs = Object.unwrap o
        keyed k = fmap Pair.value (filter (\pair -> String.unwrap (Pair.name pair) == Text.pack k) pairs)
        tagged names = any (\v -> case v of Value.String t -> String.unwrap t `elem` fmap Text.pack names; _ -> False) (keyed "type")
        referenceAtoms = sum (fmap (amountedAtoms "filter") (if tagged ["Reference"] then keyed "value" else []))
        restrictionAtoms = sum (fmap (amountedAtoms "affected") (if tagged ["CantAttack", "CantBlock"] then keyed "value" else []))
        here =
          if null (keyed "pool") || null (keyed "amount")
            then referenceAtoms + restrictionAtoms
            else sum (fmap (jsonAtoms enclosingAmountTag) (keyed "filter"))
     in here + sum (fmap (amountedSlotAtoms . Pair.value) pairs)
  Value.String _ -> 0
  Value.Null _ -> 0
  Value.Boolean _ -> 0
  Value.Number _ -> 0

-- A conjure reference pick's value, or a combat restriction's
-- (Parun.Types.AffectedUnless): the atoms of its subtree at `key` where an
-- "amount" sits beside it, and none where it does not.
amountedAtoms :: String -> Value.Value -> Int
amountedAtoms key value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        keyed k = fmap Pair.value (filter (\pair -> String.unwrap (Pair.name pair) == Text.pack k) pairs)
     in if null (keyed "amount") then 0 else sum (fmap (jsonAtoms enclosingAmountTag) (keyed key))
  _ -> 0

-- How many CR 202.3 computed-bound operands this card carries in a target slot,
-- reference pick or combat restriction that names an amount, and how many
-- anywhere else. The second
-- number is the offence; the first is what Celestine, the Living Saint
-- legitimately has one of.
--
-- Parun.Engine.Target.slotContext fills Filter.Context.slotAmount off the SLOT's
-- own Quantity (Parun.Engine.CombatRestriction.amountFrame off a restriction's),
-- so the operand in a slot that names none -- or in a Count filter, a static
-- ability's affected set, a search filter, a cost criterion -- is a silent False
-- rather than a rejected card. This is where that is made loud.
enclosingAmountCounts :: Face.Face Card.Type.Card -> (Int, Int)
enclosingAmountCounts card =
  let encoded = Codec.encode (Face.Codec.codec Card.codec) card
      slotted = amountedSlotAtoms encoded
   in (slotted, jsonAtoms enclosingAmountTag encoded - slotted)

enclosingAmountOffends :: Face.Face Card.Type.Card -> Bool
enclosingAmountOffends card = snd (enclosingAmountCounts card) /= 0

-- The CR 608.2d other-candidates operand's tag, spelled once.
otherCandidateTag :: Text.Text
otherCandidateTag = Text.pack "OfEachOtherCandidate"

-- How many of those operands sit in an edict's or a chosen permanent's own
-- filter, and how many anywhere else. Filter.amongCandidates is the one filler
-- of Filter.Context.candidateMeasures, called for an edict's pool and the
-- battlefield's -- Parun.Engine.Resolve.Slots.chosenCandidates' other zones
-- never call it -- so the operand anywhere else, a choice out of exile
-- included, is a silent False. Counted off the encoding for
-- amountedSlotAtoms' reason: the position is the enclosing PlayerSacrifices,
-- ChoosePermanents or ChosenPermanents, which no Framing names.
otherCandidateCounts :: Face.Face Card.Type.Card -> (Int, Int)
otherCandidateCounts card =
  let encoded = Codec.encode (Face.Codec.codec Card.codec) card
      edicts value = case value of
        Value.Array a -> sum (fmap edicts (Array.unwrap a))
        Value.Object o ->
          let pairs = Object.unwrap o
              keyed k = fmap Pair.value (filter (\pair -> String.unwrap (Pair.name pair) == Text.pack k) pairs)
              typed tag = any (\v -> case v of Value.String t -> String.unwrap t == Text.pack tag; _ -> False) (keyed "type")
              field name v = case v of
                Value.Object x -> [Pair.value pair | pair <- Object.unwrap x, String.unwrap (Pair.name pair) == Text.pack name]
                _ -> []
              -- A choice's zone is defaulted, so only the battlefield's omits it.
              onBattlefield = filter (null . field "zone")
              positioned
                | typed "PlayerSacrifices" = Just (concatMap (field "filter") (keyed "value"))
                | typed "ChosenPermanents" = Just (concatMap (field "filter") (onBattlefield (keyed "value")))
                | typed "ChoosePermanents" = Just (concatMap (field "filter") (onBattlefield (concatMap (field "permanents") (keyed "value"))))
                | otherwise = Nothing
           in case positioned of
                Just filters -> sum (fmap (jsonAtoms otherCandidateTag) filters)
                Nothing -> sum (fmap (edicts . Pair.value) pairs)
        Value.String _ -> 0
        Value.Null _ -> 0
        Value.Boolean _ -> 0
        Value.Number _ -> 0
      held = edicts encoded
   in (held, jsonAtoms otherCandidateTag encoded - held)

-- CR 701.3a is answerable only where an attach FRAMES the match, and
-- Filter.CanHostSubject is vacuously False in every other Filter position. A card
-- author who wrote it into a target slot, a static ability's affected set, a Count
-- filter or a Search filter would otherwise get a False predicate and no failure
-- at all -- neither the codec, the type nor any other lint says a word -- so this
-- is where that is made loud.
--
-- TWO offences under one name, because they are two ways for the same claim to be
-- untrue:
--
--   * the traversal found the atom somewhere no attach frames it -- the misuse
--     itself; and
--   * the traversal and the codec disagree about how many the card holds -- which
--     means cardFilters has a blind spot, and an atom sitting in it would be
--     reported as zero rather than as an offence.
--
-- The second is not hypothetical maintenance theatre: cardFilters' Face-record
-- fold is hand-maintained, and a new field holding a Filter is exactly the kind of
-- change that would otherwise make this lint quietly stop doing its job.
canHostSubjectOffends :: Face.Face Card.Type.Card -> Bool
canHostSubjectOffends card =
  let (framed, unframedCount) = canHostSubjectCounts card
   in unframedCount /= 0 || framed + unframedCount /= jsonAtoms (Text.pack "CanHostSubject") (Codec.encode (Face.Codec.codec Card.codec) card)

-- jsonAtoms narrowed from a whole face to ONE Filter position of it. The atom
-- this is asked about carries a payload (a SlotName), so counting the tag by hand
-- would mean a second copy of canHostSubjects' whole recursion; Parun.Codec.Filter
-- already walks every arm of it, including the ones a hand-written recursion has
-- dropped before (landwalk's Subtype, now a Filter).
--
-- Sound as a per-position count because a TargetSlot's codec embeds its Filter's
-- encoding verbatim, so the sum over cardFilters' positions and jsonAtoms over
-- the whole encoded face are counting the same occurrences.
filterAtoms :: Text.Text -> Filter.Type.Filter Keyword.Keyword -> Int
filterAtoms tag = jsonAtoms tag . atomJson

-- The CR 701.3a candidate-side tag, spelled once.
canAttachToSubjectTag :: Text.Text
canAttachToSubjectTag = Text.pack "CanAttachToSubject"

-- How many CR 701.3a candidate-side atoms this card carries inside a SEARCH's
-- filter, and how many anywhere else. The second number is the offence; the first
-- is what Auratouched Mage and Sovereigns of Lost Alara legitimately have one of
-- each.
canAttachToSubjectCounts :: Face.Face Card.Type.Card -> (Int, Int)
canAttachToSubjectCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms canAttachToSubjectTag f) (filter (\(framing, _) -> (framing == SearchFramed) == wanted) (cardFilters card)))
   in (total True, total False)

-- Filter.CanAttachToSubject is answerable only where the evaluator supplies the
-- fixed host, and Parun.Engine.Resolve's Effect.Search arm is the only one that
-- does. Written into a target slot, an affected set, a Count filter or an attach
-- destination it is a silent False rather than a rejected card, exactly as
-- Filter.CanHostSubject is outside an attach. This is where that is made loud.
--
-- Two offences under one name, for canHostSubjectOffends' two reasons: the
-- traversal found the atom outside a search, or the traversal and the codec
-- disagree about how many the card holds -- the second being a blind spot in
-- cardFilters, in which an atom would be reported as zero rather than as an
-- offence.
canAttachToSubjectOffends :: Face.Face Card.Type.Card -> Bool
canAttachToSubjectOffends card =
  let (framed, unframedCount) = canAttachToSubjectCounts card
   in unframedCount /= 0 || framed + unframedCount /= jsonAtoms canAttachToSubjectTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 205.2a subject's-host tag, spelled once.
hostOfSubjectCardTypeTag :: Text.Text
hostOfSubjectCardTypeTag = Text.pack "HostOfSubjectHasCardType"

-- How many CR 205.2a subject's-host atoms this card carries in a position an
-- attach frames, and how many anywhere else. The second number is the offence;
-- the first is what Enchantment Alteration legitimately has two of, one per card
-- type its "of that type" ranges over.
--
-- The SAME position set canHostSubjectCounts admits, because
-- Parun.Engine.Attach.hostsFor is the one filler of
-- Filter.Context.subjectHostCardTypes as it is of the view's `canHostSubject`.
-- Admitted at CR 614.1c's entry choice and refused at CR 303.4k's turn-up rider
-- for that reason alone, and not because either can ANSWER it: a permanent
-- entering the battlefield and an Aura being turned face up are each attached
-- to nothing yet, so the set is empty and the atom is False at both. Only a
-- resolving attach has a subject with a host.
hostOfSubjectCardTypeCounts :: Face.Face Card.Type.Card -> (Int, Int)
hostOfSubjectCardTypeCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms hostOfSubjectCardTypeTag f) (filter (\(framing, _) -> elem framing [AttachDestination, EntryAttachDestination] == wanted) (cardFilters card)))
   in (total True, total False)

-- Filter.HostOfSubjectHasCardType is answerable only where an attach frames the
-- match, and is a silent False everywhere else -- canAttachToSubjectOffends'
-- claim with the two roles swapped back.
--
-- Two offences under one name, for canHostSubjectOffends' two reasons: the
-- traversal found the atom outside an attach's destination, or the traversal and
-- the codec disagree about how many the card holds.
hostOfSubjectCardTypeOffends :: Face.Face Card.Type.Card -> Bool
hostOfSubjectCardTypeOffends card =
  let (framed, unframedCount) = hostOfSubjectCardTypeCounts card
   in unframedCount /= 0 || framed + unframedCount /= jsonAtoms hostOfSubjectCardTypeTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 201.4 chosen-name tag, spelled once.
hasChosenNameTag :: Text.Text
hasChosenNameTag = Text.pack "HasChosenName"

-- How many CR 201.4 chosen-name atoms this card carries inside one of the
-- ADMITTED positions -- a CR 701.23 search's filter, a CR 701.17 mill's tally,
-- an EFFECT's ObjectRef, a mode's target slot, a player effect's own Filter,
-- printed or stored, a static ability's affected set (Projection.affectedContext),
-- a mode clause's own "if", which Parun.Engine.Resolve.gateHolds reads through
-- Resolve.Slots.effectContext, or a trigger condition's own Filter, which
-- Parun.Engine.Event.Match reads through Projection.sourceContext -- and how many
-- anywhere else. The second number is the offence; the first is what Ancient
-- Vendetta, Predict, Petra Sphinx, Conundrum Sphinx, Vexing Arcanix, Null
-- Chamber, Conjurer's Ban, Runed Halo, Declaration of Naught, Immediate Action
-- and Booby Trap legitimately have.
--
-- SourceHostFramed and not `hostFramed`: since #3320 that tag means an effect's
-- ObjectRef and nothing else, which is what makes it admissible here. The
-- positions it used to share the tag with carry StandingHostFramed and are
-- REJECTED, though Parun.Engine.SourceContext fills their contexts: no card asks
-- a chosen name in a CR 604.2 or CR 603.4 clause yet. The self-test below plants
-- the atom in a static condition and expects the offence.
--
-- An ALLOWLIST rather than "wherever Filter.Context.sourceChosenNames is filled",
-- boundNameCounts' posture and for its reason: since #2992 the field is
-- filled by Parun.Engine.Resolve.Slots.effectContext itself, so every position a
-- RESOLUTION reaches has it, and this rejects the atom in positions that would in
-- fact answer. Widen it when a card wants one of them.
hasChosenNameCounts :: Face.Face Card.Type.Card -> (Int, Int)
hasChosenNameCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms hasChosenNameTag f) (filter (\(framing, _) -> elem framing [SearchFramed, MillTallyFramed, SourceHostFramed, InTargetSlot, PlayerEffectFramed, StoredPlayerEffectFramed, AffectedSetFramed, ClauseGateFramed, TriggerConditionFramed] == wanted) (cardFilters card)))
   in (total True, total False)

-- CR 201.4's chosen name is answerable only where Filter.Context.sourceChosenNames
-- is filled: every source-framed position (`sourceFramed`). Read
-- through a bare Filter.contextFor it is a silent False rather than a rejected
-- card, and this is where that is made loud.
--
-- The positions hasChosenNameCounts admits are narrower than that, on
-- purpose: see its own note. So a card rejected here is not necessarily one the
-- engine would answer wrong.
--
-- SearchFramed is the framing canAttachToSubjectOffends fences, and for a
-- different rule: that atom needs the search arm's own VIEW as well as its
-- context, so it is admitted in that one position where this atom is admitted in
-- three.
--
-- Two offences under one name, for canHostSubjectOffends' two reasons: the
-- traversal found the atom outside those positions, or the traversal and the codec
-- disagree about how many the card holds -- the second being a blind spot in
-- cardFilters, in which an atom would be reported as zero rather than as an
-- offence. Unlike its three siblings' the second disjunct is PROVED here rather
-- than a regression fence: Effect.ChooseCardName's own restriction is a Filter
-- position cardFilters walks, so the self-test's fixture for it goes to (0, 0)
-- when effectFilters stops reporting it and the codec half is what still catches
-- the atom.
hasChosenNameOffends :: Face.Face Card.Type.Card -> Bool
hasChosenNameOffends card =
  let (framed, elsewhere) = hasChosenNameCounts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms hasChosenNameTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 607.2d chosen-colour and chosen-subtype tags, spelled once.
hasChosenColorTag :: Text.Text
hasChosenColorTag = Text.pack "HasChosenColor"

hasChosenSubtypeTag :: Text.Text
hasChosenSubtypeTag = Text.pack "HasChosenSubtype"

-- How many atoms carrying `tag` this card holds in one of the `admitted`
-- positions, and how many anywhere else. The second number is the offence.
--
-- A SPELL's own positions are moved to the second number although they are
-- admitted: the context reads the answer off the source, and a spell is never
-- the object CR 614.1c's "as this enters" choice was made for, nor attached to
-- anything, so the atom there would be a silent False. The exception is a
-- spell whose own resolution makes a choice `answers` admits (Effect.ChooseQuality,
-- Persecute): the filters its mode reads AFTER the choice (CR 608.2c's "in the
-- order written") read it, though its target slots, chosen before it resolves
-- (CR 601.2c), still cannot, nor can a filter ahead of it or in another mode.
chosenValueCounts :: (Framing -> Bool) -> (ChosenQuality.ChosenQuality -> Bool) -> Text.Text -> Face.Face Card.Type.Card -> (Int, Int)
chosenValueCounts admitted answers tag card =
  let total keep pairs = sum (fmap (\(_, f) -> filterAtoms tag f) (filter (keep . fst) pairs))
      spellPairs = modalFilters (Face.spell card)
      answered = afterChoice answers (Face.spell card)
      inSpell = total admitted spellPairs - total admitted answered
   in (total admitted (cardFilters card) - inSpell, total (not . admitted) (cardFilters card) + inSpell)

-- The filters a spell's mode reads after its first `Effect.ChooseQuality q`
-- whose `q` answers the atom:
-- modalFilters over what follows it -- the rest of the choosing clause, shorn
-- of the gate asked before it, and every later clause -- with no target slot.
afterChoice :: (ChosenQuality.ChosenQuality -> Bool) -> Modal.Modal Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> [(Framing, Filter.Type.Filter Keyword.Keyword)]
afterChoice answers modal =
  let chosen effect = case effect of
        Effect.ChooseQuality q -> answers q
        _ -> False
      rest mode = case Seq.breakl (any chosen . Clause.effects) (Mode.clauses mode) of
        (_, after) -> case Seq.viewl after of
          Seq.EmptyL -> Nothing
          chooser Seq.:< later ->
            Just
              ( Mode.MkMode
                  (chooser {Clause.condition = Nothing, Clause.payGate = Nothing, Clause.effects = Seq.drop 1 (Seq.dropWhileL (not . chosen) (Clause.effects chooser))} Seq.<| later)
                  Map.empty
              )
   in modalFilters modal {Modal.modes = Seq.fromList (Maybe.mapMaybe rest (Foldable.toList (Modal.modes modal)))}

-- Whether a choice of this quality answers HasChosenColor rather than
-- HasChosenSubtype: the field Parun.Engine.Event.chooseQuality writes.
writesColors :: ChosenQuality.ChosenQuality -> Bool
writesColors quality = case quality of
  ChosenQuality.Colors _ -> True
  ChosenQuality.BasicLandType -> False
  ChosenQuality.CreatureType -> False

-- CR 105.2's chosen colour is answerable only where Filter.Context.sourceChosenColors
-- is filled: every source-framed position (sourceFramed), plus a static grant's
-- bare protection quality (grantedChosenColors) and CR 106.6's mana
-- restriction, which Parun.Engine.Mana.admitsUnder fills off the mana unit
-- (Throne of Eldraine). Everywhere else it is a silent False.
hasChosenColorCounts :: Face.Face Card.Type.Card -> (Int, Int)
hasChosenColorCounts card =
  let (framed, elsewhere) = chosenValueCounts (\framing -> framing == ManaRestrictionFramed || sourceFramed framing) writesColors hasChosenColorTag card
      granted = grantedChosenColors card
   in (framed + granted, elsewhere - granted)

-- CR 607.2d's "protection from the chosen color" granted by a STATIC ability
-- or by a resolution's ModifyTarget: the keyword positions the colour is
-- answered at, since Parun.Engine.Keyword.withChosenColors bakes the choice
-- into a BARE quality -- as Parun.Engine.Projection applies a static grant
-- (Cho-Manno's Blessing), and as freezeQuantities stores a resolution's (CR
-- 608.2h, Stave Off). The atom buried in a quality stays an offence.
grantedChosenColors :: Face.Face Card.Type.Card -> Int
grantedChosenColors card =
  let bare m = case m of
        Modification.GainKeyword (Keyword.Protection protection) -> Protection.quality protection == Filter.Type.HasChosenColor
        _ -> False
   in length
        ( [() | ability <- Face.staticAbilities card, m <- NonEmpty.toList (StaticAbility.modifications ability), bare m]
            <> [() | Effect.ModifyTarget modify <- cardResolutionEffects card, bare (ModifyTarget.modification modify)]
        )

-- CR 205.3's chosen subtype in the same positions, plus CR 106.6's restriction,
-- which Parun.Engine.Mana.admitsUnder answers off the mana unit (Pillar of
-- Origins). The colour has no such reading, so the two lists differ.
hasChosenSubtypeCounts :: Face.Face Card.Type.Card -> (Int, Int)
hasChosenSubtypeCounts = chosenValueCounts (\framing -> framing == ManaRestrictionFramed || sourceFramed framing) (not . writesColors) hasChosenSubtypeTag

-- CR 607.2a's last-exiled atom, spelled once: IsLastExiledWithSource's tag.
isLastExiledWithSourceTag :: Text.Text
isLastExiledWithSourceTag = Text.pack "IsLastExiledWithSource"

-- The atom is answerable only in CR 106.6's restriction, where
-- Parun.Engine.Mana.admitsUnder fills Filter.Context.sourceLastExiled off the
-- mana unit (Ice Cauldron); everywhere else it is a silent False.
isLastExiledWithSourceCounts :: Face.Face Card.Type.Card -> (Int, Int)
isLastExiledWithSourceCounts = chosenValueCounts (== ManaRestrictionFramed) (const False) isLastExiledWithSourceTag

-- Two offences under one name, hasChosenNameOffends' two: an atom outside the
-- admitted positions, or the traversal and the codec disagreeing about how many
-- the card holds.
chosenValueOffends :: (Face.Face Card.Type.Card -> (Int, Int)) -> Text.Text -> Face.Face Card.Type.Card -> Bool
chosenValueOffends counts tag card =
  let (framed, elsewhere) = counts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms tag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 702.16k chosen-player tag, spelled once.
ofChosenPlayerTag :: Text.Text
ofChosenPlayerTag = Text.pack "OfChosenPlayer"

-- How many CR 702.16k chosen-player atoms this card carries inside a KEYWORD's
-- own filter, and how many anywhere else. The second number is the offence; the
-- first is what True-Name Nemesis legitimately has one of.
ofChosenPlayerCounts :: Face.Face Card.Type.Card -> (Int, Int)
ofChosenPlayerCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms ofChosenPlayerTag f) (filter (\(framing, _) -> (framing == KeywordFramed) == wanted) (cardFilters card)))
   in (total True, total False)

-- CR 702.16k's chosen player is answerable only where
-- Filter.Context.carrierChosenPlayer is filled, and the four fillers are the four
-- positions rule 702.16 reads a protection QUALITY in
-- (Parun.Engine.Replacement.candidateContext, Parun.Engine.Target.targetable,
-- Parun.Engine.AttachRestriction.barredBy,
-- Parun.Engine.CombatRestriction.cantBeBlockedBy). Every one of them takes the
-- filter off a keyword, so a target slot, an affected set, a Count filter or a
-- cost criterion asking this atom is a silent False rather than a rejected card.
-- This is where that is made loud.
--
-- Every one of them takes the filter off a keyword AS A KEYWORD, which is why
-- CR 702.6c's equip quality is not in this bucket: rule 702.6a's minted ability
-- carries that payload into a target slot answered by
-- Parun.Engine.Target.slotContext, which sets carrierChosenPlayer to Nothing. It
-- arrives as MintedTargetSlot rather than KeywordFramed and so offends here,
-- which is the point of that framing; the "CR 702.16k an equip quality is not a
-- protection quality" case below is what proves it.
--
-- The frame is KEYWORD rather than PROTECTION, which is wider than rule 702.16k
-- alone, and the width cuts two ways. CR 702.11d's hexproof quality is the
-- harmless half: Parun.Engine.Target.targetable evaluates it against the very
-- Context that fills the field, so a hexproof-from-the-chosen-player card would
-- be answerable in that one position too.
--
-- CR 702.14a's landwalk is the other half, and this frame admits it while nothing
-- answers it: Parun.Engine.Combat.landwalkAllowsGiven matches the criterion
-- through a plain Filter.contextFor, which leaves carrierChosenPlayer Nothing, so
-- `Landwalk OfChosenPlayer` would pass this lint and be vacuously False. No
-- printing can reach it -- rule 702.14a's quality is "usually a land type, but it
-- can also be the card type land plus any combination of land types, card types,
-- and/or supertypes", a list with no player on it -- so the hole is unreachable
-- rather than merely unoccupied. Narrowing the fence to Keyword.Protection is not
-- a one-line change: `keywordFramed` tags every keyword's filter alike, and
-- telling them apart wants a Framing this type does not draw.
--
-- Two offences under one name, for hasChosenNameOffends' two reasons: the
-- traversal found the atom outside a keyword, or the traversal and the codec
-- disagree about how many the card holds.
ofChosenPlayerOffends :: Face.Face Card.Type.Card -> Bool
ofChosenPlayerOffends card =
  let (framed, elsewhere) = ofChosenPlayerCounts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms ofChosenPlayerTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- How many atoms tagged `tag` in an encoding decode to one `wanted` admits:
-- an anchored atom's trait and anchor are what tell its readings apart, and a
-- bound anchor's slot name varies, so no single needle finds them.
decodedAtoms :: String -> (Filter.Type.Filter Keyword.Keyword -> Bool) -> Value.Value -> Int
decodedAtoms tag wanted value =
  here + case value of
    Value.Array a -> sum (fmap (decodedAtoms tag wanted) (Array.unwrap a))
    Value.Object o -> sum (fmap (decodedAtoms tag wanted . Pair.value) (Object.unwrap o))
    Value.String _ -> 0
    Value.Null _ -> 0
    Value.Boolean _ -> 0
    Value.Number _ -> 0
  where
    tagged o = elem (Pair.MkPair (String.MkString (Text.pack "type")) (Value.String (String.MkString (Text.pack tag)))) (Object.unwrap o)
    here :: Int
    here = case value of
      Value.Object o | tagged o -> either (const 0) (\atom -> if wanted atom then 1 else 0) (Codec.decode (Filter.Codec.codec Keyword.Codec.codec) value)
      _ -> 0

-- The CR 709.4a bound-name atoms in an encoding: Filter.Shares Name at a Bound
-- anchor.
boundNameAtoms :: Value.Value -> Int
boundNameAtoms = decodedAtoms "Shares" (\atom -> case atom of Filter.Type.Shares Trait.Name (Anchor.Bound _) -> True; _ -> False)

-- How many CR 709.4a atoms this card carries in one of the ADMITTED positions
-- -- a MODE's target slot filter (Harness the Storm), a CR 701.23 search filter
-- (Bifurcate), a CR 608.2c hand sweep's (Hour of Glory) or a CR 119.3 life
-- loss amount's Count filter (Grim Reminder) -- and how many anywhere else. The second number is the offence.
--
-- An ALLOWLIST rather than "wherever Filter.Context.slotNames is filled",
-- which is the wider set: every position a resolution
-- reaches through Parun.Engine.Resolve.Slots.effectContext has the names -- an
-- ObjectRef's own affected set among them, which is SourceHostFramed inside an
-- effect (Resolve.battlefieldMatching). So this rejects the atom in positions
-- that would in fact answer, and only in that direction -- widen it when a card
-- wants one of them, which is the posture sweptForSingularSlots takes at
-- SlotlessCostFramed and what the hand sweep's own entry is.
boundNameCounts :: Face.Face Card.Type.Card -> (Int, Int)
boundNameCounts card =
  let total wanted = sum (fmap (\(_, f) -> boundNameAtoms (atomJson f)) (filter (\(framing, _) -> elem framing [InTargetSlot, SearchFramed, HandSweepFramed, LifeLossAmountFramed] == wanted) (cardFilters card)))
   in (total True, total False)

-- CR 709.4a's bound-name comparison is answerable only where
-- Filter.Context.slotNames is filled, which two callers do:
-- Parun.Engine.Target.admittedGiven, matching a MODE's target slot Filter, and
-- Parun.Engine.Resolve.Slots.effectContext, which all but one of a resolution's
-- positions go through -- the search filter and the mill tally among them.
-- Filter.contextFor leaves it empty, so
-- Filter.Shares Name Bound in a Count filter read outside a resolution, an
-- affected set or a cost criterion is a silent False rather than a rejected card. This is where that is made loud.
--
-- The positions boundNameCounts admits are narrower than that, on
-- purpose: see its own note. So a card rejected here is not necessarily one the
-- engine would answer wrong.
--
-- Two offences under one name, for canHostSubjectOffends' two reasons: the
-- traversal found the atom outside those positions, or the traversal and the codec
-- disagree about how many the card holds -- the second being a blind spot in
-- cardFilters, in which an atom would be reported as zero rather than as an
-- offence.
--
-- The second disjunct is a REGRESSION FENCE rather than a proved behaviour, as
-- canHostSubjectOffends' is: every position a fixture can reach today is caught by
-- the first, so neutralizing the cross-check leaves the suite green. What would
-- observe it is a future Face field cardFilters forgets, which is the thing that
-- cannot be written down yet.
boundNameOffends :: Face.Face Card.Type.Card -> Bool
boundNameOffends card =
  let (slotted, elsewhere) = boundNameCounts card
   in elsewhere /= 0 || slotted + elsewhere /= boundNameAtoms (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 205.3m atoms anchored at a SLOT in an encoding: Filter.Shares
-- CreatureType at a Bound anchor. evaluatedOffends polices the Evaluated one.
boundCreatureTypeAtoms :: Value.Value -> Int
boundCreatureTypeAtoms = decodedAtoms "Shares" (\atom -> case atom of Filter.Type.Shares Trait.CreatureType (Anchor.Bound _) -> True; _ -> False)

-- How many CR 205.3m atoms this card carries in a resolution's own positions --
-- an effect's ObjectRef (Heirloom Blade), a clause's "if" (Mudbutton Clanger), a
-- search, a mill tally or a hand sweep, each read through
-- Parun.Engine.Resolve.Slots.effectContext -- or in a target slot (Unbury), read
-- through Parun.Engine.Target.slotContext: the two fillers of
-- Filter.Context.slotCreatureTypes. And how many anywhere else, where the atom
-- is a silent True. The second number is the offence.
boundCreatureTypeCounts :: Face.Face Card.Type.Card -> (Int, Int)
boundCreatureTypeCounts card =
  let total wanted = sum (fmap (\(_, f) -> boundCreatureTypeAtoms (atomJson f)) (filter (\(framing, _) -> elem framing [SourceHostFramed, ClauseGateFramed, SearchFramed, MillTallyFramed, HandSweepFramed, InTargetSlot] == wanted) (cardFilters card)))
   in (total True, total False)

-- The atom outside those positions, or the traversal and the codec disagreeing
-- about how many the card holds -- boundNameOffends' two offences, and its
-- second disjunct is the same regression fence.
boundCreatureTypeOffends :: Face.Face Card.Type.Card -> Bool
boundCreatureTypeOffends card =
  let (framed, elsewhere) = boundCreatureTypeCounts card
   in elsewhere /= 0 || framed + elsewhere /= boundCreatureTypeAtoms (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 608.2c bound-object operand's tag, spelled once.
ofBoundTag :: Text.Text
ofBoundTag = Text.pack "OfBound"

-- How many bound-object operands this card carries in a resolution's own
-- positions and how many anywhere else, boundCreatureTypeCounts' shape one
-- Filter.Context field over: Parun.Engine.Resolve.Slots.effectContext is the one
-- filler of Filter.Context.slotMeasures too, so the operand is a silent False
-- elsewhere. The second number is the offence.
ofBoundCounts :: Face.Face Card.Type.Card -> (Int, Int)
ofBoundCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms ofBoundTag f) (filter (\(framing, _) -> elem framing [SourceHostFramed, ClauseGateFramed, SearchFramed, MillTallyFramed, HandSweepFramed] == wanted) (cardFilters card)))
   in (total True, total False)

-- The atom outside those positions, or the traversal and the codec disagreeing
-- about how many the card holds -- boundCreatureTypeOffends' two offences.
ofBoundOffends :: Face.Face Card.Type.Card -> Bool
ofBoundOffends card =
  let (framed, elsewhere) = ofBoundCounts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms ofBoundTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 110.2 / 303.4b tag, spelled once.
sameControllerAsHostOfBoundTag :: Text.Text
sameControllerAsHostOfBoundTag = Text.pack "SameControllerAsHostOfBound"

-- How many CR 110.2-of-the-host atoms this card carries in a resolution's own
-- positions and how many anywhere else, ofBoundCounts' shape one
-- Filter.Context field over -- Parun.Engine.Resolve.Slots.effectContext is the
-- one filler of Filter.Context.slotHostControllers too. The ATTACH DESTINATION
-- is admitted alongside its siblings and they do not admit it: that position
-- became a resolution's own when Parun.Engine.Attach.hostsFor started taking its
-- Context from the caller, and it is the only one of these six a card writes
-- this atom in (Simic Guildmage). The second number is the offence.
sameControllerAsHostOfBoundCounts :: Face.Face Card.Type.Card -> (Int, Int)
sameControllerAsHostOfBoundCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms sameControllerAsHostOfBoundTag f) (filter (\(framing, _) -> elem framing [AttachDestination, EntryAttachDestination, SourceHostFramed, ClauseGateFramed, SearchFramed, MillTallyFramed, HandSweepFramed] == wanted) (cardFilters card)))
   in (total True, total False)

-- The atom outside those positions, or the traversal and the codec disagreeing
-- about how many the card holds -- boundCreatureTypeOffends' two offences.
sameControllerAsHostOfBoundOffends :: Face.Face Card.Type.Card -> Bool
sameControllerAsHostOfBoundOffends card =
  let (framed, elsewhere) = sameControllerAsHostOfBoundCounts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms sameControllerAsHostOfBoundTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 110.2 tag, spelled once.
controllerRelatesToBoundTag :: Text.Text
controllerRelatesToBoundTag = Text.pack "ControllerRelatesToBound"

-- How many CR 110.2 shared-controller atoms this card carries inside a MODE's
-- target slot filter, an attach effect's destination, a stored combat
-- restriction class or an effect's ObjectRef, and how many anywhere else. The
-- second number is the offence; the first is what Bioshift and Glamer Spinners
-- legitimately have one of.
controllerRelatesToBoundCounts :: Face.Face Card.Type.Card -> (Int, Int)
controllerRelatesToBoundCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms controllerRelatesToBoundTag f) (filter (\(framing, _) -> elem framing [InTargetSlot, AttachDestination, StoredClassFramed, SourceHostFramed] == wanted) (cardFilters card)))
   in (total True, total False)

-- CR 110.2's shared-controller comparison is answerable only where
-- Filter.Context.slotControllers is filled: Parun.Engine.Target.slotContext, the
-- one site that matches a MODE's target slot Filter, and
-- Parun.Engine.Resolve.Slots.effectContext, which an attach effect's destination
-- and an effect's ObjectRef are matched against and which
-- Parun.Engine.Resolve.Common.storedClass bakes a stored class's atom from. EntryAttachDestination's bare Context is not one. This is boundNameOffends' sweep one characteristic over, and
-- the one place the two differ is what makes it load-bearing rather than tidy:
-- that atom is a silent False outside its position and this one is a silent TRUE,
-- so an atom in a Count filter, an affected set or a search filter would ADMIT
-- what the card excludes rather than nothing at all.
--
-- Two offences under one name, boundNameOffends' two: the traversal found
-- the atom outside a target slot, or the traversal and the codec disagree about
-- how many the card holds. The second disjunct is a REGRESSION FENCE for that
-- function's reason.
controllerRelatesToBoundOffends :: Face.Face Card.Type.Card -> Bool
controllerRelatesToBoundOffends card =
  let (slotted, elsewhere) = controllerRelatesToBoundCounts card
   in elsewhere /= 0 || slotted + elsewhere /= jsonAtoms controllerRelatesToBoundTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 303.4b tag, spelled once.
hostOfSourceTag :: Text.Text
hostOfSourceTag = Text.pack "IsHostOfSource"

-- How many CR 303.4b atoms this card carries in a position whose evaluator
-- supplies the source's host, and how many anywhere else. The second number is the
-- offence; the first is what Ray of Frost legitimately has three of. A spell's
-- own positions count as elsewhere, chosenValueCounts' rule: a spell is attached
-- to nothing.
hostOfSourceCounts :: Face.Face Card.Type.Card -> (Int, Int)
hostOfSourceCounts = chosenValueCounts hostFramed (const False) hostOfSourceTag

-- The source-framed positions the host atom is admitted in: narrower than
-- `sourceFramed`, and the four a card in the pool writes it in. Not
-- implemented: CR 603.10a's look-back to the host in a trigger condition
-- ("when enchanted creature leaves the battlefield"), where CR 704.5n leaves an
-- Equipment unattached on the battlefield (gap #5089).
hostFramed :: Framing -> Bool
hostFramed framing = case framing of
  SourceHostFramed -> True
  StandingHostFramed -> True
  PlayerEffectFramed -> True
  ReplacementRowFramed -> True
  _ -> False

-- CR 303.4b's "enchanted" is answerable only where Filter.Context.sourceAttachedTo
-- is filled: the positions `hostFramed` admits, where a source that has left
-- answers the host it had (CR 608.2h). Filter.contextFor leaves it Nothing, so
-- Filter.IsHostOfSource elsewhere is a silent False rather than a rejected card.
-- This is where that is made loud.
--
-- Two offences under one name, for canHostSubjectOffends' two reasons: the
-- traversal found the atom outside those positions, or the traversal and the
-- codec disagree about how many the card holds -- the second being a blind spot in
-- cardFilters, in which an atom would be reported as zero rather than as an
-- offence. The second disjunct is a REGRESSION FENCE for boundNameOffends'
-- reason.
hostOfSourceOffends :: Face.Face Card.Type.Card -> Bool
hostOfSourceOffends card =
  let (framed, elsewhere) = hostOfSourceCounts card
   in elsewhere /= 0 || framed + elsewhere /= jsonAtoms hostOfSourceTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- How many atoms aimed at a quantity's object an encoding carries:
-- Filter.IsEvaluated by tag, and Filter.Shares and Filter.IsAttachedTo at the
-- Evaluated anchor.
evaluatedAtoms :: Value.Value -> Int
evaluatedAtoms value =
  jsonAtoms (Text.pack "IsEvaluated") value
    + decodedAtoms "Shares" (\atom -> case atom of Filter.Type.Shares _ Anchor.Evaluated -> True; _ -> False) value
    + decodedAtoms "IsAttachedTo" (== Filter.Type.IsAttachedTo Anchor.Evaluated) value

-- How many Filter.Shares and Filter.IsAttachedTo atoms in an encoding pair an
-- anchor with a reading Parun.Engine.Filter has none for -- sharesAnchored's
-- and attachedAnchored's Nothing, which Filter.matches answers False (#5636) --
-- and how many it carries in all.
unreadAnchorCounts :: Value.Value -> (Int, Int)
unreadAnchorCounts value =
  let unread atom = case atom of
        Filter.Type.Shares trait anchor -> Maybe.isNothing (Filter.sharesAnchored trait anchor)
        Filter.Type.IsAttachedTo anchor -> Maybe.isNothing (Filter.attachedAnchored anchor)
        _ -> False
      count wanted = decodedAtoms "Shares" wanted value + decodedAtoms "IsAttachedTo" wanted value
   in (count unread, count (const True))

-- How many of those atoms this card carries in a Count's filter, and how many
-- its encoding carries in all.
evaluatedCounts :: Face.Face Card.Type.Card -> (Int, Int)
evaluatedCounts card =
  ( sum (fmap (evaluatedAtoms . atomJson . Count.Type.filter) (cardCounts card)),
    evaluatedAtoms (Codec.encode (Face.Codec.codec Card.codec) card)
  )

-- Filter.Context.evaluated and evaluatedCreatureTypes are filled by
-- Parun.Engine.Quantity's Count arm, the only caller of
-- Parun.Engine.Count.evaluate, and by nothing else, so the atoms anywhere but a
-- Count's filter are a silent False. An atom the codec finds and
-- cardCounts does not is the offence -- misplaced, or in a blind spot of that
-- traversal.
evaluatedOffends :: Face.Face Card.Type.Card -> Bool
evaluatedOffends card =
  let (inCounts, total) = evaluatedCounts card
   in inCounts /= total

-- The CR 115.10a bound-object tag, spelled once.
isBoundTag :: Text.Text
isBoundTag = Text.pack "IsBound"

-- How many CR 115.10a bound-object atoms this card carries in a position with no
-- resolution behind it -- a WISH's filter or CR 201.4a's naming restriction,
-- which share OutsideTheGameFramed; a KEYWORD's own; a COST paid with no
-- announcement behind it; or the target slot of an ability rule 702 mints --
-- and how many anywhere else. The FIRST
-- number is the offence here, which is the sibling position lints turned around:
-- the atom is answerable in every position whose evaluator supplies the
-- resolution's slots, and unanswerable in the four that supply none.
isBoundCounts :: Face.Face Card.Type.Card -> (Int, Int)
isBoundCounts card =
  let total wanted = sum (fmap (\(_, f) -> filterAtoms isBoundTag f) (filter (\(framing, _) -> elem framing [OutsideTheGameFramed, KeywordFramed, SlotlessCostFramed, MintedTargetSlot] == wanted) (cardFilters card)))
   in (total True, total False)

-- CR 400.11c's candidates are cards outside the game, which no spell or ability
-- affects, so no slot of the resolution names one -- and
-- Parun.Engine.Projection.View.viewOfCard, the view they are matched through, fills no
-- `identity` for Filter.IsBound to compare in any case. The atom in a wish's
-- filter is therefore a silent False rather than a rejected card. CR 201.4a's
-- naming restriction is matched through the same view by
-- Parun.Interpreter.legalCardName, so it is silent there too. This is where that
-- is made loud.
--
-- Two offences under one name, for hostOfSourceOffends' two reasons turned
-- around: the traversal found the atom inside a wish's filter, or the traversal
-- and the codec disagree about how many the card holds. The second disjunct is a
-- REGRESSION FENCE for boundNameOffends' reason.
--
-- Only IsBound, of the atoms that read a Context's slots. Shares Name Bound is
-- fenced to a mode's target slot by its own lint, so a wish's filter already
-- rejects it; IsControllerOfBound and HeldByBound are False wherever
-- Parun.Engine.Filter.matches reaches them -- a fact about every position but a
-- Scope.OverPlayers count's, not about this one.
isBoundOffends :: Face.Face Card.Type.Card -> Bool
isBoundOffends card =
  let (wished, elsewhere) = isBoundCounts card
   in wished /= 0 || wished + elsewhere /= jsonAtoms isBoundTag (Codec.encode (Face.Codec.codec Card.codec) card)

-- The CR 601.2b per-keyword tally's codec tag, spelled once.
timesPaidTag :: Text.Text
timesPaidTag = Text.pack "TimesPaid"

-- Every designator a Quantity.TimesPaid carries in an ENCODED face, as the
-- codec wrote it. Read off the encoding for canHostSubjectOffends' reason turned to a
-- payload: this module's three Quantity traversals answer in Counts and Filters,
-- neither of which can carry a Keyword, so the arm is invisible to all three.
--
-- The tagged arm and not the bare tag, jsonAtoms' distinction: only an object
-- whose "type" is the tag contributes, and what it contributes is the "value"
-- beside it -- Parun.JsonCodec.Common's shape for an Arm.payload.
timesPaidDesignators :: Value.Value -> [Value.Value]
timesPaidDesignators value = case value of
  Value.Array a -> concatMap timesPaidDesignators (Array.unwrap a)
  Value.Object o -> taggedValues timesPaidTag value <> concatMap (timesPaidDesignators . Pair.value) (Object.unwrap o)
  Value.String _ -> []
  Value.Null _ -> []
  Value.Boolean _ -> []
  Value.Number _ -> []

-- The keywords those designators name whole, under their OfKeyword arm.
timesPaidKeywords :: Value.Value -> [Value.Value]
timesPaidKeywords = concatMap (taggedValues (Text.pack "OfKeyword")) . timesPaidDesignators

-- The "value" of an object whose "type" is that tag, or nothing.
taggedValues :: Text.Text -> Value.Value -> [Value.Value]
taggedValues tag value = case value of
  Value.Object o ->
    let pairs = Object.unwrap o
        keyed k = fmap Pair.value (filter (\pair -> String.unwrap (Pair.name pair) == Text.pack k) pairs)
        tagged = Maybe.mapMaybe (\v -> case v of Value.String t | String.unwrap t == tag -> Just (); _ -> Nothing) (keyed "type")
     in if null tagged then [] else keyed "value"
  Value.Array _ -> []
  Value.String _ -> []
  Value.Null _ -> []
  Value.Boolean _ -> []
  Value.Number _ -> []

-- CR 601.2b's per-keyword tally, which CR 702.33c makes payable more than once
-- for a multikicker. Parun.Engine.Quantity joins TimesPaid's Keyword to
-- Parun.Engine.Cast's tally by structural equality, and that tally is keyed by
-- Parun.Engine.Keyword.optionalCosts of the face's own keywords -- so a keyword
-- this face never prints, or the same symbols in another order, reads 0 for the
-- life of the game with nothing red. This is where that is made loud.
--
-- Compared as ENCODINGS rather than as Keywords so the two sides come off the one
-- codec Parun.CodecIntegrationSpec round-trips; the Keyword's own Eq is what the
-- engine joins on, and the codec is injective, so the two agree.
--
-- Stated about the PRINTED keywords, which is what a card file can be wrong
-- about. Every Kicker or Multikicker in data/cards/ sits at a face's own
-- `keywords`; Wicker Picker's granted StickerKicker is named by no TimesPaid.
-- A Printed designator offends on a face printing no keyword it links to (CR
-- 607.2i, 702.33e), since it too would read 0 for the life of the game.
timesPaidOffends :: Face.Face Card.Type.Card -> Bool
timesPaidOffends card =
  let encoded = Codec.encode (Face.Codec.codec Card.codec) card
      printed = fmap (Codec.encode Keyword.Codec.codec) (Keyword.Engine.optionalCosts (Face.keywordSet card))
      designator = Codec.encode (KeywordDesignator.Codec.codec Keyword.Codec.codec)
      linked = [designator (KeywordDesignator.Printed family) | keyword <- Foldable.toList (Face.keywordSet card), Just family <- [Keyword.Engine.familyOf keyword], Keyword.Engine.designates (KeywordDesignator.Printed family) keyword]
      isPrinted = not . null . taggedValues (Text.pack "Printed")
   in any (`notElem` printed) (timesPaidKeywords encoded) || any (`notElem` linked) (filter isPrinted (timesPaidDesignators encoded))

-- Two things a TriggerCondition.AnyOf may not contain, checked at every depth so
-- that a nested one cannot smuggle either in.
--
-- A CR 603.8 STATE trigger, because the two kinds of condition are gathered by
-- different scans: Parun.Engine.Event.Trigger.stateTriggers walks the battlefield (and the
-- command zone) asking
-- whether the state holds, and Event.matchesTrigger walks the event log. An
-- ability that was both would be gathered by stateTriggers whenever any clause
-- held (that arm answers `any`), and CR 603.8's "not again until the ability has
-- left the stack" would then hold back the EVENT clauses too. Nothing else in the
-- tree catches this: both classifications compile, and each is individually
-- defensible.
--
-- A NESTED AnyOf, because a flat list says everything a nested one could and the
-- nesting only multiplies the shapes the classifications above have to be right
-- for.
anyOfOffends :: TriggerCondition.TriggerCondition -> Bool
anyOfOffends condition =
  let inside c = case c of
        TriggerCondition.StateIs _ -> True
        TriggerCondition.AnyOf _ -> True
        _ -> False
   in case condition of
        TriggerCondition.AnyOf conditions -> any inside conditions || any anyOfOffends conditions
        _ -> False

-- | A position lint's accepting side: each author's atoms, as many as named,
-- all sit in admitted positions, and they are the pool's only ones. The
-- table is what a new author extends; no total is pinned beside it.
assertAuthors ::
  Spec.Spec IO n ->
  Registry.Registry IO ->
  [Printing.Printing] ->
  String ->
  (Face.Face Card.Type.Card -> (Int, Int)) ->
  [(String, Int)] ->
  IO ()
assertAuthors s registry ps label counts authors = do
  counted <- traverse (\(name, _) -> fmap (\p -> (name, counts (S.combinedFace p))) (S.printingOf s registry name)) authors
  Spec.assertEqWith s label counted (fmap (\(name, n) -> (name, (n, 0))) authors)
  Spec.assertEqWith s "and they are the pool's only ones" (sum (fmap (uncurry (+) . counts . S.combinedFace) ps)) (sum (fmap snd authors))

filterPositionLintSpec :: (Monad n) => Spec.Spec IO n -> Registry.Registry IO -> [(FilePath, Either Text.Text Card.Type.Card)] -> n ()
filterPositionLintSpec s registry corpus = Spec.describe s "Lint" $ do
  -- CR 603.2's event triggers and CR 603.8's state triggers are gathered by two
  -- different scans, so one ability may not be both. See anyOfOffends for the two
  -- shapes this rejects and why each would be incoherent rather than merely odd.
  --
  -- Swept over the pool, with the non-vacuity assertion its neighbours carry: a
  -- pool with no AnyOf at all would pass this without examining anything.
  -- The pool's AnyOf cards -- Balemurk Leech, Bartered Cow and their like -- are
  -- all ACCEPTED here.
  Spec.it s "CR 603.2 no AnyOf mixes in a state trigger or nests another AnyOf" $ do
    ps <- S.allPrintings s corpus
    let conditions c = fmap TriggeredAbility.condition (Face.triggeredAbilities c)
        isAnyOf c = case c of TriggerCondition.AnyOf _ -> True; _ -> False
        offenders = filter (anyFace (any anyOfOffends . conditions) . Printing.card) ps
    Spec.assertBool
      s
      (any (anyFace (any isAnyOf . conditions) . Printing.card) ps)
      "the pool has a card with an AnyOf condition to lint"
    Spec.assertEqWith s "every AnyOf holds only event triggers, flat" (fmap (S.nameOf . Printing.card) offenders) []
  -- The REJECTING direction, against hand-built offenders rather than card files,
  -- as the repeated-face-name lint above does it.
  Spec.it s "the lint itself catches a state trigger and a nested AnyOf inside an AnyOf" $ do
    let never = Condition.Type.Compares (Compares.MkCompares (Quantity.Type.Literal 0) Comparison.Exactly (Quantity.Type.Literal 1))
        fine = TriggerCondition.AnyOf [TriggerCondition.SelfEnters, TriggerCondition.RoomFullyUnlocked PlayerRelation.You]
    Spec.assertBool s (not (anyOfOffends fine)) "the control: two event triggers side by side are fine"
    Spec.assertBool s (anyOfOffends (TriggerCondition.AnyOf [TriggerCondition.SelfEnters, TriggerCondition.StateIs never])) "a CR 603.8 state trigger inside an AnyOf is rejected"
    Spec.assertBool s (anyOfOffends (TriggerCondition.AnyOf [fine])) "and so is a nested AnyOf"
    -- The recursion is what the nesting check buys: a state trigger one level
    -- down is caught too.
    Spec.assertBool s (anyOfOffends (TriggerCondition.AnyOf [TriggerCondition.AnyOf [TriggerCondition.StateIs never]])) "including a state trigger buried one level down"
    -- NOT an offence outside an AnyOf: a bare state trigger is how every CR 603.8
    -- card in the pool is written, and this lint must not reject those.
    Spec.assertBool s (not (anyOfOffends (TriggerCondition.StateIs never))) "a bare state trigger is left alone"
  Spec.it s "no mode declares a slot named enchant" $ do
    ps <- S.allPrintings s corpus
    let offends c = any (Map.member Card.enchantSlot . Mode.targetSlots) (Modal.modes (Face.spell c))
        offenders = filter (anyFace offends . Printing.card) ps
    Spec.assertEqWith s "the enchant slot is never hand-declared" (fmap (S.nameOf . Printing.card) offenders) []
  -- CR 701.3a: "An Aura, Equipment, or Fortification can't be attached to an
  -- object or player it couldn't enchant, equip, or fortify, respectively." The
  -- atom that asks that question is answerable only where an attach frames the
  -- match, and vacuously False everywhere else. Not implemented: the atom at a
  -- RESOLUTION-TIME choice, where Infectious Rage's "choose a creature at random
  -- this Aura can enchant. Return this card to the battlefield attached to that
  -- creature" writes it (#3871). See canHostSubjectOffends for the
  -- two offences this one predicate covers.
  Spec.it s "CR 701.3a no card asks CanHostSubject outside a position an attach frames" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace canHostSubjectOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where an attach frames it" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the cards that do are ACCEPTED
    -- here rather than skipped -- at least one per framing opcode, so a
    -- cardFilters arm that forgot one would count its atom as zero and redden.
    assertAuthors
      s
      registry
      ps
      "each author's atoms are framed by an attach"
      canHostSubjectCounts
      [ ("Aura Graft", 1), -- its own attach
        ("Synthetic Aura Diffusion", 1), -- CR 303.4d's AttachTargetToEach
        ("Simic Guildmage", 1), -- the card's own CR 608.2d ruling
        ("Grifter's Blade", 1), -- a CR 614.1c entry replacement
        ("Glamer Spinners", 1), -- a group attach's destination
        ("Fumble", 1) -- a group attach, its 2018-06-08 ruling
      ]
    -- The traversal reaches a Filter position no effect, target slot or affected
    -- set would have led it to: CR 702.29e's typecycling predicate, on a real
    -- card. Its absence would not show up in the sweep above, because Ash Barrens
    -- does not author the atom -- only in this. KeywordFramed and not Unframed:
    -- the tag is applied by keywordFilters at the leaf, so a printed keyword's
    -- own filter carries it whatever field quoted the keyword.
    barrens <- S.printingOf s registry "Ash Barrens"
    Spec.assertBool
      s
      ( elem
          (KeywordFramed, Filter.Type.And [Filter.Type.HasCardType CardType.Land, Filter.Type.HasSupertype Supertype.Basic])
          (cardFilters (S.combinedFace barrens))
      )
      "CR 702.29e landcycling's filter is a position the sweep walks"
  -- CR 701.3a from the candidate's side: Filter.CanAttachToSubject is answerable
  -- only where the evaluator supplies the fixed host, which is a search's filter
  -- and nothing else. See canAttachToSubjectOffends for the two offences.
  Spec.it s "CR 701.3a no card asks CanAttachToSubject outside a search's filter" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace canAttachToSubjectOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only in a search's filter" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and every card that does is
    -- ACCEPTED here rather than skipped -- two saying "it" of their own source
    -- and one saying "that creature" of a slot its trigger bound, which is the
    -- axis Parun.Types.Search.subject carries and this lint is blind to.
    assertAuthors
      s
      registry
      ps
      "each author's atom is framed by its own search"
      canAttachToSubjectCounts
      [ ("Auratouched Mage", 1),
        ("Sovereigns of Lost Alara", 1),
        ("Bruna, Light of Alabaster", 1) -- a graveyard and a hand, not a library
      ]
    -- The unframed side has room to spare, so a Framing that had stopped marking
    -- searches would fail here rather than pass the sweep above by iterating over
    -- nothing.
    let positions = concatMap (cardFilters . S.combinedFace) ps
    Spec.assertBool s (length (filter ((== SearchFramed) . fst) positions) > 5) "the pool gives the accepted side search filters to be about"
  -- CR 201.4's chosen name is CR 701.3a's atom in nearly the same frame:
  -- answerable only where the resolution's own context is built
  -- (Parun.Engine.Resolve.Slots.effectContext), and a silent False everywhere
  -- else. See hasChosenNameOffends for the two offences.
  Spec.it s "CR 201.4 no card asks HasChosenName outside an admitted position" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace hasChosenNameOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where the resolution overlays the chosen names" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and EVERY card that does is
    -- ACCEPTED here rather than skipped -- at least one per admitted position,
    -- so a framing that stopped marking any would redden.
    assertAuthors
      s
      registry
      ps
      "each author's atoms are framed where the resolution overlays the chosen names"
      hasChosenNameCounts
      [ ("Ancient Vendetta", 1), -- its own search
        ("Predict", 1), -- its own mill tally
        ("Petra Sphinx", 1), -- the ObjectRef its move names
        ("Conundrum Sphinx", 1), -- the ObjectRef its move names
        ("Declaration of Naught", 1), -- its activated ability's target slot
        ("Null Chamber", 2), -- its printed player abilities
        ("Runed Halo", 1), -- its printed player ability
        ("Conjurer's Ban", 2), -- its stored player effects
        ("Cheering Fanatic", 1), -- its stored player effect
        ("Synthetic Name Ward", 1), -- its stored player effect
        ("Immediate Action", 1), -- its static ability's affected set
        ("Vexing Arcanix", 3), -- its two moves' ObjectRefs and its damage clause's gate
        ("Booby Trap", 1), -- its trigger condition
        ("Pithing Needle", 1), -- its activation prohibition's affected set
        ("Sphinx Ambassador", 1) -- its move clause's gate
      ]
  -- CR 702.16k's chosen player in the same frame one atom over: answerable only
  -- where a protection quality is read, and every one of those four positions
  -- takes its filter off a keyword. See ofChosenPlayerOffends for the two
  -- offences.
  Spec.it s "CR 702.16k no card asks OfChosenPlayer outside a keyword's own filter" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace ofChosenPlayerOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only in a keyword's filter" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the card that does is
    -- ACCEPTED here rather than skipped.
    assertAuthors s registry ps "each author's atom is framed by its own keyword" ofChosenPlayerCounts [("True-Name Nemesis", 1)]
  -- The hole that bucket had while every keyword payload was KeywordFramed. CR
  -- 702.6c's equip quality is a payload that is NOT read as a keyword: rule
  -- 702.6a's minted ability carries it into a target slot, which
  -- Parun.Engine.Target.slotContext answers with carrierChosenPlayer unfilled, so
  -- an equip quality asking CR 702.16k's chosen player would have passed the lint
  -- above and then matched nothing. MintedTargetSlot is what makes it loud.
  Spec.it s "CR 702.16k an equip quality is not a protection quality" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    blade <- S.printingOf s registry "Dúnedain Blade"
    let base = S.combinedFace piker
        creatures = Filter.Type.HasCardType CardType.Creature
        -- Buried under both combinators, so a lint reading only the top of a
        -- Filter would miss it.
        buried = Filter.Type.And [Filter.Type.Or [creatures, Filter.Type.OfChosenPlayer]]
        equipping quality = Keyword.Equip (Equip.MkEquip (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) []) quality EquipTarget.Creature)
        offending = base {Face.keywords = Map.singleton (equipping (Just buried)) 1}
        protecting = base {Face.keywords = Map.singleton (Keyword.Protection Protection.MkProtection {Protection.quality = buried, Protection.spares = Nothing}) 1}
    -- Ordered FIRST, and the assertion this framing exists for.
    Spec.assertBool s (ofChosenPlayerOffends offending) "OfChosenPlayer in an equip quality offends"
    Spec.assertEqWith s "counted outside the keyword bucket" (ofChosenPlayerCounts offending) (0, 1)
    -- The pair differing in exactly ONE thing: the same buried atom on the same
    -- face, moved into a quality rule 702.16 really does read off the keyword.
    Spec.assertBool s (not (ofChosenPlayerOffends protecting)) "the same atom in a protection quality does not"
    Spec.assertEqWith s "counted inside it" (ofChosenPlayerCounts protecting) (1, 0)
    -- So the framing rejects the ATOM and not the position: the printed quality
    -- in the pool carries it and is accepted.
    Spec.assertBool s (not (ofChosenPlayerOffends (S.combinedFace blade))) "Dúnedain Blade's own quality is accepted"
    Spec.assertEqWith
      s
      "and arrives framed as a minted target slot"
      (fmap fst (filter ((==) (Filter.Type.HasSubtype Subtype.Human) . snd) (cardFilters (S.combinedFace blade))))
      [MintedTargetSlot]
    -- The other half of what that framing promises, one atom over: the minted
    -- ability announces nothing, so CR 115.10a's bound object is as unanswerable
    -- in an equip quality as in a keyword's own filter, and isBoundCounts puts
    -- the framing in its offending list for that.
    let slot = SlotName.MkSlotName (Text.pack "target")
        bound = Filter.Type.And [Filter.Type.Or [creatures, Filter.Type.IsBound slot]]
    Spec.assertBool s (isBoundOffends (base {Face.keywords = Map.singleton (equipping (Just bound)) 1})) "IsBound in an equip quality offends too"
    Spec.assertBool s (not (isBoundOffends (base {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching bound) Nothing]}))) "and the same atom at an unframed position does not"
  -- CR 701.23a: a search looks through a zone, so one naming none can find
  -- nothing. Nothing else catches an empty set. Search.zones is defaulted-absent
  -- to the library, so a card file has to write "zones": [] on purpose -- and the
  -- result decodes, resolves, finds nothing and shuffles nothing, which reads
  -- exactly like a search whose filter matched nothing.
  Spec.it s "CR 701.23a every search names at least one zone" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace (any Set.null . searchZoneSets) . Printing.card) ps
    Spec.assertEqWith s "no card's search names an empty zone set" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors searches, and the one naming two zones is
    -- read here rather than skipped.
    moogle <- S.printingOf s registry "Delivery Moogle"
    Spec.assertEqWith
      s
      "Delivery Moogle's search names its library and its graveyard"
      (searchZoneSets (S.combinedFace moogle))
      [Set.fromList [Zone.Library, Zone.Graveyard]]
    Spec.assertBool s (length (concatMap (searchZoneSets . S.combinedFace) ps) > 5) "and the pool gives the sweep other searches to be about"
  -- CR 709.4a's Filter.Shares Name Bound is in CR 701.3a's position one axis over:
  -- answerable only where Filter.Context.slotNames is filled, and unanswerable --
  -- a silent False -- everywhere else. The positions ADMITTED here are a MODE's
  -- target slot, a CR 701.23 search filter, a CR 608.2c hand sweep's own filter
  -- and a CR 119.3 life loss amount, the last three since their arms take their
  -- context from the resolution (Parun.ResolveSpec's Bifurcate, Hour of Glory and
  -- Grim Reminder cases). That set
  -- is narrower than the set that would answer -- boundNameCounts says why
  -- -- so this rejects in the safe direction only. See boundNameOffends
  -- for the two offences and Framing for why CR 303.4a's enchant slot is not one
  -- of the safe positions.
  Spec.it s "CR 709.4a no card asks a slot-anchored Shares Name outside a mode's target slot, a search filter, a hand sweep or a life loss amount" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace boundNameOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only in a target slot's, a search's, a hand sweep's or a life loss amount's filter" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous, the way the sibling sweeps would be alone: the pool authors the
    -- atom, and the cards that do are ACCEPTED here rather than skipped -- one in
    -- each admitted position, so no member of the set is unwitnessed.
    assertAuthors
      s
      registry
      ps
      "each author's atom is in an admitted position"
      boundNameCounts
      [ ("Harness the Storm", 1), -- its trigger's target slot
        ("Bifurcate", 1), -- its search's filter
        ("March of Burgeoning Life", 1), -- its search's filter
        ("Hour of Glory", 1), -- its hand sweep's filter
        ("Grim Reminder", 1), -- its life loss amount's Count filter
        ("Haunting Echoes", 1), -- its search's filter
        ("Doubling Chant", 1), -- its search's filter, against its loop's member
        ("Shimian Specter", 1) -- its search's filter, against its loop's member
      ]
    -- Both sides of the split, with room to spare under the pool's real figures:
    -- a traversal that had stopped walking, or a Framing that had stopped marking
    -- target slots, would fail here rather than pass the sweep above by iterating
    -- over nothing. Without the second, "elsewhere" would be every occurrence and
    -- this would silently become the sibling atoms' "no card writes it at all".
    let positions = concatMap (cardFilters . S.combinedFace) ps
    Spec.assertBool s (length positions > 100) "the pool gives the traversal Filter positions to walk"
    Spec.assertBool s (length (filter ((== InTargetSlot) . fst) positions) > 10) "and target slot filters for the accepted side to be about"
    Spec.assertBool s (length (filter ((== SearchFramed) . fst) positions) > 10) "and search filters, the accepted side's other half"
  -- CR 205.3m's bound comparison in Shares Name Bound's frame, one field over:
  -- answerable only where effectContext or Target.slotContext fills
  -- Filter.Context.slotCreatureTypes. See boundCreatureTypeOffends for the two
  -- offences.
  Spec.it s "CR 205.3m no card asks a slot-anchored Shares CreatureType outside a resolution's own positions or a target slot" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace boundCreatureTypeOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where a resolution or a target slot fills the creature types" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: one card per admitted position the pool uses is ACCEPTED.
    blade <- S.printingOf s registry "Heirloom Blade"
    Spec.assertEqWith s "Heirloom Blade's two atoms are in its ObjectRefs" (boundCreatureTypeCounts (S.combinedFace blade)) (2, 0)
    clanger <- S.printingOf s registry "Mudbutton Clanger"
    let face = S.combinedFace clanger
        atom = Filter.Type.Shares Trait.CreatureType (Anchor.Bound (SlotName.MkSlotName (Text.pack "self")))
        restricted = face {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching atom) Nothing]}
    Spec.assertEqWith s "Mudbutton Clanger's one atom is in its clause's gate" (boundCreatureTypeCounts face) (1, 0)
    unbury <- S.printingOf s registry "Unbury"
    Spec.assertEqWith s "Unbury's two atoms are in its target slots, one naming each sibling" (boundCreatureTypeCounts (S.combinedFace unbury)) (2, 0)
    -- The lint's own proof, the pair differing in one position: the same atom in
    -- a static restriction's affected set, read through a bare contextFor.
    Spec.assertBool s (boundCreatureTypeOffends restricted) "the atom in an affected set offends"
    Spec.assertEqWith s "counted outside the admitted positions" (boundCreatureTypeCounts restricted) (1, 1)
  -- CR 208.1's bound comparison in the arm above's frame, one Filter.Context field
  -- over: answerable only where effectContext fills Filter.Context.slotMeasures.
  -- See ofBoundOffends for the two offences.
  Spec.it s "CR 208.1 no card compares against a bound object outside a resolution's own positions" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace ofBoundOffends . Printing.card) ps
    Spec.assertEqWith s "the operand sits only where the resolution fills the bound measures" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the card that does is ACCEPTED.
    profaner <- S.printingOf s registry "Profaner of the Dead"
    let face = S.combinedFace profaner
        atom = Filter.Type.Measures (Measures.MkMeasures Measure.Toughness Comparison.LessThan (Operand.OfBound (BoundMeasure.MkBoundMeasure (SlotName.MkSlotName (Text.pack "thatExploitedCreature")) Measure.Toughness)))
        restricted = face {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching atom) Nothing]}
    Spec.assertEqWith s "Profaner of the Dead's one atom is in its ObjectRef" (ofBoundCounts face) (1, 0)
    -- The lint's own proof, the pair differing in one position: the same atom in
    -- a static restriction's affected set, read through a bare contextFor.
    Spec.assertBool s (ofBoundOffends restricted) "the atom in an affected set offends"
    Spec.assertEqWith s "counted outside the admitted positions" (ofBoundCounts restricted) (1, 1)
  -- CR 110.2 asked of the bound object's HOST (CR 303.4b), the arm above's frame
  -- one Filter.Context field over and one position wider: effectContext fills
  -- Filter.Context.slotHostControllers, and the attach destination is one of its
  -- positions now that Parun.Engine.Attach.hostsFor takes its Context from the
  -- caller. See sameControllerAsHostOfBoundOffends for the two offences.
  Spec.it s "CR 110.2 no card asks SameControllerAsHostOfBound outside a resolution's own positions" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace sameControllerAsHostOfBoundOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where the resolution fills the hosts' controllers" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the card that does is ACCEPTED.
    guildmage <- S.printingOf s registry "Simic Guildmage"
    let face = S.combinedFace guildmage
        atom = Filter.Type.SameControllerAsHostOfBound (SlotName.MkSlotName (Text.pack "target"))
        restricted = face {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching atom) Nothing]}
    Spec.assertEqWith s "Simic Guildmage's one atom is in its attach destination" (sameControllerAsHostOfBoundCounts face) (1, 0)
    -- The lint's own proof, the pair differing in one position: the same atom in
    -- a static restriction's affected set, read through a bare contextFor.
    Spec.assertBool s (sameControllerAsHostOfBoundOffends restricted) "the atom in an affected set offends"
    Spec.assertEqWith s "counted outside the admitted positions" (sameControllerAsHostOfBoundCounts restricted) (1, 1)
  -- CR 205.2a asked of the same host (CR 303.4b), the arm above one
  -- characteristic over and one position NARROWER: this atom reads
  -- Filter.Context.subjectHostCardTypes, which Parun.Engine.Attach.hostsFor fills
  -- and nothing else does, so an attach's destination is the only position that
  -- answers it. See hostOfSubjectCardTypeOffends for the two offences.
  Spec.it s "CR 205.2a no card asks HostOfSubjectHasCardType outside a position an attach frames" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace hostOfSubjectCardTypeOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where an attach fills the subject's host" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the card that does is
    -- ACCEPTED. Two of them, one per card type "of that type" ranges over.
    alteration <- S.printingOf s registry "Enchantment Alteration"
    let face = S.combinedFace alteration
        atom = Filter.Type.HostOfSubjectHasCardType CardType.Creature
        restricted = face {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching atom) Nothing]}
    Spec.assertEqWith s "Enchantment Alteration's two atoms are in its attach destination" (hostOfSubjectCardTypeCounts face) (2, 0)
    -- The lint's own proof, the pair differing in one position: the same atom in
    -- a static restriction's affected set, read through a bare contextFor.
    Spec.assertBool s (hostOfSubjectCardTypeOffends restricted) "the atom in an affected set offends"
    Spec.assertEqWith s "counted outside the admitted positions" (hostOfSubjectCardTypeCounts restricted) (2, 1)
  -- CR 110.2's Filter.ControllerRelatesToBound is CR 709.4a's atom one characteristic
  -- over, in the same position and with the STAKES reversed: it is vacuously TRUE
  -- where Filter.Context.slotControllers has no key for its slot, so an atom
  -- outside the positions filling it admits every candidate the card meant to
  -- exclude rather than none. See controllerRelatesToBoundOffends.
  Spec.it s "CR 110.2 no card asks ControllerRelatesToBound outside a mode's target slot, an attach destination, a stored class or an effect's object" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace controllerRelatesToBoundOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only in an admitted position" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the cards that do are ACCEPTED
    -- here rather than skipped -- one in each admitted position.
    assertAuthors
      s
      registry
      ps
      "each author's atom is in an admitted position"
      controllerRelatesToBoundCounts
      [ ("Bioshift", 1), -- its second target slot
        ("Simic Guildmage", 1), -- its first ability, Bioshift's sentence
        ("Glamer Spinners", 1), -- its attach destination
        ("Sorrow's Path", 1), -- its second target slot
        ("Mark for Death", 1), -- its stored class, baked by Parun.Engine.Resolve.Common.storedClass
        ("Flame Wave", 1), -- its damage's object
        ("Chandra Nalaar", 1), -- its -8, Flame Wave's sentence
        ("Chandra's Fury", 1), -- its damage's object, Flame Wave's sentence
        ("Necrotic Plague", 1) -- its trigger's target slot, relative to the dead creature's controller
      ]
    -- The REJECTING direction, hand-built for the reason every sibling lint's is:
    -- a card that offends must not be loadable, so no file can carry one. Buried
    -- under all three combinators, so an implementation reading only the top of a
    -- Filter would accept it.
    piker <- S.printingOf s registry "Goblin Piker"
    let atom = Filter.Type.ControllerRelatesToBound PlayerRelation.You (SlotName.MkSlotName (Text.pack "from"))
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]
        planted =
          (S.combinedFace piker)
            { Face.staticAbilities =
                [ StaticAbility.MkStaticAbility
                    (Affected.Matching buried)
                    Nothing
                    Set.empty
                    Nothing
                    Nothing
                    (NonEmpty.singleton Modification.LoseAllAbilities)
                ]
            }
    Spec.assertEqWith s "the same atom in a static ability's affected set is an offence" (controllerRelatesToBoundCounts planted) (0, 1)
    Spec.assertBool s (controllerRelatesToBoundOffends planted) "and the lint says so"
    Spec.assertBool s (not (controllerRelatesToBoundOffends (S.combinedFace piker))) "where the ungrafted card is accepted"
  -- CR 601.3a's lookahead (Parun.Engine.Filter.manaValueThresholds) bounds its
  -- sample by the mana value LITERALS a prohibition compares against, so a
  -- player effect comparing a mana value against any other operand would leave
  -- the sample too short with nothing failing. The position lints above keep the
  -- source, bound-object and enclosing-amount operands out of a player effect;
  -- this keeps the rest out too.
  Spec.it s "CR 601.3a no player effect compares a mana value against anything but a literal" $ do
    ps <- S.allPrintings s corpus
    let encode = Codec.encode (Filter.Codec.codec Keyword.Codec.codec)
        inPlayerEffects wanted c = sum [manaValueComparisons wanted (encode f) | (framing, f) <- cardFilters c, elem framing [PlayerEffectFramed, StoredPlayerEffectFramed]]
        nonLiteral = (/= Text.pack "Literal")
        offenders = filter (anyFace ((/= 0) . inPlayerEffects nonLiteral) . Printing.card) ps
    Spec.assertEqWith s "every player effect's mana value comparison is against a literal" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the traversal reaches the pool's literal ones, and the
    -- counter sees a non-literal one buried under a combinator.
    Spec.assertBool s (sum (fmap (sum . fmap (inPlayerEffects (== Text.pack "Literal")) . Card.Type.faces . Printing.card) ps) /= 0) "the pool's player effects compare mana values against literals"
    Spec.assertEqWith s "a planted comparison against the candidate's own power is counted" (manaValueComparisons nonLiteral (encode (Filter.Type.Not (Filter.Type.Measures (Measures.MkMeasures Measure.ManaValue Comparison.AtMost (Operand.Own Measure.Power)))))) 1
    -- And the same read from the other side: power against the candidate's own
    -- mana value varies with X exactly as the measure would.
    Spec.assertEqWith s "so is one reading the mana value through the operand" (manaValueComparisons nonLiteral (encode (Filter.Type.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.Own Measure.ManaValue))))) 1
    Spec.assertEqWith s "and a power literal is not" (manaValueComparisons nonLiteral (encode (Filter.Type.Measures (Measures.MkMeasures Measure.Power Comparison.AtLeast (Operand.Literal 4))))) 0
  -- CR 202.3's computed bound is CR 709.4a's atom one axis over once more, and the
  -- axis is the SLOT rather than the Framing: Parun.Engine.Target.slotContext fills
  -- Filter.Context.slotAmount off the target slot's own Quantity, so an
  -- EnclosingAmount operand in a slot naming no amount -- or anywhere that is not
  -- a target slot, a conjure's reference pick or a combat restriction's affected
  -- set at all -- is a silent False. See enclosingAmountCounts.
  Spec.it s "CR 202.3 no card compares against an enclosing amount outside a slot that names one" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace enclosingAmountOffends . Printing.card) ps
    Spec.assertEqWith s "the operand sits only where the slot supplies the bound" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the operand, and every card that does is
    -- ACCEPTED here rather than skipped.
    --
    -- At most, against the mana value: Celestine, the Living Saint; Ratchet,
    -- Field Medic, through a DELAYED ability (CR 603.12's reflexive, whose slot is
    -- baked and matched exactly as an ordinary trigger's is); Venerable
    -- Warsinger, whose X is CR 603.2's own event amount; Stir the Grave, the first
    -- on a SPELL, whose X CR 601.2b announces one step before CR 601.2c chooses the
    -- target; Synthetic Borrowed Exhumation, the first whose slot is also JOINTLY
    -- JUDGED (Parun.Engine.Target.jointlyJudged); Synthetic Measured Refrain, whose
    -- bound folds over what a sibling slot names (Parun.TargetSpec's "CR 700.2d a
    -- repeated mode's computed bound measures its own occurrence's sibling
    -- slot"); and Blighted Nightmare and Tameshi, Reality Architect, on ACTIVATED
    -- abilities, whose X CR 602.2b announces.
    --
    -- Exactly, against the mana value: Chthonian Nightmare, Tamiyo, Compleated
    -- Sage, Synthetic Counted Verdict and Spell Blast in a slot, and Fear of
    -- Change and Ornate Imitations in a reference pick, at the top level and
    -- inside a ForEachNumber body.
    --
    -- At most and less than, against the mana value on a SPELL whose X shares the
    -- cost with a count announced beside it: March of Otherworldly Light and March
    -- of Burgeoning Life.
    --
    -- At most, against the power: Spawnbroker's `theirs` slot and Nihiloor's.
    --
    -- Greater than, against the power, in a combat restriction's affected set:
    -- Ensnaring Bridge.
    assertAuthors
      s
      registry
      ps
      "each author's one operand is in the slot that names its bound"
      enclosingAmountCounts
      [ ("Celestine, the Living Saint", 1),
        ("Ratchet, Field Medic", 1),
        ("Venerable Warsinger", 1),
        ("Stir the Grave", 1),
        ("Synthetic Borrowed Exhumation", 1),
        ("Synthetic Measured Refrain", 1),
        ("Blighted Nightmare", 1),
        ("Tameshi, Reality Architect", 1),
        ("Chthonian Nightmare", 1),
        ("Tamiyo, Compleated Sage", 1),
        ("Synthetic Counted Verdict", 1),
        ("Spell Blast", 1),
        ("Fear of Change", 1),
        ("Ornate Imitations", 1),
        ("Spawnbroker", 1),
        ("Nihiloor", 1),
        ("March of Otherworldly Light", 1),
        ("March of Burgeoning Life", 1),
        ("Ensnaring Bridge", 1)
      ]
    -- The rejected side, which the sweep above cannot show while the pool has no
    -- offender: the SAME atom, buried under all three combinators, in a target
    -- slot that names no amount -- the position a card author would most plausibly
    -- reach for, since it differs from the accepted one by an absent key alone.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.Measures (Measures.MkMeasures Measure.ManaValue Comparison.AtMost Operand.EnclosingAmount))]]
        slotWith slot =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) slot) Seq.empty
            }
        amountless = slotWith (TargetSlot.required Pool.Creatures (Just buried))
    Spec.assertEqWith s "a planted atom in an amountless slot is an offence" (enclosingAmountCounts amountless) (0, 1)
    Spec.assertBool s (enclosingAmountOffends amountless) "and the lint says so"
    -- And the pair that differs in exactly one thing: the same face with the same
    -- filter, in a slot that DOES name an amount, is accepted -- so the lint is
    -- reading the amount key rather than rejecting every planted atom.
    let amounted = slotWith (TargetSlot.withAmount (Quantity.Type.LifeGainedThisTurn (PlayerRef.Relative PlayerRelation.You)) (TargetSlot.required Pool.Creatures (Just buried)))
    Spec.assertEqWith s "the same atom in a slot that names one is not" (enclosingAmountCounts amounted) (1, 0)
    -- The same pair at the other position: a conjure's reference pick, which
    -- fills the bound only where it names one.
    let conjuring amount =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneMode (Seq.singleton (Effect.Conjure (Conjure.MkConjure Conjure.defaultQuantity (ConjureCards.Reference (FromReference.MkFromReference buried amount)) Conjure.defaultSelection (ConjureDestination.Battlefield ConjureEntry.defaultValue) Nothing)))
            }
    Spec.assertEqWith s "a planted atom in a reference pick naming no amount is an offence" (enclosingAmountCounts (conjuring Nothing)) (0, 1)
    Spec.assertEqWith s "and one naming an amount is not" (enclosingAmountCounts (conjuring (Just (Quantity.Type.Literal 4)))) (1, 0)
    -- And at the third: a combat restriction's affected set.
    let restricting amount =
          (S.combinedFace piker)
            { Face.combatRestrictions = [CombatRestriction.CantAttack (AffectedUnless.MkAffectedUnless (Affected.Matching buried) Nothing Nothing amount)]
            }
    Spec.assertEqWith s "a planted atom in a restriction naming no amount is an offence" (enclosingAmountCounts (restricting Nothing)) (0, 1)
    Spec.assertEqWith s "and one naming an amount is not" (enclosingAmountCounts (restricting (Just (Quantity.Type.Literal 4)))) (1, 0)
  -- CR 608.2d's other-candidates operand is answerable only in an edict's or a
  -- chosen permanent's own filter. See otherCandidateCounts.
  Spec.it s "CR 608.2d no card compares against other candidates outside an edict or a chosen permanent" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace ((/= 0) . snd . otherCandidateCounts) . Printing.card) ps
    Spec.assertEqWith s "the operand sits only in an edict's or a chosen permanent's filter" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: these author it, and are accepted -- each with how many.
    -- Juxtapose writes two, one per ChoosePermanents.
    let authors :: [(String, Int)]
        authors =
          [ ("Break Under Pressure", 1),
            ("Consumed by Greed", 1),
            ("Crackling Doom", 1),
            ("Drop of Honey", 1),
            ("Extract a Confession", 1),
            ("Fall of the Impostor", 1),
            ("Flare of Malice", 1),
            ("Highcliff Felidar", 1),
            ("Juxtapose", 2),
            ("Myrkul's Edict", 1),
            ("Penregon Besieged", 1),
            ("Porphyry Nodes", 1),
            ("Professor Onyx", 1),
            ("Purging Scythe", 1),
            ("Riveteers Charm", 1),
            ("Soul Shatter", 1),
            ("Tariff", 1),
            ("Summon: Valefor", 1),
            ("The Dining Car", 1),
            ("Witch-king, Bringer of Ruin", 1)
          ]
    assertAuthors s registry ps "each author's operands are in its edict or chosen permanents" otherCandidateCounts authors
    -- The rejected side: the same atom in a target slot's filter.
    piker <- S.printingOf s registry "Goblin Piker"
    let atom = Filter.Type.And [Filter.Type.HasCardType CardType.Creature, Filter.Type.Measures (Measures.MkMeasures Measure.Power Comparison.AtLeast (Operand.OfEachOtherCandidate Measure.Power))]
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just atom))) Seq.empty
            }
    Spec.assertEqWith s "a planted atom in a target slot is an offence" (otherCandidateCounts planted) (0, 1)
    -- And in a chosen permanent's own filter, the pair differing in the zone
    -- alone: chosenCandidates' exile arm never calls Filter.amongCandidates.
    let choosing zone =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneMode (Seq.singleton (Effect.Destroy (Destroy.MkDestroy (ObjectRef.ChosenPermanents (ChosenPermanents.MkChosenPermanents atom (PlayerRef.InSlot Binding.you) HowMany.one zone)) Regenerability.Regenerable Nothing Nothing Nothing)))
            }
    Spec.assertEqWith s "the atom in a battlefield choice's filter is accepted" (otherCandidateCounts (choosing Zone.Battlefield)) (1, 0)
    Spec.assertEqWith s "and in an exile choice's filter is an offence" (otherCandidateCounts (choosing Zone.Exile)) (0, 1)
  -- CR 303.4b's Filter.IsHostOfSource is CR 709.4a's atom one axis over again:
  -- answerable only in the positions `hostFramed` admits. See hostOfSourceOffends for the two offences.
  Spec.it s "CR 303.4b no card asks IsHostOfSource where the source's host is unknown" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace hostOfSourceOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only where the host is supplied" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the cards that do are ACCEPTED
    -- here rather than skipped, every leg of the tagging among them.
    assertAuthors
      s
      registry
      ps
      "each author's atoms are framed"
      hostOfSourceCounts
      [ ("Ray of Frost", 3), -- a CR 604.2 clause, a CR 603.4 clause and an Effect.Tap's ObjectRef
        ("Oppressive Rays", 1), -- a printed player ability's own effect (Parun.PlayerEffectSpec)
        ("Pariah", 1), -- a CR 614.1 replacement row's own Filter (Parun.ReplacementSpec)
        ("Animate Dead", 1), -- the ObjectRef of its return
        ("Bewitching Leechcraft", 1), -- a CR 603.4 tap
        ("Abduction", 1), -- an untap in the same entering trigger
        ("Carry Away", 1), -- a CR 603.4 Effect.Unattach
        ("Tamiyo's Compleation", 2), -- its tap and its unattach
        ("Bronzehide Lion", 1), -- the quoted ability its CR 611.2e return grants
        ("Freed from the Real", 2), -- an activated tap and untap
        ("Infinite Reflection", 1), -- a CR 707.5 copy entry, read as Pariah's is
        ("Firebreathing", 1), -- an activated pump
        ("Shiv's Embrace", 1), -- Firebreathing's wording
        ("Regeneration", 1), -- a loop whose member its shield names
        ("Ring of Xathrid", 1) -- Regeneration's wording, through an Equipment
      ]
    -- The rejected side, which the sweep above cannot show while the pool has no
    -- offender: the same atom planted in a SPELL's target slot -- the position a
    -- card author would most plausibly reach for -- IS counted as elsewhere.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not Filter.Type.IsHostOfSource]]
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just buried))) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is an offence" (hostOfSourceCounts planted) (0, 1)
    Spec.assertBool s (hostOfSourceOffends planted) "and the lint says so"
    -- A PERMANENT's trigger condition is source-framed, but CR 704.5n has
    -- unattached an Equipment before a CR 603.10a look-back is matched (gap
    -- #5089), so it is refused.
    let onTrigger = (S.combinedFace piker) {Face.triggeredAbilities = [oneEffectTrigger (TriggerCondition.PermanentEnters buried) (Effect.Draw (Draw.MkDraw (PlayerRef.InSlot Binding.you) (Quantity.Type.Literal 1) Nothing))]}
    Spec.assertEqWith s "a trigger condition asking it is an offence too" (hostOfSourceCounts onTrigger) (0, 1)
    -- CastOffer.payingInstead carries SlotlessCostFramed and is paid framed by
    -- the OFFERED card (Parun.Engine.Resolve.Effect.offerCastOnce), so neither the
    -- host nor a chosen value of the offering object answers there.
    Spec.assertEqWith s "an offer's cost is not source-framed" (sourceFramed SlotlessCostFramed, hostFramed SlotlessCostFramed) (False, False)
  -- CR 613.4c's "it": the atoms aimed at a quantity's object are answerable only
  -- in a Count's filter. See evaluatedOffends.
  Spec.it s "CR 613.4c no card asks an evaluated-object atom outside a Count" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace evaluatedOffends . Printing.card) ps
    Spec.assertEqWith s "the atom sits only in a Count's filter" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: Thran Power Suit writes it twice, once per half of its pump.
    suit <- S.printingOf s registry "Thran Power Suit"
    Spec.assertEqWith s "Thran Power Suit's two atoms are both in Counts" (evaluatedCounts (S.combinedFace suit)) (2, 2)
    -- Coat of Arms writes IsEvaluated and the Evaluated anchor once per half.
    coat <- S.printingOf s registry "Coat of Arms"
    Spec.assertEqWith s "Coat of Arms' four atoms are all in Counts" (evaluatedCounts (S.combinedFace coat)) (4, 4)
    -- The rejected side: the same atom planted in a target slot.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.IsAttachedTo Anchor.Evaluated)]]
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just buried))) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is outside every Count" (evaluatedCounts planted) (0, 1)
    Spec.assertBool s (evaluatedOffends planted) "and the lint says so"
    let others = Filter.Type.And [Filter.Type.Not Filter.Type.IsEvaluated, Filter.Type.Shares Trait.CreatureType Anchor.Evaluated]
        plantedOthers =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just others))) Seq.empty
            }
    Spec.assertEqWith s "Coat of Arms' two atoms planted are outside every Count" (evaluatedCounts plantedOthers) (0, 2)
  -- A pair Filter.matches has no reading for answers False wherever it sits,
  -- so it is rejected outright rather than by position (#5636).
  Spec.it s "no card writes a Shares or IsAttachedTo anchor the filter context carries no values for" $ do
    ps <- S.allPrintings s corpus
    let encodedFace = Codec.encode (Face.Codec.codec Card.codec)
        offenders = filter (anyFace (\face -> fst (unreadAnchorCounts (encodedFace face)) /= 0) . Printing.card) ps
    Spec.assertEqWith s "every anchored atom has a reading" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool writes the atoms the sweep is about.
    Spec.assertBool s (sum (fmap (snd . unreadAnchorCounts . encodedFace . S.combinedFace) ps) > 10) "the pool writes anchored atoms"
    -- The rejected side: radiance's "each other creature that shares a color
    -- with it" and Street Sweeper's "Auras attached to target land", planted in
    -- a target slot, beside a read pair that is not counted.
    piker <- S.printingOf s registry "Goblin Piker"
    let slot = SlotName.MkSlotName (Text.pack "target")
        plantedWith atom =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton slot (TargetSlot.required Pool.Creatures (Just (Filter.Type.And [Filter.Type.Not atom])))) Seq.empty
            }
    Spec.assertEqWith s "a planted Shares Color Bound is unread" (unreadAnchorCounts (encodedFace (plantedWith (Filter.Type.Shares Trait.Color (Anchor.Bound slot))))) (1, 1)
    Spec.assertEqWith s "a planted IsAttachedTo Bound is unread" (unreadAnchorCounts (encodedFace (plantedWith (Filter.Type.IsAttachedTo (Anchor.Bound slot))))) (1, 1)
    Spec.assertEqWith s "a planted Shares Name Bound is read" (unreadAnchorCounts (encodedFace (plantedWith (Filter.Type.Shares Trait.Name (Anchor.Bound slot))))) (0, 1)
  -- CR 702.33d: a kicker tally names one of the face's OWN kicker keywords,
  -- joined to Parun.Engine.Cast's per-keyword map by structural equality. See
  -- timesPaidOffends for why this is read off the encoding.
  Spec.it s "CR 702.33d every kicker tally names a cost its face prints" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace timesPaidOffends . Printing.card) ps
    Spec.assertEqWith s "no card counts a kicker cost its face never prints" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the arm, and the cards that do are ACCEPTED
    -- here rather than swept past. Gnarlid Pack counts its multikicker once and
    -- Sunscape Battlemage its two CR 702.33b kickers once each.
    gnarlid <- S.printingOf s registry "Gnarlid Pack"
    sunscape <- S.printingOf s registry "Sunscape Battlemage"
    let tallies = length . timesPaidKeywords . Codec.encode (Face.Codec.codec Card.codec) . S.combinedFace
    Spec.assertEqWith s "the pool writes three tallies for this lint to be about" (fmap tallies [gnarlid, sunscape]) [1, 2]
    -- The REJECTING direction, as faces differing from the printed one in the
    -- kicker cost ALONE: Gnarlid Pack's {1}{G} respelled {G}{1} is a different Map
    -- key, so the tally reads 0 for the life of the game.
    let face = S.combinedFace gnarlid
        reverseMana cost = cost {Cost.Type.mana = fmap (\(ManaCost.MkManaCost symbols) -> ManaCost.MkManaCost (reverse symbols)) (Cost.Type.mana cost)}
        respell keyword = case keyword of
          Keyword.Multikicker cost -> Keyword.Multikicker (reverseMana cost)
          Keyword.StickerKicker cost -> Keyword.StickerKicker (reverseMana cost)
          _ -> keyword
    Spec.assertBool s (not (timesPaidOffends face)) "the control: Gnarlid Pack as printed is accepted"
    Spec.assertBool s (timesPaidOffends (face {Face.keywords = Map.mapKeys respell (Face.keywords face)})) "a reordered multikicker cost is rejected"
    Spec.assertBool s (timesPaidOffends (face {Face.keywords = Map.empty})) "and so is a face that counts a kicker it prints none of"
    burst <- S.printingOf s registry "Burst Lightning"
    Spec.assertBool s (not (timesPaidOffends (S.combinedFace burst))) "the control: Burst Lightning's Printed Kicker reading is accepted"
    Spec.assertBool s (timesPaidOffends ((S.combinedFace burst) {Face.keywords = Map.empty})) "and rejected on a face printing no kicker"
    scrapshooter <- S.printingOf s registry "Scrapshooter"
    Spec.assertBool s (not (timesPaidOffends (S.combinedFace scrapshooter))) "the control: Scrapshooter's Printed Gift reading is accepted"
    Spec.assertBool s (timesPaidOffends ((S.combinedFace scrapshooter) {Face.keywords = Map.empty})) "and rejected on a face printing no gift"
  -- CR 702.122d's Filter.CantCrewVehicles is the one atom here that no card may
  -- write ANYWHERE, rather than one admitted at some positions: it is answerable
  -- only where Parun.Engine.Cost.tapCandidates gathers the prohibition, and it is
  -- minted only by Parun.Engine.Keyword's `crew` -- which is what confines rule
  -- 702.122d to a crew cost, the same cost component being printable outside one
  -- (data/cards/synthetic-crewed-battery.json). A card writing it would read as a
  -- crew prohibition in a position that gathers none.
  Spec.it s "CR 702.122d no card asks CantCrewVehicles" $ do
    ps <- S.allPrintings s corpus
    let atomsOf tag = jsonAtoms tag . Codec.encode (Face.Codec.codec Card.codec) . S.combinedFace
    Spec.assertEqWith s "the pool authors the atom nowhere" (fmap (S.nameOf . Printing.card) (filter ((/= 0) . atomsOf cantCrewVehiclesTag) ps)) []
    -- NOT vacuous in the way an unreachable sweep would be: the tag the sweep
    -- counts is the atom's own wire name, so a renamed constructor fails here
    -- rather than passing by counting nothing.
    Spec.assertEqWith
      s
      "and that tag is what the atom encodes as"
      (jsonAtoms cantCrewVehiclesTag (Codec.encode (Filter.Codec.codec Keyword.Codec.codec) Filter.Type.CantCrewVehicles))
      1
    -- The traversal reaches a card's filters at all, which the zero above cannot
    -- show: the same sweep over an atom the pool DOES author is non-zero.
    Spec.assertBool
      s
      (sum (fmap (atomsOf (Text.pack "HasCardType")) ps) > 0)
      "and the sweep reaches the filters a card does write"
  -- CR 115.10a's Filter.IsBound is the position lints' MIRROR: it is answerable
  -- wherever the evaluator hands over the resolution's slots and the candidate is
  -- an object, and unanswerable in the one card-authored position whose
  -- candidates are not objects in the game -- CR 400.11c's wish filter, matched
  -- against a printed face. See isBoundOffends for the two offences.
  -- CR 601.2c: Filter.IsTarget reads the targets a cast or an activation
  -- stamped, so it is answerable in the cost that announcement pays and a
  -- silent False elsewhere (isTargetStrays).
  Spec.it s "CR 601.2c no card asks IsTarget outside a cost an announcement pays" $ do
    ps <- S.allPrintings s corpus
    Spec.assertEqWith s "no card asks IsTarget where nothing stamps the targets" (fmap (S.nameOf . Printing.card) (filter (anyFace isTargetOffends . Printing.card) ps)) []
    edict <- S.printingOf s registry "Synthetic Spiteful Edict"
    rite <- S.printingOf s registry "Synthetic Spiteful Rite"
    altar <- S.printingOf s registry "Synthetic Spiteful Altar"
    let atoms = jsonAtoms isTargetTag . Codec.encode (Face.Codec.codec Card.codec) . S.combinedFace
    Spec.assertEqWith s "and the added, additional and activation costs that ask it are accepted" (fmap atoms [edict, rite, altar], fmap (isTargetOffends . S.combinedFace) [edict, rite, altar]) ([1, 1, 1], [False, False, False])
    piker <- S.printingOf s registry "Goblin Piker"
    let planted = (S.combinedFace piker) {Face.spell = Mint.oneMode (Seq.singleton (Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching (Filter.Type.Not Filter.Type.IsTarget)) Regenerability.Regenerable Nothing Nothing Nothing)))}
    Spec.assertBool s (isTargetOffends planted) "the same atom in an effect's filter is an offence"
  Spec.it s "CR 400.11c no card asks IsBound in a wish's filter" $ do
    ps <- S.allPrintings s corpus
    let offenders = filter (anyFace isBoundOffends . Printing.card) ps
    Spec.assertEqWith s "no card names a bound slot where the candidate is a card outside the game" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous: the pool authors the atom, and the cards that do are ACCEPTED
    -- here rather than skipped: Showstopping Surprise writes "each other
    -- creature" as Not (IsBound "target"), and that atom is counted on the
    -- accepted side.
    surprise <- S.printingOf s registry "Showstopping Surprise"
    Spec.assertEqWith
      s
      "Showstopping Surprise's one atom is outside a wish's filter"
      (isBoundCounts (S.combinedFace surprise))
      (0, 1)
    Spec.assertBool s (sum (fmap (snd . isBoundCounts . S.combinedFace) ps) > 5) "and the pool gives the accepted side other atoms to be about"
    -- The rejected side, which the sweep above cannot show while the pool has no
    -- offender: the SAME atom, buried under all three combinators, in a wish's
    -- own filter -- so an implementation reading only the top of a Filter would
    -- accept it.
    let slot = SlotName.MkSlotName (Text.pack "target")
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Sorcery, Filter.Type.Not (Filter.Type.IsBound slot)]]
        spellOf effects =
          Mint.oneMode (Seq.fromList effects)
    piker <- S.printingOf s registry "Goblin Piker"
    let base = S.combinedFace piker
        wished = base {Face.spell = spellOf [Effect.FromOutsideTheGame (FromOutsideTheGame.MkFromOutsideTheGame 1 False OutsideDestination.Hand buried True)]}
    Spec.assertEqWith s "a planted atom in a wish's filter is an offence" (isBoundCounts wished) (1, 0)
    Spec.assertBool s (isBoundOffends wished) "and the lint says so"
    -- And the pair that differs in exactly one thing: the same face carrying the
    -- same filter in a position whose candidates ARE objects is accepted -- so the
    -- lint is reading the position rather than rejecting every planted atom.
    let destroying = base {Face.spell = spellOf [Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching buried) Regenerability.Regenerable Nothing Nothing Nothing)]}
    Spec.assertEqWith s "the same atom over objects is not" (isBoundCounts destroying) (0, 1)
    Spec.assertBool s (not (isBoundOffends destroying)) "and the lint accepts it"
    -- THE THIRD POSITION: a CR 118.12 gate's cost, measured and paid with the
    -- resolving object's slots (Cost.canPayReading, Cost.payReading), so the
    -- same buried atom is answerable there and accepted -- Calim, Djinn
    -- Emperor's "two other cards named Calim" is the printing.
    --
    -- Written as a gate over the SAME `base` face and the SAME `buried` filter as
    -- the two legs above, so the three differ in position and in nothing else.
    let gated =
          base
            { Face.spell =
                Mint.oneModeOf
                  Map.empty
                  ( Seq.singleton
                      ( Clause.MkClause
                          Nothing
                          Nothing
                          Nothing
                          Optionality.Mandatory
                          ( Just
                              PayGate.MkPayGate
                                { PayGate.payer = PlayerRef.Relative PlayerRelation.You,
                                  PayGate.cost = CostChoice.MkCostChoice (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) buried)] NonEmpty.:| []),
                                  PayGate.basis = Nothing,
                                  PayGate.branch = PayBranch.IfNotPaid,
                                  PayGate.obligation = PayObligation.Optional,
                                  PayGate.perEach = Nothing,
                                  PayGate.x = Nothing,
                                  PayGate.offeredAt = Nothing
                                }
                          )
                          (Seq.singleton (Effect.Sacrifice SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.InSlot slot, SacrificeEffect.sacrificer = Sacrificer.EffectController, SacrificeEffect.sacrificed = Nothing}))
                      )
                  )
            }
    Spec.assertEqWith s "CR 118.12 the same atom in a gate's cost is not an offence" (isBoundCounts gated) (0, 1)
    Spec.assertBool s (not (isBoundOffends gated)) "and the lint accepts it"
    -- THE OTHER COST POSITIONS, every one paid through the same
    -- Parun.Engine.Cost.pay, split by whether an announcement is behind them.
    -- Built over the SAME `base` face and the SAME `buried` filter as every leg
    -- above, so they differ from the accepted leg in position and in nothing
    -- else.
    let sacrificing = [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) buried)]
        sacrificeCost = Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) sacrificing
        -- CR 601.2f, paid as the cast is announced -- after CR 601.2c.
        added = base {Face.additionalCosts = sacrificing}
        -- CR 118.9, the cost half only -- the CR 604.2 condition an alternative
        -- may carry is a separate question and is not tagged with it.
        alternatively = base {Face.alternativeCosts = [AlternativeCost.MkAlternativeCost Nothing sacrificeCost]}
        -- CR 602.2b, paid as the ability is activated -- after CR 601.2c too.
        activating = base {Face.activatedAbilities = [ActivatedAbility.MkActivatedAbility sacrificeCost [] 0 Nothing (spellOf []) [] Activator.Controller Nothing Nothing Nothing]}
        -- CR 116.2d: a special action uses no stack (CR 116.1), so no
        -- announcement could answer in any engine.
        ignoring = base {Face.specialActions = [SpecialAction.IgnoreThisUntilEndOfTurn (AbilityName.MkAbilityName (Text.pack "the prohibition")) sacrificeCost]}
        -- CR 116.2c: the same special action, as the price of ending an effect.
        ending = base {Face.spell = spellOf [Effect.AffectPlayers (AffectPlayers.MkAffectPlayers (Duration.UntilPaid sacrificeCost) (AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.You)) PlayerEffect.CantCastSpells)]}
        -- CR 508.1h and CR 509.1d: a declaration announces no target.
        attacking = base {Face.attackCosts = [AttackCost.MkAttackCost (Affected.Matching (Filter.Type.HasCardType CardType.Creature)) (PerCreature.Fixed sacrificeCost) AttackCostScope.Controller]}
        blocking = base {Face.blockCosts = [BlockCost.MkBlockCost (Affected.Matching (Filter.Type.HasCardType CardType.Creature)) (PerCreature.Fixed sacrificeCost) Nothing]}
    -- Ordered FIRST: the positions an announcement pays are accepted, which is
    -- what #2924 changed -- Parun.Engine.Cost.pay reads CR 601.2c's targets off
    -- the stack object, so the atom is answered there.
    Spec.assertEqWith
      s
      "CR 601.2f / 118.9 / 602.2b a planted atom in a cost an announcement pays is answered"
      (fmap isBoundCounts [added, alternatively, activating])
      [(0, 1), (0, 1), (0, 1)]
    Spec.assertBool s (not (any isBoundOffends [added, alternatively, activating])) "and the lint accepts all three"
    Spec.assertEqWith
      s
      "CR 116.2d / 116.2c / 508.1h / 509.1d a planted atom in a cost nothing announces is an offence"
      (fmap isBoundCounts [ignoring, ending, attacking, blocking])
      [(1, 0), (1, 0), (1, 0), (1, 0)]
    Spec.assertBool s (all isBoundOffends [ignoring, ending, attacking, blocking]) "and the lint says so at all four"
  -- CR 702 / CR 122.1b: a keyword's own Filter is read off a continuous effect or
  -- off the printed face, through Parun.Engine.Filter.contextFor, which fills
  -- neither the resolution's slots nor the source's host. keywordFilters tags it
  -- KeywordFramed at the LEAF that produces it rather than at the position that
  -- quotes it, so a quoting position's promise is not inherited by the keyword's
  -- text -- which matters because counterKindFilters is reached from positions
  -- that promise more than a keyword can keep: a CR 614.1 replacement ROW, whose
  -- `hostFramed` is True, and a MODE's target-slot amount, which is InTargetSlot.
  Spec.it s "CR 702 a keyword's own filter is framed by the keyword and not by whatever quotes it" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let base = S.combinedFace piker
        slot = SlotName.MkSlotName (Text.pack "target")
        creatures = Filter.Type.HasCardType CardType.Creature
        -- Buried under all three combinators at every plant, so a lint reading
        -- only the top of a Filter would miss each one.
        bury atom = Filter.Type.And [Filter.Type.Or [creatures, Filter.Type.Not atom]]
        boundAtom = bury (Filter.Type.IsBound slot)
        hostAtom = bury Filter.Type.IsHostOfSource
        nameAtom = bury (Filter.Type.Shares Trait.Name (Anchor.Bound slot))
        keywordOf f = Keyword.Hexproof (Just f)
        kindOf f = CounterKind.Keyword (keywordOf f)
        plain = CounterKind.PlusOnePlusOne
        prohibiting kind = [CounterRestriction.MkCounterRestriction (Affected.Matching creatures) (Just kind)]
        granting keyword =
          [ StaticAbility.MkStaticAbility
              (Affected.Matching creatures)
              Nothing
              Set.empty
              Nothing
              Nothing
              (NonEmpty.singleton (Modification.GainKeyword keyword))
          ]
        scaling kind onWhat =
          [ PrintedReplacement.MkPrintedReplacement
              Nothing
              (ReplacementEffect.CounterR (CounterR.MkCounterR (CounterPattern.MkCounterPattern (Just kind) CounterSubject.ByAnything (ControllerRelation.Related PlayerRelation.You) onWhat Nothing) (Scaling.AddMore 1)))
              Set.empty
              Nothing
          ]
        spellOf targetSlot =
          Mint.oneModeTargeting (Map.singleton slot targetSlot) Seq.empty
        counting kind f = spellOf (TargetSlot.withAmount (Quantity.Type.ObjectCounters kind) (TargetSlot.required Pool.Creatures f))
        -- CR 614.1c's own row, carrying the entry rewrite under test. Filter.IsSource
        -- is what every "[this permanent] enters ..." clause matches on.
        entering rewrite =
          [ PrintedReplacement.MkPrintedReplacement
              Nothing
              (ReplacementEffect.EntryR (EntryR.MkEntryR Filter.Type.IsSource rewrite))
              Set.empty
              Nothing
          ]
        -- CR 208.2b's option, distinct P/T so nothing here is a numeric
        -- coincidence, and the keyword is the only thing carrying a Filter.
        optionWith keywords = EntryOption.MkEntryOption 2 5 keywords Set.empty
    -- Ordered FIRST, and CR 115.10a's half of the claim: the atom whose offence
    -- is the mirror of the others' is rejected at all three sites a keyword's
    -- Filter is reached from. A site that lost the tag reddens under its own
    -- label rather than under a total.
    let sited =
          [ ("CR 702.11d's printed keyword", isBoundCounts (base {Face.keywords = Map.singleton (keywordOf boundAtom) 1})),
            ("CR 613's granted keyword", isBoundCounts (base {Face.staticAbilities = granting (keywordOf boundAtom)})),
            ("CR 122.1b's keyword counter", isBoundCounts (base {Face.counterRestrictions = prohibiting (kindOf boundAtom)})),
            -- CR 208.2b's as-enters options and CR 614.1c's outright grant, the
            -- three positions #3232 named: each carries a Set of whole Keywords,
            -- so each reaches a Filter the same way CR 707.9a's exception does.
            -- ONE option of the flip's two carries the atom, so the count is 1
            -- here as it is at every other site.
            ("CR 208.2b's as-enters option", isBoundCounts (base {Face.replacementEffects = entering (EntryRewrite.ChoiceOf [optionWith (Set.singleton (keywordOf boundAtom))])})),
            ("CR 705.2's flipped option", isBoundCounts (base {Face.replacementEffects = entering (EntryRewrite.ChoiceByCoinFlip EntryFlip.MkEntryFlip {EntryFlip.heads = optionWith (Set.singleton (keywordOf boundAtom)), EntryFlip.tails = optionWith Set.empty})})),
            ("CR 614.1c's granted keyword", isBoundCounts (base {Face.replacementEffects = entering (EntryRewrite.EntersWith (EntersWith.MkEntersWith Nothing (Set.singleton (keywordOf boundAtom)) Seq.empty))}))
          ]
    Spec.assertEqWith s "IsBound under a keyword is an offence at every site that reaches one" sited (fmap (fmap (const (1, 0))) sited)
    -- The pair that differs in exactly ONE thing: the same prohibition, the same
    -- buried atom, moved off the KIND and onto the affected set beside it -- an
    -- ordinary unframed position, where the resolution's slots are supplied and
    -- the atom is accepted. So the lint is reading the keyword and not rejecting
    -- every plant.
    let besideIt = base {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching boundAtom) (Just plain)]}
    Spec.assertEqWith s "the same atom beside the kind rather than under it is not" (isBoundCounts besideIt) (0, 1)
    Spec.assertBool s (not (isBoundOffends besideIt)) "and the lint accepts it"
    -- CR 303.4b, the first position #2733 named: a CR 614.1 replacement row's own
    -- Filters ARE read with the source's host supplied, and the keyword counter
    -- inside one is not.
    let rowKeyword = base {Face.replacementEffects = scaling (kindOf hostAtom) creatures}
        rowItself = base {Face.replacementEffects = scaling plain hostAtom}
    Spec.assertEqWith s "IsHostOfSource under a replacement row's keyword counter is an offence" (hostOfSourceCounts rowKeyword) (0, 1)
    Spec.assertBool s (hostOfSourceOffends rowKeyword) "and the lint says so"
    Spec.assertEqWith s "the same atom in the row's own pattern is not" (hostOfSourceCounts rowItself) (1, 0)
    Spec.assertBool s (not (hostOfSourceOffends rowItself)) "and the lint accepts it"
    -- CR 709.4a, the second: a MODE's target slot IS matched with the bound names
    -- supplied, and the keyword counter inside the slot's CR 202.3 amount is not.
    let amountKeyword = base {Face.spell = counting (kindOf nameAtom) Nothing}
        slotItself = base {Face.spell = counting plain (Just nameAtom)}
    Spec.assertEqWith s "Shares Name Bound under a slot amount's keyword counter is an offence" (boundNameCounts amountKeyword) (0, 1)
    Spec.assertBool s (boundNameOffends amountKeyword) "and the lint says so"
    Spec.assertEqWith s "the same atom in the slot's own filter is not" (boundNameCounts slotItself) (1, 0)
    Spec.assertBool s (not (boundNameOffends slotItself)) "and the lint accepts it"
    -- NOT vacuous: the codec sees exactly one atom in each of the six faces, so
    -- every pair above is a comparison against a real occurrence rather than
    -- against nothing -- and a (0, 0) from a traversal that stopped digging would
    -- fail the cross-check inside each lint rather than pass quietly.
    let encoded tag card = jsonAtoms tag (Codec.encode (Face.Codec.codec Card.codec) card)
        authored =
          [ ("IsBound beside the kind", encoded isBoundTag besideIt),
            ("IsHostOfSource under the row's keyword counter", encoded hostOfSourceTag rowKeyword),
            ("IsHostOfSource in the row's own pattern", encoded hostOfSourceTag rowItself),
            ("Shares Name Bound under the amount's keyword counter", boundNameAtoms (Codec.encode (Face.Codec.codec Card.codec) amountKeyword)),
            ("Shares Name Bound in the slot's own filter", boundNameAtoms (Codec.encode (Face.Codec.codec Card.codec) slotItself))
          ]
    Spec.assertEqWith s "each planted face encodes exactly one atom" authored (fmap (fmap (const 1)) authored)
  -- CR 122.1b lets a counter's KIND be a whole Keyword, and a keyword may carry a
  -- Filter of its own -- CR 702.11d's "hexproof from Goblins", CR 702.29e's
  -- typecycling predicate, the components of any Cost a keyword names. So every
  -- card-authored counter-kind position holds card text, and the traversals above
  -- have to walk it or the position lints read the wrong number.
  --
  -- What that costs, exactly: NOT silence. Every position lint above carries a
  -- codec cross-check -- "the traversal and the codec disagree" -- and a Filter
  -- the traversal cannot see makes both counts zero against a non-zero
  -- `jsonAtoms`, so the card was rejected all the same. What was wrong is the
  -- CLASSIFICATION: the offence reported was a blind spot in cardFilters rather
  -- than the atom's position, and an atom that was legitimately placed would have
  -- been rejected by the same arithmetic. #2728 records the enumeration; this is
  -- what holds it.
  --
  -- Proved position by position on the TRAVERSALS rather than on the offence
  -- boolean, which was True before this walk existed and is True after it.
  Spec.it s "CR 122.1b a Filter under a keyword counter is walked at every counter-kind position" $ do
    let -- Buried under all three combinators, so a walk reading only the top of a
        -- keyword's own Filter would miss it.
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not Filter.Type.CanAttachToSubject]]
        kind = CounterKind.Keyword (Keyword.Hexproof (Just buried))
        one = Quantity.Type.Literal 1
        slot = SlotName.MkSlotName (Text.pack "target")
        anywhere = ObjectRef.EachMatching (Filter.Type.HasCardType CardType.Creature)
        riders = EntryRiders.defaultValue {EntryRiders.counters = Map.singleton kind one}
        -- CR 118.12's gate, whose multiplier is a Quantity and so writes the kind
        -- as a NUMBER (rule 702.24a's own count); see #2876. Its cost is empty, so
        -- the row below reports the multiplier rather than a walk that found the
        -- cost's filters instead.
        gate =
          PayGate.MkPayGate
            { PayGate.payer = PlayerRef.Relative PlayerRelation.You,
              PayGate.cost = CostChoice.MkCostChoice (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) [] NonEmpty.:| []),
              PayGate.basis = Nothing,
              PayGate.branch = PayBranch.IfNotPaid,
              PayGate.obligation = PayObligation.Optional,
              PayGate.perEach = Just (Quantity.Type.ObjectCounters kind),
              PayGate.x = Nothing,
              PayGate.offeredAt = Nothing
            }
        -- The PAIR, not just the Filter: PR #2739's reader's test says a keyword's
        -- own Filter carries KeywordFramed out through every quoting position, and
        -- `frame` fills in only the ones still Unframed, so a position that
        -- overwrote the tag is an offence here exactly as a position that lost the
        -- Filter is. What reads that tag is framedSlotsReadSingly (#2741).
        holds :: [(Framing, Filter.Type.Filter Keyword.Keyword)] -> Bool
        holds = elem (KeywordFramed, buried)
        -- The same kind written as a NUMBER rather than as a kind: CR 122.1's
        -- per-object tally, which is what the three traversals below reach.
        counting = Condition.Type.Compares (Compares.MkCompares (Quantity.Type.ObjectCounters kind) Comparison.AtLeast one)
        topDepth = ObjectRef.TopOfLibrary (TopOfLibrary.MkTopOfLibrary (PlayerRef.Relative PlayerRelation.You) (Quantity.Type.ObjectCounters kind))
        -- Every position a card may write a CounterKind in, each named for the
        -- traversal that has to reach it. An arm that stops digging names itself.
        walked =
          [ ("EntryRiders' kinds", holds (riderFilters riders)),
            ("Effect.PutCounters' kind", holds (effectFilters (Effect.PutCounters (PutCounters.MkPutCounters kind one anywhere)))),
            ("Effect.RemoveCounters' kind", holds (effectFilters (Effect.RemoveCounters (RemoveCounters.MkRemoveCounters kind one slot Nothing)))),
            ("Effect.RemoveCountersAmong' kind", holds (effectFilters (Effect.RemoveCountersAmong (RemoveCountersAmong.MkRemoveCountersAmong (RemovalCount.Exactly one) anywhere (WhichCounters.OfKind kind) Nothing)))),
            ("Effect.MoveCounters' kinds", holds (effectFilters (Effect.MoveCounters (MoveCounters.MkMoveCounters anywhere (MovedKinds.Named kind one) Nothing anywhere)))),
            ("Effect.PutCountersFrom' kind", holds (effectFilters (Effect.PutCountersFrom (PutCountersFrom.MkPutCountersFrom slot (Just kind) anywhere)))),
            ("Quantity.ObjectCounters' kind", holds (quantityFilters (Quantity.Type.ObjectCounters kind))),
            ("CR 714.2b's threshold", holds (triggerConditionFilters (TriggerCondition.SelfCountersReached (SelfCountersReached.MkSelfCountersReached kind 2)))),
            ("CR 310.12b's last removal", holds (triggerConditionFilters (TriggerCondition.SelfLastCounterRemoved (SelfCountersRemoved.MkSelfCountersRemoved kind)))),
            ("its any-amount mirror", holds (triggerConditionFilters (TriggerCondition.SelfCountersRemoved (SelfCountersRemoved.MkSelfCountersRemoved kind)))),
            ("its per-counter reading", holds (triggerConditionFilters (TriggerCondition.SelfCounterRemoved (SelfCountersRemoved.MkSelfCountersRemoved kind)))),
            ("CR 603.2c's per-permanent placement", holds (triggerConditionFilters (TriggerCondition.PermanentGetsCounters (CounterPlacement.MkCounterPlacement kind (Filter.Type.HasCardType CardType.Creature))))),
            ("CR 603.2c's batch placement", holds (triggerConditionFilters (TriggerCondition.PermanentsGetCounters (CounterPlacement.MkCounterPlacement kind (Filter.Type.HasCardType CardType.Creature))))),
            ("CR 614.1's scaling pattern", holds (replacementEffectFilters (ReplacementEffect.CounterR (CounterR.MkCounterR (CounterPattern.MkCounterPattern (Just kind) CounterSubject.ByAnything (ControllerRelation.Related PlayerRelation.You) (Filter.Type.HasCardType CardType.Creature) Nothing) (Scaling.AddMore 1))))),
            ("CR 614.1c's as-enters sacrifice", holds (entryRewriteFilters (EntryRewrite.SacrificeAnyNumber (SacrificeAnyNumber.MkSacrificeAnyNumber (Filter.Type.HasCardType CardType.Creature) (Just kind) one)))),
            -- Its MULTIPLIER, a road of its own: the field is a Quantity, so the
            -- kind rides in a number here rather than in the row's own `kind`,
            -- which this case leaves empty to keep the two apart.
            ("CR 702.82a's per-sacrifice multiplier", holds (entryRewriteFilters (EntryRewrite.SacrificeAnyNumber (SacrificeAnyNumber.MkSacrificeAnyNumber (Filter.Type.HasCardType CardType.Creature) Nothing (Quantity.Type.ObjectCounters kind))))),
            ("CR 614.1c's as-enters counters", holds (entryRewriteFilters (EntryRewrite.WithCounters (WithCounters.one kind one)))),
            ("CR 614.1e's turn-up counters", holds (turnUpRewriteFilters (TurnUpRewrite.WithCounters (WithCounters.one kind one)))),
            -- The four roads a card writes the kind inside a NUMBER instead, each
            -- reaching a Quantity by its own traversal (#2740). Reading a
            -- Condition's, a Duration's, an ObjectRef's or a CR 118.12 gate's
            -- Counts alone answers [] here, since quantityCounts has no Count to
            -- hand back for an ObjectCounters.
            ("a Condition's own number", holds (conditionFilters counting)),
            ("CR 611.2b's for-as-long-as clause", holds (durationFilters (Duration.ForAsLongAs counting))),
            ("a library depth", holds (objectRefFilters topDepth)),
            ("its reveal-until mirror", holds (objectRefFilters (ObjectRef.TopOfLibraryUntil (TopOfLibraryUntil.MkTopOfLibraryUntil (PlayerRef.Relative PlayerRelation.You) (Filter.Type.HasCardType CardType.Land) (Quantity.Type.ObjectCounters kind))))),
            -- The fourth: the gate is a clause's FIELD rather than an effect, so
            -- payGateFilters is the only traversal that reaches it (#2876).
            ("CR 118.12's gate multiplier", holds (payGateFilters gate)),
            -- And the same three as cardFilters actually reaches them, one opcode
            -- or trigger condition deep, so the tagging survives the quoting
            -- position rather than only the leaf.
            ("CR 603.8's state trigger", holds (triggerConditionFilters (TriggerCondition.StateIs counting))),
            ("a stored duration's clause", holds (effectFilters (Effect.GainControl (GainControl.MkGainControl (Duration.ForAsLongAs counting) anywhere (PlayerRef.Relative PlayerRelation.You))))),
            ("a depth under an opcode", holds (effectFilters (Effect.Tap (Tap.plain topDepth))))
          ]
    -- Ordered FIRST, and the assertion this case exists for: every position digs
    -- the keyword's Filter out. A dropped arm reddens under its own label.
    Spec.assertEqWith s "every counter-kind position is walked" walked (fmap (fmap (const True)) walked)
    -- The pair that differs in exactly ONE thing: the same positions carrying a
    -- kind that is not a keyword hand back no Filter at all, so what the row above
    -- reports is the KIND's payload rather than a walk that returns everything.
    let plain = CounterKind.PlusOnePlusOne
    Spec.assertEqWith
      s
      "a kind carrying no keyword contributes nothing"
      ( counterKindFilters plain,
        effectFilters (Effect.RemoveCounters (RemoveCounters.MkRemoveCounters plain one slot Nothing)),
        quantityFilters (Quantity.Type.ObjectCounters plain),
        triggerConditionFilters (TriggerCondition.SelfLastCounterRemoved (SelfCountersRemoved.MkSelfCountersRemoved plain))
      )
      ([], [], [], [])
    -- The same pair over the three number-shaped roads: a plain kind inside the
    -- tally hands back nothing, so what those rows report is the KIND's payload
    -- rather than a walk that returns the whole Quantity.
    let plainNumber = Condition.Type.Compares (Compares.MkCompares (Quantity.Type.ObjectCounters plain) Comparison.AtLeast one)
    Spec.assertEqWith
      s
      "a number naming a plain kind contributes nothing either"
      ( conditionFilters plainNumber,
        durationFilters (Duration.ForAsLongAs plainNumber),
        objectRefFilters (ObjectRef.TopOfLibrary (TopOfLibrary.MkTopOfLibrary (PlayerRef.Relative PlayerRelation.You) (Quantity.Type.ObjectCounters plain)))
      )
      ([], [], [])
    -- And the whole road, end to end, at the ONE position no traversal above
    -- reaches on its own: a CR 122.6 prohibition names its kind on the Face
    -- record, so cardFilters' own fold is what has to carry it. The atom is
    -- CanAttachToSubject, answerable only inside a search (CR 701.3a), so the
    -- counts say the traversal found it and filed it OUTSIDE one -- where before
    -- this walk both counts read zero and only the codec cross-check objected.
    piker <- S.printingOf s registry "Goblin Piker"
    let base = S.combinedFace piker
        prohibiting =
          base
            { Face.counterRestrictions =
                [CounterRestriction.MkCounterRestriction (Affected.Matching (Filter.Type.HasCardType CardType.Creature)) (Just kind)]
            }
    Spec.assertEqWith s "a prohibition's kind is counted outside a search" (canAttachToSubjectCounts prohibiting) (0, 1)
    -- NOT vacuous: the codec sees exactly one atom in that face, so the pair above
    -- is being compared against a real occurrence rather than against nothing.
    Spec.assertEqWith s "and the codec agrees there is one" (jsonAtoms canAttachToSubjectTag (Codec.encode (Face.Codec.codec Card.codec) prohibiting)) 1
    Spec.assertBool s (canAttachToSubjectOffends prohibiting) "and the lint says so"
    -- The pair that differs in one thing again: the same prohibition over a
    -- plain kind carries no atom, so the face is accepted.
    let plainly = base {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching (Filter.Type.HasCardType CardType.Creature)) (Just plain)]}
    Spec.assertEqWith s "a prohibition naming a plain kind carries none" (canAttachToSubjectCounts plainly) (0, 0)
    Spec.assertBool s (not (canAttachToSubjectOffends plainly)) "and the lint accepts it"
    -- The gate's OTHER position, end to end over a printing rather than a
    -- fixture: Lithophage's "unless you sacrifice a Mountain" writes card text
    -- into PayGate.cost, and it is far from the only printing that does. That
    -- half was unswept before #2876 for the same reason the kind was, and a
    -- corpus card is the evidence a hand-built mode would not be.
    lithophage <- S.printingOf s registry "Lithophage"
    Spec.assertBool
      s
      (elem (Unframed, Filter.Type.HasSubtype Subtype.Mountain) (cardFilters (S.combinedFace lithophage)))
      "CR 118.12 a gate cost's own filter reaches cardFilters, tagged for the resolution's slots it reads"
  -- The batch-bound slot lint used to answer two ways about one piece of text.
  -- filterSlotsReadSingly deliberately does not descend into Filter.HasKeyword or
  -- Filter.HasCounters -- a keyword's own Filter is read through
  -- Parun.Engine.Filter.contextFor, which fills no slot map -- but the sweep that
  -- folds it over a card's Filters dropped the tag first, so the same keyword
  -- filter arriving as a top-level KeywordFramed pair from counterKindFilters was
  -- walked after all. framedSlotsReadSingly is the one funnel now (#2741).
  Spec.it s "CR 122.1b a keyword's own Filter reads no slot on either route" $ do
    let bound = SlotName.MkSlotName (Text.pack "bound")
        -- The ONE arm of filterSlotsReadSingly that answers with a slot, so a
        -- route that swept the keyword's Filter is visible and no other atom is
        -- on trial.
        atom = Filter.Type.IsControllerOfBound bound
        kind = CounterKind.Keyword (Keyword.Hexproof (Just atom))
        one = Quantity.Type.Literal 1
        anywhere = ObjectRef.EachMatching (Filter.Type.HasCardType CardType.Creature)
        -- NESTED: the atom reached by descending an ordinary Filter, which the
        -- walk stops at.
        nested = filterSlotsReadSingly (Filter.Type.HasCounters kind)
        -- TOP-LEVEL: the same keyword, the same atom, handed back by
        -- counterKindFilters as its own (KeywordFramed, f) pair -- the route that
        -- used to disagree.
        topLevel = concatMap framedSlotsReadSingly (effectFilters (Effect.PutCounters (PutCounters.MkPutCounters kind one anywhere)))
    -- Ordered FIRST, and the assertion this case exists for.
    Spec.assertEqWith s "both routes to a keyword's own Filter read no slot" (nested, topLevel) ([], [])
    -- NOT vacuous, and the pair differing in exactly ONE thing: the same atom in
    -- the same card's text at a position that is not a keyword's own IS reported,
    -- so what the pair above says is that the FRAMING silences it rather than that
    -- the walk answers nothing anywhere.
    Spec.assertEqWith
      s
      "the same atom outside a keyword is read singly"
      (concatMap framedSlotsReadSingly (effectFilters (Effect.Tap (Tap.plain (ObjectRef.EachMatching atom)))))
      [bound]
    -- One row per Framing constructor, off [minBound .. maxBound] rather than a
    -- hand-kept list: a constructor added to that type lengthens the left side and
    -- reddens here rather than picking up whichever answer the new position
    -- happens to inherit.
    Spec.assertEqWith
      s
      "every framing's answer, one row per constructor"
      (fmap (\framing -> (framing, framedSlotsReadSingly (framing, atom))) [minBound .. maxBound])
      [ (Unframed, [bound]),
        (AttachDestination, [bound]),
        (EntryAttachDestination, [bound]),
        (InTargetSlot, [bound]),
        (SourceHostFramed, [bound]),
        (StandingHostFramed, [bound]),
        (PlayerEffectFramed, [bound]),
        (StoredPlayerEffectFramed, [bound]),
        (SearchFramed, [bound]),
        (ReplacementRowFramed, [bound]),
        (OutsideTheGameFramed, [bound]),
        (KeywordFramed, []),
        (SlotlessCostFramed, [bound]),
        (MintedTargetSlot, [bound]),
        (MillTallyFramed, [bound]),
        (HandSweepFramed, [bound]),
        (ClauseGateFramed, [bound]),
        (LifeLossAmountFramed, [bound]),
        (AffectedSetFramed, [bound]),
        (ActivationCostFramed, [bound]),
        (ManaRestrictionFramed, [bound]),
        (TriggerConditionFramed, [bound]),
        (StoredClassFramed, [bound]),
        (ChosenSourceFramed, [bound])
      ]
  -- A comparison against the SOURCE's measures, names (CR 702.60a's ripple) or
  -- colours (CR 702.78a's conspire) is answerable only where the CONTEXT
  -- supplies them: Parun.Engine.Projection.withCharacteristicsOf fills all three
  -- together, for every context Projection.sourceContext frames and for CR
  -- 509.1b's pairwise walks, and they are empty inside the CR 613 layer fold and
  -- in a bare Filter.contextFor -- so the atom in a card's affected set or static
  -- condition would be a silent False. Outside a face's own pairwise position
  -- (Spitfire Handler's, Ironclaw Curse's, Okk's company), a wish's filter (Synthetic Wishful
  -- Djinn's), a triggered ability's own condition (Kami of Mourning's) and a
  -- target slot's filter (Stone Giant's, which Parun.Engine.Target.slotContext
  -- frames through Projection.framedWith), only
  -- Parun.Engine.Keyword's keywords and Parun.Engine.Ring's emblem write them, and
  -- this is what keeps that true.
  Spec.it s "CR 702.134a / 702.60a / 702.78a no card compares against the source outside the positions that fill it" $ do
    ps <- S.allPrintings s corpus
    let ofSource = Value.String (String.MkString (Text.pack "OfSource"))
        needles = ofSource : fmap (\trait -> atomJson (Filter.Type.Shares trait Anchor.Source)) [Trait.Name, Trait.Color, Trait.Sector]
        encoded = Codec.encode (Face.Codec.codec Card.codec)
        pairwise needle c = sum (fmap (occurrences needle . atomJson) (concatMap pairwiseFilters (Face.combatRestrictions c))) + evasionBlockerAtoms needle (encoded c)
        pairwiseFilters r = case r of
          CombatRestriction.CantBeBlockedBy x -> [CantBeBlockedBy.blockers x]
          CombatRestriction.CantBlockCreatures x -> [CantBlockCreatures.attackers x]
          CombatRestriction.CantAttackAlone x -> Maybe.maybeToList (AloneUnless.alongside x)
          CombatRestriction.CantBlockAlone x -> Maybe.maybeToList (AloneUnless.alongside x)
          _ -> []
        inSlots needle c = sum [occurrences needle (atomJson f) | (InTargetSlot, f) <- cardFilters c]
        admitted needle c = (pairwise needle c, wishFilterAtoms needle (encoded c), triggerConditionAtoms needle (encoded c), inSlots needle c)
        outside needle c = let (p, w, t, i) = admitted needle c in occurrences needle (encoded c) - p - w - t - i
        offenders = [(needle, S.nameOf (Printing.card p)) | needle <- needles, p <- ps, anyFace (\c -> outside needle c /= 0) (Printing.card p)]
    Spec.assertEqWith s "the atoms are written only where the source is filled" offenders []
    -- NOT vacuous: each admitted position has its author, and each is accepted.
    djinn <- S.printingOf s registry "Synthetic Wishful Djinn"
    kami <- S.printingOf s registry "Kami of Mourning"
    spitfire <- S.printingOf s registry "Spitfire Handler"
    giant <- S.printingOf s registry "Stone Giant"
    Spec.assertEqWith
      s
      "the Djinn's is in a wish, the Kami's in a trigger condition, the Handler's pairwise, the Giant's in a target slot"
      (fmap (\p -> (admitted ofSource (S.combinedFace p), outside ofSource (S.combinedFace p))) [djinn, kami, spitfire, giant])
      [((0, 1, 0, 0), 0), ((0, 0, 1, 0), 0), ((1, 0, 0, 0), 0), ((0, 0, 0, 1), 0)]
    -- The resolved row's blocker filter is pairwise too, and Space Beleren's +1
    -- writes one there.
    beleren <- S.printingOf s registry "Space Beleren"
    let sameSector = atomJson (Filter.Type.Shares Trait.Sector Anchor.Source)
    Spec.assertEqWith s "Space Beleren's is in a resolved evasion's blocker filter" (admitted sameSector (S.combinedFace beleren), outside sameSector (S.combinedFace beleren)) ((1, 0, 0, 0), 0)
    -- NOT vacuous the other way either: the same counter over a hand-built face
    -- that DOES carry each atom -- buried under all three combinators, in a
    -- static ability's affected set, whose Projection.affectedContext fills no
    -- characteristics -- finds it. An effect's ObjectRef would answer
    -- (Resolve.Slots.effectContext frames it through Projection.framedWith), but
    -- no card writes one there, so the lint refuses it in the safe direction.
    piker <- S.printingOf s registry "Goblin Piker"
    let atoms = [Filter.Type.Measures (Measures.MkMeasures Measure.Power Comparison.LessThan (Operand.OfSource Measure.Power)), Filter.Type.Shares Trait.Name Anchor.Source, Filter.Type.Shares Trait.Color Anchor.Source, Filter.Type.Shares Trait.Sector Anchor.Source]
        planted atom =
          (S.combinedFace piker)
            { Face.staticAbilities =
                [ StaticAbility.MkStaticAbility
                    (Affected.Matching (Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]))
                    Nothing
                    Set.empty
                    Nothing
                    Nothing
                    (NonEmpty.singleton Modification.LoseAllAbilities)
                ]
            }
    Spec.assertEqWith s "a planted atom is seen" (zipWith (\needle atom -> outside needle (planted atom)) needles atoms) [1, 1, 1, 1]
  -- CR 702.140a's comparison is the source-comparison atom's owner trait, and
  -- its one filler is Parun.Engine.Target.slotContext -- so it is answerable
  -- only inside a TARGET SLOT's own filter and would be a silent False in an
  -- affected set, a Count filter, a cost criterion or a search filter. Only
  -- Parun.Engine.Keyword writes it -- mutate -- and into a slot the rule MINTS
  -- rather than one a card authors, so what is swept here is every card filter
  -- alike.
  Spec.it s "CR 702.140a no card writes a source-owner comparison" $ do
    ps <- S.allPrintings s corpus
    let atoms c = occurrences (atomJson (Filter.Type.Shares Trait.Owner Anchor.Source)) (Codec.encode (Face.Codec.codec Card.codec) c)
        offenders = filter (anyFace (\c -> atoms c /= 0) . Printing.card) ps
    Spec.assertEqWith s "the atom is the engine's alone" (fmap (S.nameOf . Printing.card) offenders) []
    -- NOT vacuous, the sweeps above's reason: the same counter over a hand-built
    -- face that DOES carry the atom finds it.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.Shares Trait.Owner Anchor.Source)]]
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just buried))) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is seen" (atoms planted) 1
  -- CR 508.5's atom is answerable only where the CONTEXT supplies a defending
  -- player, and exactly two callers fill Filter.Context.defendingPlayers:
  -- Parun.Engine.Target.admittedGiven for a target slot (CR 702.39a's provoke,
  -- Sensational Spider-Man, Yare) and Parun.Engine.CombatRestriction.inForce for a
  -- CR 508.1c gate (Armored Galleon). It is empty everywhere else, so the atom in
  -- any OTHER position -- a static ability's affected set, a search filter, a
  -- triggered ability's condition -- would be a silent False. This is the lint
  -- that keeps that true: what it sweeps is the atom outside a combat
  -- restriction, by re-encoding each face with its restrictions dropped, and
  -- outside a mode's target slot, by subtracting what cardFilters finds there.
  Spec.it s "CR 508.5 no card writes ControlledByRole Defending outside a combat restriction or a target slot" $ do
    ps <- S.allPrintings s corpus
    let needle = atomJson (Filter.Type.ControlledByRole TurnRole.Defending)
        atoms c = occurrences needle (Codec.encode (Face.Codec.codec Card.codec) c)
        inSlots c = sum [occurrences needle (atomJson f) | (InTargetSlot, f) <- cardFilters c]
        elsewhere c = atoms (c {Face.combatRestrictions = []}) - inSlots c
        offenders = filter (anyFace ((/= 0) . elsewhere) . Printing.card) ps
    Spec.assertEqWith s "the atom is the engine's alone outside a gate" (fmap (S.nameOf . Printing.card) offenders) []
    -- Three legs of anti-vacuity, because the narrowing above could hide a real
    -- offender by blinding the counter rather than by being true.
    --
    -- One: the pool DOES write the atom, in the position the narrowing accepts.
    -- Armored Galleon's CR 508.1c gate is the whole of its text, so the counter
    -- sees it and `elsewhere` does not.
    galleon <- S.printingOf s registry "Armored Galleon"
    Spec.assertEqWith s "the Galleon's gate carries the atom" (atoms (S.combinedFace galleon)) 1
    Spec.assertEqWith s "and nothing outside it does" (elsewhere (S.combinedFace galleon)) 0
    -- Two: the same counter over a hand-built face carrying the atom in a target
    -- slot finds it, and `elsewhere` does not -- the position Sensational
    -- Spider-Man writes it in.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.ControlledByRole TurnRole.Defending)]]
        targetSlot = TargetSlot.required Pool.Creatures (Just buried)
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) targetSlot) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is seen" (atoms planted) 1
    Spec.assertEqWith s "and in a target slot it is accepted" (elsewhere planted) 0
    -- Three: the same atom in a counter restriction's affected set is an
    -- offence, which is what says neither subtraction drops the rest of the face.
    let affected = (S.combinedFace piker) {Face.counterRestrictions = [CounterRestriction.MkCounterRestriction (Affected.Matching buried) Nothing]}
    Spec.assertEqWith s "and outside both positions it is still seen" (elsewhere affected) 1
  -- CR 603.2's baked half is in Modification.SetController's position rather
  -- than CR 702.39a's: a PlayerId that only a resolution can know, round-tripped
  -- by a total codec, so nothing but this keeps card JSON from naming a seat
  -- (#199). The UNBAKED atom beside it is card data and is not swept -- Trygon
  -- Predator writes it, and Parun.Engine.Resolve.Slots.modeSlots is what checks the slot
  -- it names is one the ability's condition binds.
  Spec.it s "CR 603.2 no card writes HeldByPlayer" $ do
    ps <- S.allPrintings s corpus
    let atoms c = jsonAtoms (Text.pack "HeldByPlayer") (Codec.encode (Face.Codec.codec Card.codec) c)
        offenders = filter (anyFace ((/= 0) . atoms) . Printing.card) ps
    Spec.assertEqWith s "the baked atom is the engine's alone" (fmap (S.nameOf . Printing.card) offenders) []
    -- Not vacuous, for the sibling sweep's reason: the same counter over a
    -- hand-built face carrying the atom in a target slot finds it.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.HeldByPlayer Holder.Controller (PlayerId.MkPlayerId 1))]]
        targetSlot = TargetSlot.required Pool.Creatures (Just buried)
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) targetSlot) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is seen" (atoms planted) 1
    let owned = (S.combinedFace piker) {Face.spell = Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just (Filter.Type.HeldByPlayer Holder.Owner (PlayerId.MkPlayerId 1))))) Seq.empty}
    Spec.assertEqWith s "and its owner holder" (atoms owned) 1
  -- CR 601.2c's baked "that player's graveyard", for HeldByPlayer's reason:
  -- Parun.Engine.Target.bakePerPlayer writes it, and no card may name a seat.
  Spec.it s "CR 601.2c no card writes ZoneScope.BoundPlayer" $ do
    ps <- S.allPrintings s corpus
    let atoms c = jsonAtoms (Text.pack "BoundPlayer") (Codec.encode (Face.Codec.codec Card.codec) c)
        offenders = filter (anyFace ((/= 0) . atoms) . Printing.card) ps
    Spec.assertEqWith s "the baked scope is the engine's alone" (fmap (S.nameOf . Printing.card) offenders) []
    piker <- S.printingOf s registry "Goblin Piker"
    let targetSlot = TargetSlot.required (Pool.CardsInGraveyard (ZoneScope.BoundPlayer (PlayerId.MkPlayerId 1))) Nothing
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) targetSlot) Seq.empty
            }
    Spec.assertEqWith s "a planted scope is seen" (atoms planted) 1
  -- CR 702.119c's baked half, in the position the atom above holds: an ObjectId
  -- that only a cast can know, written by Parun.Engine.Cost.candidateCostsGiven
  -- into an emerge candidate's sacrifice criterion and round-tripped by a total
  -- codec, so nothing but this keeps card JSON from naming an object.
  Spec.it s "CR 702.119c no card writes IsObject" $ do
    ps <- S.allPrintings s corpus
    let atoms c = jsonAtoms (Text.pack "IsObject") (Codec.encode (Face.Codec.codec Card.codec) c)
        offenders = filter (anyFace ((/= 0) . atoms) . Printing.card) ps
    Spec.assertEqWith s "the baked atom is the engine's alone" (fmap (S.nameOf . Printing.card) offenders) []
    -- Not vacuous, for the sibling sweep's reason.
    piker <- S.printingOf s registry "Goblin Piker"
    let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not (Filter.Type.IsObject (ObjectId.MkObjectId 1))]]
        targetSlot = TargetSlot.required Pool.Creatures (Just buried)
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) targetSlot) Seq.empty
            }
    Spec.assertEqWith s "a planted atom is seen" (atoms planted) 1
  -- CR 611.2b's baked half, in exactly the position the atom above holds: a
  -- PlayerId only a resolution can know, written by Parun.Engine.Condition.bakeBound
  -- as a "for as long as" duration begins and round-tripped by a total codec
  -- (Parun.Codec.Expiry serialises a whole stored condition), so nothing but this
  -- keeps card JSON from naming a seat. The UNBAKED PlayerRef.InSlot beside it is
  -- card data -- Garland, Royal Kidnapper writes it -- and is not swept.
  -- HolderOfObject is the same baked half for an object slot, and swept beside it.
  Spec.it s "CR 611.2b no card writes a Specific PlayerRef" $ do
    ps <- S.allPrintings s corpus
    let atoms c = sum (fmap (\tag -> jsonAtoms (Text.pack tag) (Codec.encode (Face.Codec.codec Card.codec) c)) ["Specific", "HolderOfObject"])
        offenders = filter (anyFace ((/= 0) . atoms) . Printing.card) ps
    Spec.assertEqWith s "the baked reference is the engine's alone" (fmap (S.nameOf . Printing.card) offenders) []
    -- Not vacuous, for the sibling sweeps' reason: the same counter over a
    -- hand-built face carrying the reference inside a duration's condition finds
    -- it.
    piker <- S.printingOf s registry "Goblin Piker"
    let crowned =
          Condition.Type.Compares
            ( Compares.MkCompares
                (Quantity.Type.IsMonarch (PlayerRef.Specific (PlayerId.MkPlayerId 1)))
                Comparison.AtLeast
                (Quantity.Type.Literal 1)
            )
        planted =
          (S.combinedFace piker)
            { Face.spell =
                Mint.oneModeTargeting (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures Nothing)) (Seq.singleton (Effect.GainControl (GainControl.MkGainControl (Duration.ForAsLongAs crowned) (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) (PlayerRef.Relative PlayerRelation.You))))
            }
    Spec.assertEqWith s "a planted reference is seen" (atoms planted) 1
  -- The sweep above passes VACUOUSLY for every card but Aura Graft, and Aura
  -- Graft only exercises the ACCEPTING direction, so the rejecting direction is
  -- proven here instead -- hand-built, never a card file, because a card that
  -- offends a lint must not be loadable.
  --
  -- Every fixture plants the atom BURIED under all three combinators rather than
  -- bare, so an implementation that looked only at the top of a Filter would
  -- accept every one of them. And each is asserted through canHostSubjectCounts
  -- as well as through the predicate: the counts say the TRAVERSAL found it in
  -- that position, where the predicate alone would also be satisfied by the codec
  -- half of the cross-check noticing an atom the traversal missed entirely.
  Spec.it s "the lint itself catches CanHostSubject outside an attach's destination" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    sorcerer <- S.printingOf s registry "Prodigal Sorcerer"
    graft <- S.printingOf s registry "Aura Graft"
    let base = S.combinedFace piker
        slot = SlotName.MkSlotName (Text.pack "target")
        atom = Filter.Type.CanHostSubject
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]
        -- A one-mode, one-clause, mandatory spell running these effects and
        -- declaring these slots -- the smallest carrier that reaches a mode's
        -- clauses and its targetSlots at once.
        spellOf effects slots =
          Mint.oneModeTargeting slots (Seq.fromList effects)
        boostedBy quantity =
          StaticAbility.MkStaticAbility
            (Affected.Matching Filter.Type.IsSource)
            Nothing
            Set.empty
            Nothing
            Nothing
            (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness quantity (Quantity.Type.Literal 0))))
        planted =
          [ ( "a target slot",
              base {Face.spell = spellOf [] (Map.singleton slot (TargetSlot.required Pool.Permanents (Just buried)))}
            ),
            ( "CR 303.4a's enchant ability",
              base {Face.enchant = [TargetSlot.required Pool.Permanents (Just buried)]}
            ),
            ( "a static ability's affected set",
              base
                { Face.staticAbilities =
                    [ StaticAbility.MkStaticAbility
                        (Affected.Matching buried)
                        Nothing
                        Set.empty
                        Nothing
                        Nothing
                        (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Type.Literal 1) (Quantity.Type.Literal 1))))
                    ]
                }
            ),
            ( "a Count's filter",
              base
                { Face.staticAbilities =
                    [ boostedBy
                        ( Quantity.Type.Count
                            (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                        )
                    ]
                }
            ),
            ( "a Search filter",
              base {Face.spell = spellOf [Effect.Search Search.MkSearch {Search.searcher = PlayerRef.Relative PlayerRelation.You, Search.owner = PlayerRef.Relative PlayerRelation.You, Search.zones = Set.singleton Zone.Library, Search.outsideTheGame = False, Search.quantity = Just (Quantity.Type.Literal 1), Search.filter = buried, Search.upTo = False, Search.destination = SearchDestination.RevealThenHand, Search.subject = Nothing, Search.slot = Nothing, Search.differentIn = Set.empty, Search.exactly = False, Search.andOr = False}] Map.empty}
            ),
            ( "an ObjectRef.EachMatching set",
              base {Face.spell = spellOf [Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching buried) Regenerability.Regenerable Nothing Nothing Nothing)] Map.empty}
            ),
            ( "CR 603.6a's trigger condition",
              base
                { Face.triggeredAbilities =
                    [ oneEffectTrigger
                        (TriggerCondition.PermanentEnters buried)
                        (Effect.Draw (Draw.MkDraw (PlayerRef.InSlot Binding.you) (Quantity.Type.Literal 1) Nothing))
                    ]
                }
            ),
            ( "CR 601.2f's sacrifice cost component",
              (S.combinedFace sorcerer)
                { Face.activatedAbilities =
                    fmap
                      (\a -> a {ActivatedAbility.cost = (ActivatedAbility.cost a) {Cost.Type.components = [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) buried)]}})
                      (Face.activatedAbilities (S.combinedFace sorcerer))
                }
            ),
            ( "CR 702.29e's typecycling predicate",
              base {Face.keywords = Map.singleton (Keyword.Cycling (Cycling.MkCycling (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) []) (Just buried))) 1}
            ),
            ( "CR 613.11's spell-cost modifier",
              base
                { Face.playerAbilities =
                    [PlayerStaticAbility.MkPlayerStaticAbility {PlayerStaticAbility.scope = PlayerScope.Related PlayerRelation.You, PlayerStaticAbility.condition = Nothing, PlayerStaticAbility.name = Nothing, PlayerStaticAbility.effect = PlayerEffect.ModifyCost (CostModifier.MkCostModifier CostSubject.Spells buried Nothing Nothing Nothing Nothing (CostChange.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 1])))}]
                }
            ),
            ( "CR 508.1c's combat restriction",
              base {Face.combatRestrictions = [CombatRestriction.CantAttack (AffectedUnless.MkAffectedUnless (Affected.Matching buried) Nothing Nothing Nothing)]}
            ),
            ( "CR 508.1h's cost to attack",
              base {Face.attackCosts = [AttackCost.MkAttackCost (Affected.Matching buried) (PerCreature.Fixed (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) [])) AttackCostScope.Controller]}
            ),
            ( "CR 508.1h's counted share",
              base
                { Face.attackCosts =
                    [ AttackCost.MkAttackCost
                        (Affected.Matching (Filter.Type.HasCardType CardType.Creature))
                        ( PerCreature.Counted
                            ( Quantity.Type.Count
                                (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                            )
                        )
                        AttackCostScope.Controller
                    ]
                }
            ),
            ( "CR 509.1d's cost to block",
              base {Face.blockCosts = [BlockCost.MkBlockCost (Affected.Matching buried) (PerCreature.Fixed (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) [])) Nothing]}
            ),
            ( "CR 509.1b's block-cost attacker filter",
              base {Face.blockCosts = [BlockCost.MkBlockCost (Affected.Matching Filter.Type.IsSource) (PerCreature.Fixed (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) [])) (Just buried)]}
            ),
            ( "CR 509.1d's counted share",
              base
                { Face.blockCosts =
                    [ BlockCost.MkBlockCost
                        (Affected.Matching (Filter.Type.HasCardType CardType.Creature))
                        ( PerCreature.Counted
                            ( Quantity.Type.Count
                                (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                            )
                        )
                        Nothing
                    ]
                }
            ),
            ( "CR 614.1's counter-placement pattern",
              base
                { Face.replacementEffects =
                    [ PrintedReplacement.MkPrintedReplacement
                        Nothing
                        (ReplacementEffect.CounterR (CounterR.MkCounterR (CounterPattern.MkCounterPattern Nothing CounterSubject.ByAnything (ControllerRelation.Related PlayerRelation.You) buried Nothing) (Scaling.AddMore 1)))
                        Set.empty
                        Nothing
                    ]
                }
            ),
            ( "CR 604.2's clause gating a printed replacement ability",
              base
                { Face.replacementEffects =
                    [ PrintedReplacement.MkPrintedReplacement
                        ( Just
                            ( Condition.Type.Compares
                                ( Compares.MkCompares
                                    ( Quantity.Type.Count
                                        (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                                    )
                                    Comparison.AtLeast
                                    (Quantity.Type.Literal 1)
                                )
                            )
                        )
                        (ReplacementEffect.DestructionR (DestructionR.MkDestructionR Nothing DestructionRewrite.Regenerate))
                        Set.empty
                        Nothing
                    ]
                }
            ),
            ( "a created token's own static ability",
              base
                { Face.spell =
                    spellOf
                      [ Effect.Create
                          Create.MkCreate
                            { Create.quantity = Quantity.Type.Literal 1,
                              Create.card = oneFaced (base {Face.staticAbilities = [StaticAbility.MkStaticAbility (Affected.Matching buried) Nothing Set.empty Nothing Nothing (NonEmpty.singleton Modification.LoseAllAbilities)]}),
                              Create.riders = EntryRiders.defaultValue,
                              Create.slot = Nothing,
                              Create.creator = PlayerRef.Relative PlayerRelation.You
                            }
                      ]
                      Map.empty
                }
            ),
            ( "CR 103.5b's pregame action",
              base {Face.mulliganActions = [HandAction.MkHandAction Nothing [Effect.Search Search.MkSearch {Search.searcher = PlayerRef.Relative PlayerRelation.You, Search.owner = PlayerRef.Relative PlayerRelation.You, Search.zones = Set.singleton Zone.Library, Search.outsideTheGame = False, Search.quantity = Just (Quantity.Type.Literal 1), Search.filter = buried, Search.upTo = False, Search.destination = SearchDestination.RevealThenHand, Search.subject = Nothing, Search.slot = Nothing, Search.differentIn = Set.empty, Search.exactly = False, Search.andOr = False}]]}
            )
          ]
        report (label, card) = (label, canHostSubjectOffends card, canHostSubjectCounts card)
    Spec.assertEqWith
      s
      "every unframed position is rejected, and the traversal is what finds it"
      (fmap report planted)
      (fmap (\(label, _) -> (label, True, (0, 1))) planted)
    -- The cross-check agrees on every fixture, which is what says it reports a
    -- blind spot rather than firing on cards that have none.
    Spec.assertEqWith
      s
      "and the codec counts exactly the atoms the traversal does"
      (fmap (\(_, card) -> jsonAtoms (Text.pack "CanHostSubject") (Codec.encode (Face.Codec.codec Card.codec) card)) planted)
      (fmap (const 1) planted)
    -- The nesting, stated on its own: a top-level-only check would score every
    -- one of these zero but the first.
    Spec.assertEqWith
      s
      "the atom is found at every nesting depth"
      ( fmap
          canHostSubjects
          [ atom,
            Filter.Type.And [atom],
            Filter.Type.Or [atom],
            Filter.Type.Not atom,
            buried,
            Filter.Type.HasKeyword (Keyword.Cycling (Cycling.MkCycling (Cost.Type.MkCost Nothing []) (Just atom))),
            -- CR 303.4's attachment atom, which carries the HOST's description and
            -- is therefore a Filter position like the combinators above. No card
            -- nests this atom there -- it would be nonsense text -- so this is the
            -- only observer that descent has.
            Filter.Type.AttachedTo atom
          ]
      )
      [1, 1, 1, 1, 1, 1, 1]
    -- The ACCEPTING direction, twice: the real card, and the buried atom in an
    -- AttachTarget destination grafted onto a card with no attach of its own --
    -- so the acceptance is about the POSITION and not about Aura Graft.
    Spec.assertEqWith
      s
      "Aura Graft is accepted"
      (canHostSubjectOffends (S.combinedFace graft), canHostSubjectCounts (S.combinedFace graft))
      (False, (1, 0))
    let grafted = base {Face.spell = spellOf [Effect.AttachTarget (AttachTarget.MkAttachTarget slot buried)] (Map.singleton slot (TargetSlot.required Pool.Permanents Nothing))}
    Spec.assertEqWith
      s
      "a buried atom in an AttachTarget destination is accepted"
      (canHostSubjectOffends grafted, canHostSubjectCounts grafted)
      (False, (1, 0))
    Spec.assertEqWith
      s
      "and the ungrafted base card carries no atom at all"
      (canHostSubjectOffends base, canHostSubjectCounts base)
      (False, (0, 0))
  -- The rejecting direction for CR 709.4a, for the reason the test above gives:
  -- Harness the Storm only exercises the ACCEPTING one, and a card that offends a
  -- lint must not be loadable, so the offenders are hand-built rather than filed.
  --
  -- Every fixture buries the atom under all three combinators, so an
  -- implementation reading only the top of a Filter would accept all of them, and
  -- each is asserted through boundNameCounts as well as the predicate -- the
  -- counts say the TRAVERSAL put it in that position, where the predicate alone is
  -- also satisfied by the codec half noticing an atom the traversal missed.
  Spec.it s "the lint itself catches a slot-anchored Shares Name outside a mode's target slot, a search filter, a hand sweep or a life loss amount" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    sorcerer <- S.printingOf s registry "Prodigal Sorcerer"
    harness <- S.printingOf s registry "Harness the Storm"
    let base = S.combinedFace piker
        slot = SlotName.MkSlotName (Text.pack "target")
        atom = Filter.Type.Shares Trait.Name (Anchor.Bound (SlotName.MkSlotName (Text.pack "thatSpell")))
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]
        spellOf effects slots =
          Mint.oneModeTargeting slots (Seq.fromList effects)
        boostedBy quantity =
          StaticAbility.MkStaticAbility
            (Affected.Matching Filter.Type.IsSource)
            Nothing
            Set.empty
            Nothing
            Nothing
            (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness quantity (Quantity.Type.Literal 0))))
        planted =
          [ -- THE one that separates this lint from a copy of the sibling: an
            -- enchant slot is a TargetSlot, and is still not a position that can
            -- answer -- Attach.attachmentFor (CR 303.4j) and
            -- Sba.stillLegalEnchant (CR 303.4c) both re-ask it through
            -- Target.admittedRecipients, which binds nothing.
            ( "CR 303.4a's enchant ability",
              base {Face.enchant = [TargetSlot.required Pool.Permanents (Just buried)]}
            ),
            ( "a static ability's affected set",
              base
                { Face.staticAbilities =
                    [ StaticAbility.MkStaticAbility
                        (Affected.Matching buried)
                        Nothing
                        Set.empty
                        Nothing
                        Nothing
                        (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Type.Literal 1) (Quantity.Type.Literal 1))))
                    ]
                }
            ),
            ( "a Count's filter",
              base
                { Face.staticAbilities =
                    [ boostedBy
                        ( Quantity.Type.Count
                            (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                        )
                    ]
                }
            ),
            ( "an ObjectRef.EachMatching set",
              base {Face.spell = spellOf [Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching buried) Regenerability.Regenerable Nothing Nothing Nothing)] Map.empty}
            ),
            ( "CR 603.6a's trigger condition",
              base
                { Face.triggeredAbilities =
                    [ oneEffectTrigger
                        (TriggerCondition.PermanentEnters buried)
                        (Effect.Draw (Draw.MkDraw (PlayerRef.InSlot Binding.you) (Quantity.Type.Literal 1) Nothing))
                    ]
                }
            ),
            ( "CR 601.2f's sacrifice cost component",
              (S.combinedFace sorcerer)
                { Face.activatedAbilities =
                    fmap
                      (\a -> a {ActivatedAbility.cost = (ActivatedAbility.cost a) {Cost.Type.components = [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) buried)]}})
                      (Face.activatedAbilities (S.combinedFace sorcerer))
                }
            ),
            ( "CR 702.29e's typecycling predicate",
              base {Face.keywords = Map.singleton (Keyword.Cycling (Cycling.MkCycling (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) []) (Just buried))) 1}
            ),
            ( "a created token's own static ability",
              base
                { Face.spell =
                    spellOf
                      [ Effect.Create
                          Create.MkCreate
                            { Create.quantity = Quantity.Type.Literal 1,
                              Create.card = oneFaced (base {Face.staticAbilities = [StaticAbility.MkStaticAbility (Affected.Matching buried) Nothing Set.empty Nothing Nothing (NonEmpty.singleton Modification.LoseAllAbilities)]}),
                              Create.riders = EntryRiders.defaultValue,
                              Create.slot = Nothing,
                              Create.creator = PlayerRef.Relative PlayerRelation.You
                            }
                      ]
                      Map.empty
                }
            )
          ]
        report (label, card) = (label, boundNameOffends card, boundNameCounts card)
    Spec.assertEqWith
      s
      "every position that cannot answer is rejected, and the traversal is what finds it"
      (fmap report planted)
      (fmap (\(label, _) -> (label, True, (0, 1))) planted)
    Spec.assertEqWith
      s
      "and the codec counts exactly the atoms the traversal does"
      (fmap (\(_, card) -> boundNameAtoms (Codec.encode (Face.Codec.codec Card.codec) card)) planted)
      (fmap (const 1) planted)
    -- The nesting, stated on its own: a top-level-only check would score every one
    -- of these zero but the first.
    Spec.assertEqWith
      s
      "the atom is found at every nesting depth"
      ( fmap
          (boundNameAtoms . atomJson)
          [ atom,
            Filter.Type.And [atom],
            Filter.Type.Or [atom],
            Filter.Type.Not atom,
            buried,
            Filter.Type.HasKeyword (Keyword.Cycling (Cycling.MkCycling (Cost.Type.MkCost Nothing []) (Just atom)))
          ]
      )
      [1, 1, 1, 1, 1, 1]
    -- The ACCEPTING direction, twice: the real card, and the buried atom in a mode
    -- target slot grafted onto a card that declares none of its own -- so the
    -- acceptance is about the POSITION and not about Harness the Storm.
    Spec.assertEqWith
      s
      "Harness the Storm is accepted"
      (boundNameOffends (S.combinedFace harness), boundNameCounts (S.combinedFace harness))
      (False, (1, 0))
    let slotted = base {Face.spell = spellOf [] (Map.singleton slot (TargetSlot.required Pool.Permanents (Just buried)))}
    Spec.assertEqWith
      s
      "a buried atom in a mode's target slot is accepted"
      (boundNameOffends slotted, boundNameCounts slotted)
      (False, (1, 0))
    -- The OTHER accepted position, and the pair to the rejections above: a search
    -- filter is matched in the resolution's own context
    -- (Parun.Engine.Resolve.Slots.effectContext), so the same buried atom that offends
    -- in every position above is accepted here.
    let searched = base {Face.spell = spellOf [Effect.Search Search.MkSearch {Search.searcher = PlayerRef.Relative PlayerRelation.You, Search.owner = PlayerRef.Relative PlayerRelation.You, Search.zones = Set.singleton Zone.Library, Search.outsideTheGame = False, Search.quantity = Just (Quantity.Type.Literal 1), Search.filter = buried, Search.upTo = False, Search.destination = SearchDestination.RevealThenHand, Search.subject = Nothing, Search.slot = Nothing, Search.differentIn = Set.empty, Search.exactly = False, Search.andOr = False}] Map.empty}
    Spec.assertEqWith
      s
      "a buried atom in a search's filter is accepted"
      (boundNameOffends searched, boundNameCounts searched)
      (False, (1, 0))
    -- The THIRD accepted position, and the one that separates this lint from a
    -- rule about ObjectRefs: EachCardInHand's own filter is matched in the
    -- resolution's context (Resolve.Slots.objectRefObjects), where the
    -- EachMatching set planted above is not a position slotNames reaches -- the
    -- two sit in the same field of the same effect and answer differently.
    let sweptHand = base {Face.spell = spellOf [Effect.Reveal (Reveal.MkReveal (ObjectRef.EachCardInHand (EachCardInHand.MkEachCardInHand (ZoneScope.ControllerOfBound slot) (Just buried))) Nothing)] Map.empty}
    Spec.assertEqWith
      s
      "a buried atom in a hand sweep's filter is accepted"
      (boundNameOffends sweptHand, boundNameCounts sweptHand)
      (False, (1, 0))
    Spec.assertEqWith
      s
      "and the ungrafted base card carries no atom at all"
      (boundNameOffends base, boundNameCounts base)
      (False, (0, 0))
  -- The rejecting direction for CR 201.4, for the reason the two tests above give:
  -- Ancient Vendetta only exercises the ACCEPTING one, and a card that offends a
  -- lint must not be loadable, so the offenders are hand-built rather than filed.
  --
  -- Every fixture buries the atom under all three combinators, for the sibling's
  -- reason, and each is asserted through hasChosenNameCounts as well as the
  -- predicate.
  Spec.it s "the lint itself catches HasChosenName outside an admitted position" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    sorcerer <- S.printingOf s registry "Prodigal Sorcerer"
    vendetta <- S.printingOf s registry "Ancient Vendetta"
    let base = S.combinedFace piker
        slot = SlotName.MkSlotName (Text.pack "target")
        atom = Filter.Type.HasChosenName NameChooser.AnyChooser
        buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]
        spellOf effects slots =
          Mint.oneModeTargeting slots (Seq.fromList effects)
        searchFor f = Effect.Search Search.MkSearch {Search.searcher = PlayerRef.Relative PlayerRelation.You, Search.owner = PlayerRef.Relative PlayerRelation.You, Search.zones = Set.singleton Zone.Library, Search.outsideTheGame = False, Search.quantity = Just (Quantity.Type.Literal 1), Search.filter = f, Search.upTo = False, Search.destination = SearchDestination.Exile, Search.subject = Nothing, Search.slot = Nothing, Search.differentIn = Set.empty, Search.exactly = False, Search.andOr = False}
        planted =
          [ ( "CR 303.4a's enchant ability",
              base {Face.enchant = [TargetSlot.required Pool.Permanents (Just buried)]}
            ),
            ( "CR 201.4a's own restriction on the choosing effect",
              base {Face.spell = spellOf [Effect.ChooseCardName (ChooseCardName.MkChooseCardName (PlayerRef.Relative PlayerRelation.You) buried)] Map.empty}
            ),
            -- THE counter-example to the ObjectRef position accepted below, and
            -- the reason StandingHostFramed is a constructor of its own (#3320):
            -- Parun.Engine.Projection.conditionHolds builds this clause's context
            -- through Filter.contextFor, which leaves sourceChosenNames empty, so
            -- the atom here is the silent False the lint exists to catch. It was
            -- ACCEPTED between #2992 and #3320, when both positions shared a tag.
            ( "CR 604.2's clause gating a static ability",
              base
                { Face.staticAbilities =
                    [ StaticAbility.MkStaticAbility
                        (Affected.Matching Filter.Type.IsSource)
                        ( Just
                            ( Condition.Type.Compares
                                ( Compares.MkCompares
                                    ( Quantity.Type.Count
                                        (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) buried Aggregation.Members)
                                    )
                                    Comparison.AtLeast
                                    (Quantity.Type.Literal 1)
                                )
                            )
                        )
                        Set.empty
                        Nothing
                        Nothing
                        (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Type.Literal 1) (Quantity.Type.Literal 1))))
                    ]
                }
            ),
            ( "CR 601.2f's sacrifice cost component",
              (S.combinedFace sorcerer)
                { Face.activatedAbilities =
                    fmap
                      (\a -> a {ActivatedAbility.cost = (ActivatedAbility.cost a) {Cost.Type.components = [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) buried)]}})
                      (Face.activatedAbilities (S.combinedFace sorcerer))
                }
            ),
            ( "CR 702.29e's typecycling predicate",
              base {Face.keywords = Map.singleton (Keyword.Cycling (Cycling.MkCycling (Cost.Type.MkCost (Just (ManaCost.MkManaCost [])) []) (Just buried))) 1}
            )
          ]
        report (label, card) = (label, hasChosenNameOffends card, hasChosenNameCounts card)
    Spec.assertEqWith
      s
      "every position that cannot answer is rejected, and the traversal is what finds it"
      (fmap report planted)
      (fmap (\(label, _) -> (label, True, (0, 1))) planted)
    Spec.assertEqWith
      s
      "and the codec counts exactly the atoms the traversal does"
      (fmap (\(_, card) -> jsonAtoms hasChosenNameTag (Codec.encode (Face.Codec.codec Card.codec) card)) planted)
      (fmap (const 1) planted)
    -- The ACCEPTING direction, twice: the real card, and the buried atom in a
    -- search's filter grafted onto a card that declares none of its own -- so the
    -- acceptance is about the POSITION and not about Ancient Vendetta.
    Spec.assertEqWith
      s
      "Ancient Vendetta is accepted"
      (hasChosenNameOffends (S.combinedFace vendetta), hasChosenNameCounts (S.combinedFace vendetta))
      (False, (1, 0))
    let searched = base {Face.spell = spellOf [searchFor buried] Map.empty}
    Spec.assertEqWith
      s
      "a buried atom in a search's filter is accepted"
      (hasChosenNameOffends searched, hasChosenNameCounts searched)
      (False, (1, 0))
    -- A trigger condition's own Filter, grafted the same way: Parun.Engine.Event.Match
    -- reads it through Projection.sourceContext, which carries the bearer's
    -- chosen names -- Booby Trap's "a card with the chosen name".
    let triggered =
          base
            { Face.triggeredAbilities =
                [ oneEffectTrigger
                    (TriggerCondition.PermanentEnters buried)
                    (Effect.Draw (Draw.MkDraw (PlayerRef.InSlot Binding.you) (Quantity.Type.Literal 1) Nothing))
                ]
            }
    Spec.assertEqWith
      s
      "a buried atom in a trigger condition is accepted"
      (hasChosenNameOffends triggered, hasChosenNameCounts triggered)
      (False, (1, 0))
    -- The second accepting position, grafted the same way: the mill arm's
    -- tally reads the resolution's own context, so its filter answers exactly as
    -- the search's does.
    let tallied = base {Face.spell = spellOf [Effect.Mill (Mill.MkMill (PlayerRef.Relative PlayerRelation.You) (Quantity.Type.Literal 1) (Just (MillTally.MkMillTally slot buried)) Nothing)] Map.empty}
    Spec.assertEqWith
      s
      "a buried atom in a mill's tally is accepted"
      (hasChosenNameOffends tallied, hasChosenNameCounts tallied)
      (False, (1, 0))
    -- A mode's target slot: Parun.Engine.Target.slotContext frames it by its
    -- source, so a name the source chose as it entered (CR 614.1c) answers
    -- there -- Declaration of Naught's "target spell with the chosen name".
    let targeting = base {Face.spell = spellOf [] (Map.singleton slot (TargetSlot.required Pool.Permanents (Just buried)))}
    Spec.assertEqWith
      s
      "a buried atom in a mode's target slot is accepted"
      (hasChosenNameOffends targeting, hasChosenNameCounts targeting)
      (False, (1, 0))
    -- And the third, see #2992: an ObjectRef's own Filter is matched through
    -- Resolve.Slots.objectRefObjects, which builds the same context, so Petra
    -- Sphinx's "if that card has the chosen name" answers there too. This one was
    -- among the rejections above until then.
    let referenced = base {Face.spell = spellOf [Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching buried) Regenerability.Regenerable Nothing Nothing Nothing)] Map.empty}
    Spec.assertEqWith
      s
      "a buried atom in an ObjectRef's own filter is accepted"
      (hasChosenNameOffends referenced, hasChosenNameCounts referenced)
      (False, (1, 0))
    -- And a static ability's affected set, Immediate Action's: matched through
    -- Projection.affectedContext, which frames it by its source. This one was
    -- among the rejections above until then.
    let affected =
          base
            { Face.staticAbilities =
                [ StaticAbility.MkStaticAbility
                    (Affected.Matching buried)
                    Nothing
                    Set.empty
                    Nothing
                    Nothing
                    (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Type.Literal 1) (Quantity.Type.Literal 1))))
                ]
            }
    Spec.assertEqWith
      s
      "a buried atom in a static ability's affected set is accepted"
      (hasChosenNameOffends affected, hasChosenNameCounts affected)
      (False, (1, 0))
    Spec.assertEqWith
      s
      "and the ungrafted base card carries no atom at all"
      (hasChosenNameOffends base, hasChosenNameCounts base)
      (False, (0, 0))
  -- CR 607.2d's chosen colour and chosen subtype: answerable only where the
  -- asking ability's SOURCE supplies its choice, and a silent False elsewhere.
  -- See chosenValueCounts for the positions and chosenValueOffends for the two
  -- offences.
  Spec.it s "CR 607.2d no card asks HasChosenColor or HasChosenSubtype outside an admitted position" $ do
    ps <- S.allPrintings s corpus
    let offends card =
          anyFace (chosenValueOffends hasChosenColorCounts hasChosenColorTag) card
            || anyFace (chosenValueOffends hasChosenSubtypeCounts hasChosenSubtypeTag) card
    Spec.assertEqWith s "the atoms sit only where the source's choice is supplied" (fmap (S.nameOf . Printing.card) (filter (offends . Printing.card) ps)) []
    -- NOT vacuous: a card per admitted position is ACCEPTED rather than skipped,
    -- so a framing that stopped marking one would redden.
    Monad.forM_
      [ ("Caged Sun", hasChosenColorCounts, "an affected set", (1, 0)),
        ("Cho-Manno's Blessing", hasChosenColorCounts, "a static grant's protection quality", (1, 0)),
        ("Pentarch Paladin", hasChosenColorCounts, "an activated ability's target slot", (1, 0)),
        ("Obelisk of Urd", hasChosenSubtypeCounts, "an affected set", (1, 0)),
        ("Doom Cannon", hasChosenSubtypeCounts, "an activated ability's cost", (1, 0)),
        ("From the Rubble", hasChosenSubtypeCounts, "a triggered ability's target slot", (1, 0)),
        ("Kindred Boon", hasChosenSubtypeCounts, "an activated ability's target slot", (1, 0)),
        ("Etchings of the Chosen", hasChosenSubtypeCounts, "an affected set and an activated ability's cost", (2, 0)),
        ("Pillar of Origins", hasChosenSubtypeCounts, "a mana restriction", (1, 0)),
        ("Throne of Eldraine", hasChosenColorCounts, "a mana restriction", (1, 0)),
        ("Kindred Discovery", hasChosenSubtypeCounts, "two trigger conditions", (2, 0)),
        ("Brass Herald", hasChosenSubtypeCounts, "an affected set and a resolution's own filter", (2, 0)),
        ("Persecute", hasChosenColorCounts, "a spell's own hand sweep after its own choice", (1, 0)),
        ("Story Circle", hasChosenColorCounts, "an activated ability's chosen damage source", (1, 0))
      ]
      $ \(name, counts, position, expected) -> do
        printing <- S.printingOf s registry name
        Spec.assertEqWith s (name <> "'s atoms are framed by " <> position) (counts (S.combinedFace printing)) expected
  -- The rejecting direction, for both atoms: each buried under all three
  -- combinators and planted in a spell's positions, which cannot answer, then
  -- in source-framed ones, which can.
  Spec.it s "the lint itself catches HasChosenColor and HasChosenSubtype outside an admitted position" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    sorcerer <- S.printingOf s registry "Prodigal Sorcerer"
    let base = S.combinedFace piker
        slot = SlotName.MkSlotName (Text.pack "target")
        spellOf effects slots =
          Mint.oneModeTargeting slots (Seq.fromList effects)
        aimed f = Map.singleton slot (TargetSlot.required Pool.Permanents (Just f))
        withAbility change = (S.combinedFace sorcerer) {Face.activatedAbilities = fmap change (Face.activatedAbilities (S.combinedFace sorcerer))}
        affecting f =
          base
            { Face.staticAbilities =
                [ StaticAbility.MkStaticAbility
                    (Affected.Matching f)
                    Nothing
                    Set.empty
                    Nothing
                    Nothing
                    (NonEmpty.singleton (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Type.Literal 1) (Quantity.Type.Literal 1))))
                ]
            }
        destroying f = Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching f) Regenerability.Regenerable Nothing Nothing Nothing)
        rejected quality f =
          [ ("a spell's target slot", base {Face.spell = spellOf [] (aimed f)}),
            ("a spell's own filter", base {Face.spell = spellOf [destroying f] Map.empty}),
            ("a spell's own filter before its own choice", base {Face.spell = spellOf [destroying f, Effect.ChooseQuality quality] Map.empty}),
            ( "a spell's own filter in another mode than its choice",
              base {Face.spell = (spellOf [Effect.ChooseQuality quality] Map.empty) {Modal.modes = Modal.modes (spellOf [Effect.ChooseQuality quality] Map.empty) <> Modal.modes (spellOf [destroying f] Map.empty)}}
            )
          ]
        accepted quality f =
          [ ("a static ability's affected set", affecting f),
            ("a spell's own filter after its own choice", base {Face.spell = spellOf [Effect.ChooseQuality quality, destroying f] Map.empty}),
            ("an activated ability's target slot", withAbility (\a -> a {ActivatedAbility.modal = spellOf [] (aimed f)})),
            ("an activated ability's sacrifice cost", withAbility (\a -> a {ActivatedAbility.cost = (ActivatedAbility.cost a) {Cost.Type.components = [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) f)]}})),
            ("CR 603.6a's trigger condition", base {Face.triggeredAbilities = [oneEffectTrigger (TriggerCondition.PermanentEnters f) draw]}),
            ("a triggered ability's own filter", base {Face.triggeredAbilities = [oneEffectTrigger TriggerCondition.SelfEnters (Effect.Destroy (Destroy.MkDestroy (ObjectRef.EachMatching f) Regenerability.Regenerable Nothing Nothing Nothing))]}),
            ( "CR 603.4's intervening clause",
              base {Face.triggeredAbilities = [(oneEffectTrigger TriggerCondition.SelfEnters draw) {TriggeredAbility.intervening = Just (Condition.Type.Compares (Compares.MkCompares (Quantity.Type.Count (Count.Type.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) f Aggregation.Members)) Comparison.AtLeast (Quantity.Type.Literal 1)))}]}
            )
          ]
        draw = Effect.Draw (Draw.MkDraw (PlayerRef.InSlot Binding.you) (Quantity.Type.Literal 1) Nothing)
    Monad.forM_
      [ (Filter.Type.HasChosenColor, ChosenQuality.Colors 1, hasChosenColorCounts, hasChosenColorTag),
        (Filter.Type.HasChosenSubtype, ChosenQuality.BasicLandType, hasChosenSubtypeCounts, hasChosenSubtypeTag)
      ]
      $ \(atom, quality, counts, tag) -> do
        let buried = Filter.Type.And [Filter.Type.Or [Filter.Type.HasCardType CardType.Creature, Filter.Type.Not atom]]
            report (label, card) = (label, chosenValueOffends counts tag card, counts card)
        Spec.assertEqWith
          s
          "every position that cannot answer is rejected"
          (fmap report (rejected quality buried))
          (fmap (\(label, _) -> (label, True, (0, 1))) (rejected quality buried))
        Spec.assertEqWith
          s
          "and every position that can is accepted"
          (fmap report (accepted quality buried))
          (fmap (\(label, _) -> (label, False, (1, 0))) (accepted quality buried))
        Spec.assertEqWith
          s
          "and the codec counts exactly the atoms the traversal does"
          (fmap (\(_, card) -> jsonAtoms tag (Codec.encode (Face.Codec.codec Card.codec) card)) (rejected quality buried <> accepted quality buried))
          (fmap (const 1) (rejected quality buried <> accepted quality buried))

  -- CR 607.2a's last exiled card: answerable in a mana restriction alone. Ice
  -- Cauldron is accepted rather than skipped, and the same atom moved into an
  -- activated ability's target slot is rejected, so the lint is not vacuous.
  Spec.it s "CR 607.2a no card asks IsLastExiledWithSource outside a mana restriction" $ do
    ps <- S.allPrintings s corpus
    Spec.assertEqWith
      s
      "the atom sits only in a mana restriction"
      (fmap (S.nameOf . Printing.card) (filter (anyFace (chosenValueOffends isLastExiledWithSourceCounts isLastExiledWithSourceTag) . Printing.card) ps))
      []
    cauldron <- S.printingOf s registry "Ice Cauldron"
    Spec.assertEqWith s "Ice Cauldron's atom is framed by a mana restriction" (isLastExiledWithSourceCounts (S.combinedFace cauldron)) (1, 0)
    sorcerer <- S.printingOf s registry "Prodigal Sorcerer"
    let slot = SlotName.MkSlotName (Text.pack "target")
        aimed =
          Mint.oneModeTargeting (Map.singleton slot (TargetSlot.required Pool.Permanents (Just Filter.Type.IsLastExiledWithSource))) Seq.empty
        planted = (S.combinedFace sorcerer) {Face.activatedAbilities = fmap (\a -> a {ActivatedAbility.modal = aimed}) (Face.activatedAbilities (S.combinedFace sorcerer))}
    Spec.assertEqWith
      s
      "and a target slot asking it is rejected"
      (chosenValueOffends isLastExiledWithSourceCounts isLastExiledWithSourceTag planted, isLastExiledWithSourceCounts planted)
      (True, (0, 1))

spec :: (Monad n) => Spec.Spec IO n -> Registry.Registry IO -> [(FilePath, Either Text.Text Card.Type.Card)] -> n ()
spec s registry corpus = Spec.describe s "Parun.Engine.Card" $ do
  filterPositionLintSpec s registry corpus
