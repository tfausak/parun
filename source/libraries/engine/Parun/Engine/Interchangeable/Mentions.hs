-- | The effect DSL's one walk, answering two questions of a tree -- an effect,
-- an ability, a replacement, a cost, a duration, a card -- through the leaves
-- an Asking names: whether it might name one object, which
-- Parun.Engine.Interchangeable asks of every stored row; and which of the
-- turn's history it reads (CR 732.3), which Parun.Engine.Fragmented asks of
-- every printing.
--
-- One function per type, each matching every constructor POSITIONALLY, so a
-- new constructor is a missing-pattern error here and a new field an arity
-- error, rather than an ObjectId or a history read this silently stops
-- reading. A field whose type can hold no ObjectId, slot name, Filter or
-- history read is a named discard, and that is the one site nothing forces: a
-- type that later gains one owes every discard of it here a function.
--
-- A tree names an object in three ways: an ObjectId it holds outright, a slot
-- it reads (slotNames), and a Filter atom (filterNames). A Card it holds is
-- printed data and names nothing -- Parun.FilterPositionLintSpec's "CR
-- 702.119c no card writes IsObject" keeps the one runtime atom out of it --
-- so Parun.Engine.Interchangeable passes `const mempty` for it, and
-- Parun.Engine.Fragmented cardNames. A type parameter is answered by the
-- function the caller passes for it.
--
-- A tree reads the history through the arm of the construct whose engine read
-- site consults GameState.events or GameState.activationsThisTurn -- and a
-- keyword's arm, where the engine EXPANDS the keyword into one or gates its
-- cost on one (Parun.Engine.Keyword, Parun.Engine.Cost.candidateCostsGiven).
module Parun.Engine.Interchangeable.Mentions where

import qualified Data.Map.Strict as Map
import qualified Parun.Engine.Binding as Binding.Engine
import qualified Parun.Types.AbilityAct as AbilityAct
import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.ActivateManaAbilities as ActivateManaAbilities
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.ActivationProhibition as ActivationProhibition
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.ActivationsThisTurn as ActivationsThisTurn
import qualified Parun.Types.ActiveReplacement as ActiveReplacement
import qualified Parun.Types.AffectPlayers as AffectPlayers
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Types.AgainstExiledPile as AgainstExiledPile
import qualified Parun.Types.AgainstLastCardExiledWith as AgainstLastCardExiledWith
import qualified Parun.Types.AgainstSlot as AgainstSlot
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AimedAt as AimedAt
import qualified Parun.Types.AimedPlayers as AimedPlayers
import qualified Parun.Types.AloneUnless as AloneUnless
import qualified Parun.Types.AlternativeActivationCost as AlternativeActivationCost
import qualified Parun.Types.AlternativeCost as AlternativeCost
import qualified Parun.Types.Amass as Amass
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.Ante as Ante
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.Arithmetic as Arithmetic
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.Types.ArrangedArrival as ArrangedArrival
import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.AttachAll as AttachAll
import qualified Parun.Types.AttachBound as AttachBound
import qualified Parun.Types.AttachR as AttachR
import qualified Parun.Types.AttachRestriction as AttachRestriction
import qualified Parun.Types.AttachRewrite as AttachRewrite
import qualified Parun.Types.AttachTarget as AttachTarget
import qualified Parun.Types.AttachedToBound as AttachedToBound
import qualified Parun.Types.AttackCost as AttackCost
import qualified Parun.Types.AttackLimitUnless as AttackLimitUnless
import qualified Parun.Types.AttackPermission as AttackPermission
import qualified Parun.Types.AttackRequirement as AttackRequirement
import qualified Parun.Types.AttackTargetRef as AttackTargetRef
import qualified Parun.Types.AttackingPlayers as AttackingPlayers
import qualified Parun.Types.Backup as Backup
import qualified Parun.Types.BecomeCopy as BecomeCopy
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.Behold as Behold
import qualified Parun.Types.Bid as Bid
import qualified Parun.Types.BindAmount as BindAmount
import qualified Parun.Types.Binding as Binding
import qualified Parun.Types.Blight as Blight
import qualified Parun.Types.BlockCost as BlockCost
import qualified Parun.Types.BlockPermission as BlockPermission
import qualified Parun.Types.BlockRequirement as BlockRequirement
import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.CandidateId as CandidateId
import qualified Parun.Types.CantAttackPlayer as CantAttackPlayer
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.CantBlockCreatures as CantBlockCreatures
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardLeavesZone as CardLeavesZone
import qualified Parun.Types.CardPutIntoGraveyard as CardPutIntoGraveyard
import qualified Parun.Types.CardsPutIntoZone as CardsPutIntoZone
import qualified Parun.Types.CastFrom as CastFrom
import qualified Parun.Types.CastFromZone as CastFromZone
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.CastRepetition as CastRepetition
import qualified Parun.Types.CastingRestriction as CastingRestriction
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.ChangeText as ChangeText
import qualified Parun.Types.CharacteristicPT as CharacteristicPT
import qualified Parun.Types.ChooseCardName as ChooseCardName
import qualified Parun.Types.ChooseNumber as ChooseNumber
import qualified Parun.Types.ChoosePermanents as ChoosePermanents
import qualified Parun.Types.ChoosePlayer as ChoosePlayer
import qualified Parun.Types.ChoosePlayerAtRandom as ChoosePlayerAtRandom
import qualified Parun.Types.Chooser as Chooser
import qualified Parun.Types.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Types.ChosenCardInGraveyard as ChosenCardInGraveyard
import qualified Parun.Types.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.CompletedDungeon as CompletedDungeon
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Conjure as Conjure
import qualified Parun.Types.ConjureCards as ConjureCards
import qualified Parun.Types.Connive as Connive
import qualified Parun.Types.ControlPlayer as ControlPlayer
import qualified Parun.Types.ControlSides as ControlSides
import qualified Parun.Types.ControlSlots as ControlSlots
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.CopyClause as CopyClause
import qualified Parun.Types.CopyException as CopyException
import qualified Parun.Types.CopyOriginal as CopyOriginal
import qualified Parun.Types.CopyStackObject as CopyStackObject
import qualified Parun.Types.CopyTargets as CopyTargets
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAddition as CostAddition
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostBasis as CostBasis
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.CostReduction as CostReduction
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.CouldProduce as CouldProduce
import qualified Parun.Types.Count as Count
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.Counter as Counter
import qualified Parun.Types.CounterDestination as CounterDestination
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPattern as CounterPattern
import qualified Parun.Types.CounterPlacement as CounterPlacement
import qualified Parun.Types.CounterProhibition as CounterProhibition
import qualified Parun.Types.CounterR as CounterR
import qualified Parun.Types.CounterRestriction as CounterRestriction
import qualified Parun.Types.CounterSubject as CounterSubject
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.CountersOnThis as CountersOnThis
import qualified Parun.Types.Craft as Craft
import qualified Parun.Types.Create as Create
import qualified Parun.Types.CreateCopy as CreateCopy
import qualified Parun.Types.CreateEmblem as CreateEmblem
import qualified Parun.Types.CreatureExploits as CreatureExploits
import qualified Parun.Types.CrewRestriction as CrewRestriction
import qualified Parun.Types.Cycling as Cycling
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DamagePattern as DamagePattern
import qualified Parun.Types.DamageR as DamageR
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.DelayedTrigger as DelayedTrigger
import qualified Parun.Types.Designate as Designate
import qualified Parun.Types.Destroy as Destroy
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.Devotion as Devotion
import qualified Parun.Types.Devour as Devour
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.DieRollR as DieRollR
import qualified Parun.Types.Discard as Discard
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.Divide as Divide
import qualified Parun.Types.DoesNotUntapNext as DoesNotUntapNext
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.DrawCountR as DrawCountR
import qualified Parun.Types.DrawR as DrawR
import qualified Parun.Types.DrawRewrite as DrawRewrite
import qualified Parun.Types.DungeonRoom as DungeonRoom
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.DuringPhase as DuringPhase
import qualified Parun.Types.EachCardFromAmong as EachCardFromAmong
import qualified Parun.Types.EachCardInExiledPile as EachCardInExiledPile
import qualified Parun.Types.EachCardInGraveyard as EachCardInGraveyard
import qualified Parun.Types.EachCardInHand as EachCardInHand
import qualified Parun.Types.Earthbend as Earthbend
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Emerge as Emerge
import qualified Parun.Types.EnteredZone as EnteredZone
import qualified Parun.Types.EntersWith as EntersWith
import qualified Parun.Types.EntryAttack as EntryAttack
import qualified Parun.Types.EntryBlock as EntryBlock
import qualified Parun.Types.EntryController as EntryController
import qualified Parun.Types.EntryFlip as EntryFlip
import qualified Parun.Types.EntryHost as EntryHost
import qualified Parun.Types.EntryOption as EntryOption
import qualified Parun.Types.EntryPrice as EntryPrice
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRestriction as EntryRestriction
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.Equip as Equip
import qualified Parun.Types.EventExpiry as EventExpiry
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.ExchangeBlocks as ExchangeBlocks
import qualified Parun.Types.ExchangeCardZones as ExchangeCardZones
import qualified Parun.Types.ExchangeOwnership as ExchangeOwnership
import qualified Parun.Types.ExchangeSides as ExchangeSides
import qualified Parun.Types.ExchangeValues as ExchangeValues
import qualified Parun.Types.ExchangeZones as ExchangeZones
import qualified Parun.Types.ExchangedValue as ExchangedValue
import qualified Parun.Types.ExileCardsFromGraveyard as ExileCardsFromGraveyard
import qualified Parun.Types.ExileCardsFromHand as ExileCardsFromHand
import qualified Parun.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Parun.Types.ExileHaunting as ExileHaunting
import qualified Parun.Types.ExileMaterials as ExileMaterials
import qualified Parun.Types.ExilePermanents as ExilePermanents
import qualified Parun.Types.ExiledCardAbilities as ExiledCardAbilities
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownCharacteristics as FaceDownCharacteristics
import qualified Parun.Types.FaceDownState as FaceDownState
import qualified Parun.Types.Fight as Fight
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FlipCoin as FlipCoin
import qualified Parun.Types.FloatingCandidate as FloatingCandidate
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.ForEachNumber as ForEachNumber
import qualified Parun.Types.ForbidAttack as ForbidAttack
import qualified Parun.Types.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Parun.Types.ForetellCost as ForetellCost
import qualified Parun.Types.FromAnywhere as FromAnywhere
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.FromReference as FromReference
import qualified Parun.Types.FullText as FullText
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.GameLossR as GameLossR
import qualified Parun.Types.GrantLookAtExiled as GrantLookAtExiled
import qualified Parun.Types.GrantPlayFromExile as GrantPlayFromExile
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Guess as Guess
import qualified Parun.Types.HandAction as HandAction
import qualified Parun.Types.HistoryRead as HistoryRead
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.Impending as Impending
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.InstructionR as InstructionR
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordCount as KeywordCount
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordInstance as KeywordInstance
import qualified Parun.Types.KeywordTally as KeywordTally
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LifeGainR as LifeGainR
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.LifeLossR as LifeLossR
import qualified Parun.Types.LimitUnless as LimitUnless
import qualified Parun.Types.LookAt as LookAt
import qualified Parun.Types.LoyaltyClause as LoyaltyClause
import qualified Parun.Types.LoyaltyGrant as LoyaltyGrant
import qualified Parun.Types.MadnessCost as MadnessCost
import qualified Parun.Types.MakeForetold as MakeForetold
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.ManaCount as ManaCount
import qualified Parun.Types.ManaProduction as ManaProduction
import qualified Parun.Types.ManaR as ManaR
import qualified Parun.Types.ManaRestriction as ManaRestriction
import qualified Parun.Types.ManaRider as ManaRider
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Meld as Meld
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.MillTally as MillTally
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MonarchTarget as MonarchTarget
import qualified Parun.Types.Morph as Morph
import qualified Parun.Types.MoveCounters as MoveCounters
import qualified Parun.Types.MoveDuration as MoveDuration
import qualified Parun.Types.MoveMana as MoveMana
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.MovedKinds as MovedKinds
import qualified Parun.Types.Ninjutsu as Ninjutsu
import qualified Parun.Types.ObjectCount as ObjectCount
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.OfferCast as OfferCast
import qualified Parun.Types.Onset as Onset
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.OrElse as OrElse
import qualified Parun.Types.PaidExpiry as PaidExpiry
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PendingEntryEffect as PendingEntryEffect
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.PerCreature as PerCreature
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PermanentCandidate as PermanentCandidate
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Types.PermanentsBecomeTargeted as PermanentsBecomeTargeted
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.PlacesSticker as PlacesSticker
import qualified Parun.Types.PlaneswalkR as PlaneswalkR
import qualified Parun.Types.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerAttacksWith as PlayerAttacksWith
import qualified Parun.Types.PlayerChoice as PlayerChoice
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally
import qualified Parun.Types.PlayerCounters as PlayerCounters
import qualified Parun.Types.PlayerDesignationTally as PlayerDesignationTally
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerQuantity as PlayerQuantity
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerSacrifices as PlayerSacrifices
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.PlayersWho as PlayersWho
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.PlotFromZone as PlotFromZone
import qualified Parun.Types.Plus as Plus
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Power as Power
import qualified Parun.Types.PreventAllDamage as PreventAllDamage
import qualified Parun.Types.PreventNextDamage as PreventNextDamage
import qualified Parun.Types.PreventNextDamageInstance as PreventNextDamageInstance
import qualified Parun.Types.Prevention as Prevention
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Prohibit as Prohibit
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.PutCountersFrom as PutCountersFrom
import qualified Parun.Types.PutSticker as PutSticker
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Quotient as Quotient
import qualified Parun.Types.RandomCardInGraveyard as RandomCardInGraveyard
import qualified Parun.Types.RandomCardInHand as RandomCardInHand
import qualified Parun.Types.RandomCardInLibrary as RandomCardInLibrary
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.RedirectDamage as RedirectDamage
import qualified Parun.Types.Reinforce as Reinforce
import qualified Parun.Types.RemovalCount as RemovalCount
import qualified Parun.Types.RemoveCounters as RemoveCounters
import qualified Parun.Types.RemoveCountersAmong as RemoveCountersAmong
import qualified Parun.Types.RemovePlayerCounters as RemovePlayerCounters
import qualified Parun.Types.Repeat as Repeat
import qualified Parun.Types.RepeatIf as RepeatIf
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.RequireAttack as RequireAttack
import qualified Parun.Types.RequireBlock as RequireBlock
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.ReturnPermanents as ReturnPermanents
import qualified Parun.Types.Reveal as Reveal
import qualified Parun.Types.RevealedThisWay as RevealedThisWay
import qualified Parun.Types.RollDie as RollDie
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.SacrificeAnyNumber as SacrificeAnyNumber
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.SacrificeRestriction as SacrificeRestriction
import qualified Parun.Types.SacrificeToEnter as SacrificeToEnter
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Search as Search
import qualified Parun.Types.SelfCountersReached as SelfCountersReached
import qualified Parun.Types.SelfCountersRemoved as SelfCountersRemoved
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.SetClassLevel as SetClassLevel
import qualified Parun.Types.SetHalfLocked as SetHalfLocked
import qualified Parun.Types.SetOwner as SetOwner
import qualified Parun.Types.ShuffleIntoLibrary as ShuffleIntoLibrary
import qualified Parun.Types.SkipPhase as SkipPhase
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SlotPerPlayer as SlotPerPlayer
import qualified Parun.Types.SpecialAction as SpecialAction
import qualified Parun.Types.SpeedDecrease as SpeedDecrease
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.Splice as Splice
import qualified Parun.Types.StatedFlip as StatedFlip
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.Suspend as Suspend
import qualified Parun.Types.TakeExtraTurn as TakeExtraTurn
import qualified Parun.Types.Tap as Tap
import qualified Parun.Types.TapForMana as TapForMana
import qualified Parun.Types.TapForTotalPower as TapForTotalPower
import qualified Parun.Types.TapPermanents as TapPermanents
import qualified Parun.Types.TargetRestriction as TargetRestriction
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.Times as Times
import qualified Parun.Types.TokenPattern as TokenPattern
import qualified Parun.Types.TokenPlus as TokenPlus
import qualified Parun.Types.TokenR as TokenR
import qualified Parun.Types.TopOfLibrary as TopOfLibrary
import qualified Parun.Types.TopOfLibraryUntil as TopOfLibraryUntil
import qualified Parun.Types.Toughness as Toughness
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnFaceDown as TurnFaceDown
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.TurnUpR as TurnUpR
import qualified Parun.Types.TurnUpRewrite as TurnUpRewrite
import qualified Parun.Types.UntapR as UntapR
import qualified Parun.Types.UntapRestriction as UntapRestriction
import qualified Parun.Types.UntapRewrite as UntapRewrite
import qualified Parun.Types.Vote as Vote
import qualified Parun.Types.VoteChoices as VoteChoices
import qualified Parun.Types.VoteObjects as VoteObjects
import qualified Parun.Types.VotePlayers as VotePlayers
import qualified Parun.Types.VotesReceived as VotesReceived
import qualified Parun.Types.Ward as Ward
import qualified Parun.Types.WhenSpent as WhenSpent
import qualified Parun.Types.WhichCounters as WhichCounters
import qualified Parun.Types.While as While
import qualified Parun.Types.WithCounters as WithCounters
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern
import qualified Parun.Types.ZoneChangeR as ZoneChangeR
import qualified Parun.Types.ZoneScope as ZoneScope

-- | What a traversal answers at each kind of leaf, combined over the tree by
-- r's Monoid: whether a tree might name one object (Parun.Engine.Interchangeable,
-- over Data.Monoid.Any), or which history it reads (Parun.Engine.Fragmented).
data Asking r = MkAsking
  { -- | An ObjectId the tree holds, by the test it passes.
    names :: (ObjectId -> Bool) -> r,
    -- | A slot read, or an atom reading the resolution context.
    context :: r,
    -- | A Filter atom reading a record kept per object id, which whole-object
    -- Eq does not compare.
    keyed :: r,
    -- | A read of the turn's history (CR 732.3).
    history :: HistoryRead.HistoryRead -> r
  }

-- Whether reading this slot might name the object.
slotNames :: Asking r -> SlotName.SlotName -> r
slotNames asking _slot = contextNames asking

-- Whether an atom reading the resolution context -- an enclosing target slot's
-- amount, an attach's subject, a baked crew or attachment set -- might name the
-- object. The same answer as a slot read, since a stored row's context is its
-- environment.
contextNames :: Asking r -> r
contextNames = context

-- Whether a Filter might single this object out from one alike in every other
-- respect.
--
-- Two objects equal whole bar the timestamp, projecting alike, named by no
-- other object, relation, stored row or combat assignment, present every atom
-- the same Parun.Engine.Filter.View in all but three respects, so an atom reading
-- none of them answers the same of both, now and after either is chosen:
--
--   * IDENTITY: IsObject names an id outright.
--   * The turn's EVENT LOG: the look-back atoms (AttackedThisTurn,
--     MilledThisTurn, DealtDamageThisTurn, EnteredThisTurn, the
--     crewed/convoked/saddled-the-source atoms) and EnteredWithSource
--     (GameState.enteredWith) and CouldAttackThisTurn
--     (GameState.couldAttackThisTurn) read a record kept per object id,
--     answered by Asking's keyed -- and the look-back atoms by its history too.
--   * A RESOLUTION CONTEXT: the slot atoms, the slot and amount operands, the
--     attach and search subject atoms, CantCrewVehicles and
--     AttachedNoLaterThanSource's baked set, answered by slotNames and
--     contextNames.
--
-- No atom reads a timestamp. The source comparisons read the row's source,
-- which Parun.Engine.Interchangeable checks is neither object; the combat atoms
-- read the combat it searches; the attachment atoms read the candidate's own
-- attachedTo, which whole-object Eq compares, or another object's, which
-- namedByAnother searches. A nested Filter is asked of some OTHER object -- a
-- host, a target, a source, a represented card, an attacher, a permanent a
-- player counts -- which may be one of the two, so it is recursed into.
filterNames :: (Monoid r) => Asking r -> Filter.Filter keyword -> r
filterNames asking criterion = case criterion of
  Filter.HasCardType _cardType -> mempty
  Filter.HasSupertype _supertype -> mempty
  Filter.HasColor _color -> mempty
  Filter.Shares _trait anchor -> anchorNames asking anchor
  Filter.HasSubtype _subtype -> mempty
  Filter.HasName _name -> mempty
  Filter.NameWordsAtLeast _n -> mempty
  Filter.HasNameOriginallyPrintedIn _expansion -> mempty
  Filter.HasKeyword _keyword -> mempty
  Filter.HasKeywordFamily _family -> mempty
  Filter.Measures measures -> measuresNames asking measures
  Filter.ManaValueIsEven -> mempty
  Filter.HeldBy _holder _relation -> mempty
  Filter.ControlledByRole _ -> mempty
  Filter.HeldByBound _holder slot -> slotNames asking slot
  Filter.HeldByPlayer _holder _player -> mempty
  Filter.HeldByRecipient _holder -> mempty
  Filter.IsSource -> mempty
  Filter.IsObject oid -> names asking (== oid)
  Filter.TargetsSource -> mempty
  Filter.TargetsOnlyOne nested -> filterNames asking nested
  Filter.HasSingleTarget -> mempty
  Filter.TargetsMatching nested -> filterNames asking nested
  Filter.TargetsPlayer _relation -> mempty
  Filter.IsBound slot -> slotNames asking slot
  Filter.IsTarget -> slotNames asking Binding.Engine.announcedTargets
  Filter.ControllerRelatesToBound _playerRelation slot -> slotNames asking slot
  Filter.SameControllerAsHostOfBound slot -> slotNames asking slot
  Filter.HasChosenName {} -> mempty
  Filter.HasChosenColor -> mempty
  Filter.HasChosenSubtype -> mempty
  Filter.IsExiledWithSource _ -> mempty
  Filter.IsLastExiledWithSource -> mempty
  Filter.OfChosenPlayer -> mempty
  Filter.OfRelatedPlayer _ -> mempty
  Filter.IsPlayer _relation -> mempty
  Filter.IsControllerOfBound slot -> slotNames asking slot
  Filter.Controls _margin nested -> filterNames asking nested
  Filter.CardsInGraveyardAtLeast _n -> mempty
  Filter.IsAttacking -> mempty
  Filter.IsAttackingPlayer _relation -> mempty
  Filter.IsAttackingPlaneswalker _relation -> mempty
  Filter.IsAttackingBattle _relation -> mempty
  Filter.DeclaredAttackedThisCombat -> mempty
  Filter.IsBlocking -> mempty
  Filter.HasBlockStatus _ -> mempty
  Filter.DeclaredAttackerThisCombat -> mempty
  Filter.DeclaredBlockerThisCombat -> mempty
  Filter.AttackedThisTurn -> keyed asking <> history asking HistoryRead.Attacks
  Filter.CouldAttackThisTurn -> keyed asking
  Filter.MilledThisTurn -> keyed asking <> history asking HistoryRead.Mills
  Filter.CantCrewVehicles -> contextNames asking
  Filter.CrewedSourceThisTurn -> keyed asking <> history asking HistoryRead.Crews
  Filter.ConvokedSourceThisTurn -> keyed asking <> history asking HistoryRead.Convokes <> history asking HistoryRead.Moves
  Filter.SaddledSourceThisTurn -> keyed asking <> history asking HistoryRead.Saddles
  Filter.DealtDamageThisTurn -> keyed asking <> history asking HistoryRead.Damage
  Filter.DealtDamageToThisTurn _ -> keyed asking <> history asking HistoryRead.Damage
  Filter.EnteredThisTurn (EnteredZone.MkEnteredZone to _from) -> keyed asking <> history asking (if to == Zone.Battlefield then HistoryRead.Entries else HistoryRead.Moves)
  Filter.ControlledSinceTurnBegan -> mempty
  Filter.AttachedTo nested -> filterNames asking nested
  Filter.HasAttached nested -> filterNames asking nested
  Filter.IsAttachedTo anchor -> anchorNames asking anchor
  Filter.IsEvaluated -> mempty
  Filter.IsHostOfSource -> mempty
  Filter.EnteredWithSource -> keyed asking
  Filter.AttachedNoLaterThanSource -> contextNames asking
  Filter.CanHostSubject -> contextNames asking
  Filter.CanAttachToSubject -> contextNames asking
  Filter.HostOfSubjectHasCardType _cardType -> contextNames asking
  Filter.IsToken -> mempty
  Filter.IsCommander -> mempty
  Filter.IsActivatedAbility -> mempty
  Filter.IsAbility -> mempty
  Filter.IsEmblem -> mempty
  Filter.FromSource nested -> filterNames asking nested
  Filter.IsTapped -> mempty
  Filter.IsFaceDown -> mempty
  Filter.RepresentedByCard nested -> filterNames asking nested
  Filter.IsExiledFaceDown -> mempty
  Filter.Transformed -> mempty
  Filter.IsRingBearer -> mempty
  Filter.IsPaired -> mempty
  Filter.IsPairedWithSource -> mempty
  Filter.BlockPartnerOfSource _ -> mempty
  Filter.HasDesignation _designation -> mempty
  Filter.HasCounters _kind -> mempty
  Filter.HasCountersOfAnyKind -> mempty
  Filter.HasSticker _kind -> mempty
  Filter.Stickered -> mempty
  Filter.HasActivatedAbility _ -> mempty
  Filter.IsInZone _zone -> mempty
  Filter.WasCastFrom _zone -> mempty
  Filter.TagWasSpent _tag -> mempty
  Filter.Paid _keywordDesignator -> mempty
  Filter.IsPrototyped -> mempty
  Filter.And nested -> foldMap (filterNames asking) nested
  Filter.Or nested -> foldMap (filterNames asking) nested
  Filter.Not nested -> filterNames asking nested
  Filter.Unwritten nested -> filterNames asking nested

abilityAddsManaNames :: (Monoid r) => Asking r -> AbilityAddsMana.AbilityAddsMana -> r
abilityAddsManaNames asking x = case x of
  AbilityAddsMana.MkAbilityAddsMana _player source _mana -> filterNames asking source

activateManaAbilitiesNames :: (Monoid r) => Asking r -> ActivateManaAbilities.ActivateManaAbilities -> r
activateManaAbilitiesNames asking x = case x of
  ActivateManaAbilities.MkActivateManaAbilities player filter_ -> playerRefNames asking player <> filterNames asking filter_

activatedAbilityNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> ActivatedAbility.ActivatedAbility card ability -> r
activatedAbilityNames asking onCard onAbility x = case x of
  ActivatedAbility.MkActivatedAbility cost maximumX _minimumX definedX modal restrictions _activator condition _name keyword -> costNames asking (keywordNames asking) cost <> foldMap (quantityNames asking) maximumX <> foldMap (quantityNames asking) definedX <> modalNames asking onCard onAbility modal <> foldMap (activationRestrictionNames asking) restrictions <> foldMap (conditionNames asking) condition <> foldMap (keywordNames asking) keyword

activationProhibitionNames :: (Monoid r) => Asking r -> ActivationProhibition.ActivationProhibition -> r
activationProhibitionNames asking x = case x of
  ActivationProhibition.MkActivationProhibition affected _kind _name -> affectedNames asking affected

activationRestrictionNames :: (Monoid r) => Asking r -> ActivationRestriction.ActivationRestriction -> r
activationRestrictionNames asking x = case x of
  ActivationRestriction.SorcerySpeed -> mempty
  ActivationRestriction.DuringPhase duringPhase -> duringPhaseNames asking duringPhase
  ActivationRestriction.DuringTurn turnScope -> turnScopeNames asking turnScope
  ActivationRestriction.AttackedThisStep -> mempty
  ActivationRestriction.AfterBlockersDeclared -> mempty
  ActivationRestriction.BeforeCombatDamage -> mempty
  ActivationRestriction.BeforeStep _phase -> history asking HistoryRead.StepBegins
  ActivationRestriction.OnlyIf condition -> conditionNames asking condition
  ActivationRestriction.OnlyOnce -> mempty
  ActivationRestriction.TimesEachTurn _ -> mempty
  ActivationRestriction.DuringDieRoll -> mempty
  ActivationRestriction.InstantSpeed -> mempty
  ActivationRestriction.SpendOnly _ -> mempty

activeReplacementNames :: (Monoid r) => Asking r -> ActiveReplacement.ActiveReplacement -> r
activeReplacementNames asking x = case x of
  ActiveReplacement.MkActiveReplacement effect source _controller _timestamp expiry _uses _origin condition rider slots_ _choices -> replacementEffectNames asking (const mempty) (grantedAbilityNames asking (const mempty)) (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty))) effect <> names asking (== source) <> expiryNames asking expiry <> foldMap (conditionNames asking) condition <> foldMap (preventionRiderNames asking) rider <> foldMap (slotNames asking) (Map.keys slots_) <> names asking (\oid -> any (elem oid) slots_)

affectPlayersNames :: (Monoid r) => Asking r -> AffectPlayers.AffectPlayers -> r
affectPlayersNames asking x = case x of
  AffectPlayers.MkAffectPlayers duration players effect -> durationNames asking duration <> affectedPlayersNames asking (slotNames asking) players <> playerEffectNames asking effect

affectedNames :: (Monoid r) => Asking r -> Affected.Affected -> r
affectedNames asking x = case x of
  Affected.TheseObjects objectId -> names asking (`elem` objectId)
  Affected.Matching filter_ -> filterNames asking filter_
  Affected.MatchingAnywhere filter_ -> filterNames asking filter_
  Affected.MatchingOffBattlefield filter_ -> filterNames asking filter_
  Affected.Attached -> mempty
  Affected.AttachedPlayerControls filter_ -> filterNames asking filter_
  Affected.PlayedThisWay duration -> durationNames asking duration

affectedPlayersNames :: (Monoid r) => Asking r -> (player -> r) -> AffectedPlayers.AffectedPlayers player -> r
affectedPlayersNames _asking onPlayer x = case x of
  AffectedPlayers.Scoped _playerScope -> mempty
  AffectedPlayers.Named player -> onPlayer player

affectedUnlessNames :: (Monoid r) => Asking r -> AffectedUnless.AffectedUnless -> r
affectedUnlessNames asking x = case x of
  AffectedUnless.MkAffectedUnless affected unless _name amount -> affectedNames asking affected <> foldMap (conditionNames asking) unless <> foldMap (quantityNames asking) amount

againstLastCardExiledWithNames :: (Monoid r) => Asking r -> (quantity -> r) -> AgainstLastCardExiledWith.AgainstLastCardExiledWith quantity -> r
againstLastCardExiledWithNames asking onQuantity x = case x of
  AgainstLastCardExiledWith.MkAgainstLastCardExiledWith filter_ quantity -> filterNames asking filter_ <> onQuantity quantity

againstSlotNames :: (Monoid r) => Asking r -> (quantity -> r) -> AgainstSlot.AgainstSlot quantity -> r
againstSlotNames asking onQuantity x = case x of
  AgainstSlot.MkAgainstSlot slot quantity -> slotNames asking slot <> onQuantity quantity

aggregationNames :: (Monoid r) => Asking r -> (quantity -> r) -> Aggregation.Aggregation quantity -> r
aggregationNames _asking onQuantity x = case x of
  Aggregation.Members -> mempty
  Aggregation.Distinct _ -> mempty
  Aggregation.MostSharingACreatureType -> mempty
  Aggregation.MostSharingACardType -> mempty
  Aggregation.DistinctNames -> mempty
  Aggregation.Greatest quantity -> onQuantity quantity
  Aggregation.Total quantity -> onQuantity quantity

aloneUnlessNames :: (Monoid r) => Asking r -> AloneUnless.AloneUnless -> r
aloneUnlessNames asking x = case x of
  AloneUnless.MkAloneUnless affected alongside unless _name -> affectedNames asking affected <> foldMap (filterNames asking) alongside <> foldMap (conditionNames asking) unless

aimedAtNames :: (Monoid r) => Asking r -> AimedAt.AimedAt -> r
aimedAtNames asking x = case x of
  AimedAt.MkAimedAt defenders _kinds -> aimedPlayersNames asking defenders

aimedPlayersNames :: (Monoid r) => Asking r -> AimedPlayers.AimedPlayers -> r
aimedPlayersNames asking x = case x of
  AimedPlayers.Scoped _playerScope -> mempty
  AimedPlayers.EachInSlot slotName -> slotNames asking slotName
  AimedPlayers.BoundPlayer _playerId -> mempty

alternativeActivationCostNames :: (Monoid r) => Asking r -> AlternativeActivationCost.AlternativeActivationCost -> r
alternativeActivationCostNames asking x = case x of
  AlternativeActivationCost.MkAlternativeActivationCost grantedBy onlyFirst _cost -> keywordDesignatorNames asking grantedBy <> foldMap (\scope -> history asking HistoryRead.Activations <> turnScopeNames asking scope) onlyFirst

alternativeCostNames :: (Monoid r) => Asking r -> AlternativeCost.AlternativeCost -> r
alternativeCostNames asking x = case x of
  AlternativeCost.MkAlternativeCost condition cost -> foldMap (conditionNames asking) condition <> costNames asking (keywordNames asking) cost

amassNames :: (Monoid r) => Asking r -> Amass.Amass -> r
amassNames asking x = case x of
  Amass.MkAmass quantity _subtype slot -> quantityNames asking quantity <> foldMap (slotNames asking) slot

anyNumberDiscardNames :: (Monoid r) => Asking r -> AnyNumberDiscard.AnyNumberDiscard -> r
anyNumberDiscardNames asking x = case x of
  AnyNumberDiscard.MkAnyNumberDiscard player cards discarded -> playerRefNames asking player <> anyNumberMatchingNames asking cards <> foldMap (slotNames asking) discarded

anyNumberMatchingNames :: (Monoid r) => Asking r -> AnyNumberMatching.AnyNumberMatching -> r
anyNumberMatchingNames asking x = case x of
  AnyNumberMatching.MkAnyNumberMatching filter_ atMost -> filterNames asking filter_ <> foldMap (quantityNames asking) atMost

arithmeticNames :: (Monoid r) => Asking r -> (quantity -> r) -> Arithmetic.Arithmetic quantity -> r
arithmeticNames asking onQuantity x = case x of
  Arithmetic.Plus plus -> plusNames asking onQuantity plus
  Arithmetic.Quotient quotient -> quotientNames asking onQuantity quotient
  Arithmetic.Times times -> timesNames asking onQuantity times
  Arithmetic.Negate quantity -> onQuantity quantity

armDelayedTriggerNames :: (Monoid r) => Asking r -> (ability -> r) -> ArmDelayedTrigger.ArmDelayedTrigger ability -> r
armDelayedTriggerNames asking onAbility x = case x of
  ArmDelayedTrigger.MkArmDelayedTrigger _name onset duration ability -> onsetNames asking onset <> foldMap (durationNames asking) duration <> foldMap onAbility ability

onsetNames :: (Monoid r) => Asking r -> Onset.Onset -> r
onsetNames asking x = case x of
  Onset.Immediately -> mempty
  Onset.FromNextTurnOf playerRef -> playerRefNames asking playerRef
  Onset.FromThatExtraTurn -> mempty

asCopyNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> AsCopy.AsCopy ability effect -> r
asCopyNames asking onAbility onEffect x = case x of
  AsCopy.MkAsCopy eligible clauses _tapped whenYouDo _among duration _recipient _optional -> filterNames asking eligible <> foldMap (copyClauseNames asking onAbility) clauses <> foldMap onEffect whenYouDo <> foldMap (durationNames asking) duration

attachAllNames :: (Monoid r) => Asking r -> AttachAll.AttachAll -> r
attachAllNames asking x = case x of
  AttachAll.MkAttachAll subjects destination -> objectRefNames asking subjects <> filterNames asking destination

attachBoundNames :: (Monoid r) => Asking r -> AttachBound.AttachBound -> r
attachBoundNames asking x = case x of
  AttachBound.MkAttachBound subject destination -> slotNames asking subject <> slotNames asking destination

attachRestrictionNames :: (Monoid r) => Asking r -> AttachRestriction.AttachRestriction -> r
attachRestrictionNames asking x = case x of
  AttachRestriction.MkAttachRestriction affected attachers -> affectedNames asking affected <> filterNames asking attachers

attachTargetNames :: (Monoid r) => Asking r -> AttachTarget.AttachTarget -> r
attachTargetNames asking x = case x of
  AttachTarget.MkAttachTarget slot filter_ -> slotNames asking slot <> filterNames asking filter_

attachedToBoundNames :: (Monoid r) => Asking r -> AttachedToBound.AttachedToBound -> r
attachedToBoundNames asking x = case x of
  AttachedToBound.MkAttachedToBound slot filter_ -> slotNames asking slot <> filterNames asking filter_

attackCostNames :: (Monoid r) => Asking r -> AttackCost.AttackCost -> r
attackCostNames asking x = case x of
  AttackCost.MkAttackCost subject perAttacker _scope -> affectedNames asking subject <> perCreatureNames asking perAttacker

attackLimitUnlessNames :: (Monoid r) => Asking r -> AttackLimitUnless.AttackLimitUnless -> r
attackLimitUnlessNames asking x = case x of
  AttackLimitUnless.MkAttackLimitUnless _limit _defenders unless -> foldMap (conditionNames asking) unless

attackPermissionNames :: (Monoid r) => Asking r -> AttackPermission.AttackPermission -> r
attackPermissionNames asking x = case x of
  AttackPermission.MkAttackPermission affected -> affectedNames asking affected

attackRequirementNames :: (Monoid r) => Asking r -> AttackRequirement.AttackRequirement -> r
attackRequirementNames asking x = case x of
  AttackRequirement.MkAttackRequirement subject _object_ while _arity -> affectedNames asking subject <> foldMap (conditionNames asking) while

attackTargetRefNames :: (Monoid r) => Asking r -> AttackTargetRef.AttackTargetRef -> r
attackTargetRefNames asking x = case x of
  AttackTargetRef.Players playerRef -> playerRefNames asking playerRef
  AttackTargetRef.Permanents objectRef -> objectRefNames asking objectRef

attackingPlayersNames :: Asking r -> AttackingPlayers.AttackingPlayers -> r
attackingPlayersNames asking x = case x of
  AttackingPlayers.MkAttackingPlayers _relation attacked -> slotNames asking attacked

backupNames :: (Monoid r) => Asking r -> (keyword -> r) -> Backup.Backup keyword -> r
backupNames _asking onKeyword x = case x of
  Backup.MkBackup _count printedAbove -> foldMap onKeyword printedAbove

becomeCopyNames :: (Monoid r) => Asking r -> (ability -> r) -> BecomeCopy.BecomeCopy ability -> r
becomeCopyNames asking onAbility x = case x of
  BecomeCopy.MkBecomeCopy original subject duration exceptions _newTargets -> copyOriginalNames asking original <> objectRefNames asking subject <> foldMap (durationNames asking) duration <> foldMap (copyExceptionNames asking onAbility) exceptions

beholdNames :: (Monoid r) => Asking r -> Behold.Behold keyword -> r
beholdNames asking x = case x of
  Behold.MkBehold _count whichObjects -> filterNames asking whichObjects

bindingNames :: (Monoid r) => Asking r -> Binding.Binding -> r
bindingNames asking x = case x of
  Binding.MkBinding targets _amount _modes copy objects _sticker _votes division -> foldMap (foldMap (recipientNames asking)) targets <> foldMap (projectedCharacteristicsNames asking) copy <> names asking (\oid -> any (elem oid) objects) <> foldMap (foldMap (recipientNames asking) . Map.keys) division

blightNames :: (Monoid r) => Asking r -> Blight.Blight -> r
blightNames asking x = case x of
  Blight.MkBlight player quantity slot -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (slotNames asking) slot

blockCostNames :: (Monoid r) => Asking r -> BlockCost.BlockCost -> r
blockCostNames asking x = case x of
  BlockCost.MkBlockCost subject perBlocker attackers -> affectedNames asking subject <> perCreatureNames asking perBlocker <> foldMap (filterNames asking) attackers

blockPermissionNames :: (Monoid r) => Asking r -> BlockPermission.BlockPermission -> r
blockPermissionNames asking x = case x of
  BlockPermission.MkBlockPermission affected additional while -> affectedNames asking affected <> foldMap (quantityNames asking) additional <> foldMap (conditionNames asking) while

blockRequirementNames :: (Monoid r) => Asking r -> BlockRequirement.BlockRequirement -> r
blockRequirementNames asking x = case x of
  BlockRequirement.MkBlockRequirement subject attacker while _arity -> foldMap (affectedNames asking) subject <> foldMap (affectedNames asking) attacker <> foldMap (conditionNames asking) while

boundMeasureNames :: Asking r -> BoundMeasure.BoundMeasure -> r
boundMeasureNames asking x = case x of
  BoundMeasure.MkBoundMeasure slot _measure -> slotNames asking slot

candidateIdNames :: (Monoid r) => Asking r -> CandidateId.CandidateId -> r
candidateIdNames asking x = case x of
  CandidateId.OfPermanent permanentCandidate -> permanentCandidateNames asking permanentCandidate
  CandidateId.OfFloating floatingCandidate -> floatingCandidateNames asking floatingCandidate

cantAttackPlayerNames :: (Monoid r) => Asking r -> CantAttackPlayer.CantAttackPlayer -> r
cantAttackPlayerNames asking x = case x of
  CantAttackPlayer.MkCantAttackPlayer affected _defenders _kinds unless _name -> affectedNames asking affected <> foldMap (conditionNames asking) unless

cantBeBlockedByNames :: (Monoid r) => Asking r -> CantBeBlockedBy.CantBeBlockedBy -> r
cantBeBlockedByNames asking x = case x of
  CantBeBlockedBy.MkCantBeBlockedBy affected blockers unless _name -> affectedNames asking affected <> filterNames asking blockers <> foldMap (conditionNames asking) unless

cantBlockCreaturesNames :: (Monoid r) => Asking r -> CantBlockCreatures.CantBlockCreatures -> r
cantBlockCreaturesNames asking x = case x of
  CantBlockCreatures.MkCantBlockCreatures affected attackers unless _name -> affectedNames asking affected <> filterNames asking attackers <> foldMap (conditionNames asking) unless

-- A printed card, every face of it, and the cards its faces create.
cardNames :: (Monoid r) => Asking r -> Card.Card -> r
cardNames asking x = case x of
  Card.MkCard _layout faces -> foldMap (faceNames asking (cardNames asking)) faces

cardLeavesZoneNames :: (Monoid r) => Asking r -> CardLeavesZone.CardLeavesZone -> r
cardLeavesZoneNames asking x = case x of
  CardLeavesZone.MkCardLeavesZone filter_ scope _from _to _whose -> filterNames asking filter_ <> turnScopeNames asking scope

cardPutIntoGraveyardNames :: (Monoid r) => Asking r -> CardPutIntoGraveyard.CardPutIntoGraveyard -> r
cardPutIntoGraveyardNames asking x = case x of
  CardPutIntoGraveyard.MkCardPutIntoGraveyard filter_ _from -> filterNames asking filter_

cardsPutIntoZoneNames :: (Monoid r) => Asking r -> CardsPutIntoZone.CardsPutIntoZone -> r
cardsPutIntoZoneNames asking x = case x of
  CardsPutIntoZone.MkCardsPutIntoZone filter_ scope _from _to -> filterNames asking filter_ <> turnScopeNames asking scope

castFromNames :: (Monoid r) => Asking r -> CastFrom.CastFrom -> r
castFromNames asking x = case x of
  CastFrom.MkCastFrom caster from -> playerRefNames asking caster <> inZoneNames asking from

castFromZoneNames :: (Monoid r) => Asking r -> CastFromZone.CastFromZone -> r
castFromZoneNames asking x = case x of
  CastFromZone.MkCastFromZone from matching _limit _verb _pool additionalCosts _reduction -> inZoneNames asking from <> filterNames asking matching <> foldMap (costComponentNames asking (keywordNames asking)) additionalCosts

castOfferNames :: (Monoid r) => Asking r -> CastOffer.CastOffer -> r
castOfferNames asking x = case x of
  CastOffer.MkCastOffer _transformed _withoutPayingManaCost payingInstead _spending restriction offeredBy _faceDown _payableFromSpent _reduction -> foldMap (costNames asking (keywordNames asking)) payingInstead <> foldMap (filterNames asking) restriction <> foldMap (keywordNames asking) offeredBy

castRepetitionNames :: (Monoid r) => Asking r -> CastRepetition.CastRepetition -> r
castRepetitionNames asking x = case x of
  CastRepetition.Once -> mempty
  CastRepetition.AnyNumber -> mempty
  CastRepetition.WithinTotalManaValue quantity -> quantityNames asking quantity

castingRestrictionNames :: (Monoid r) => Asking r -> CastingRestriction.CastingRestriction -> r
castingRestrictionNames asking x = case x of
  CastingRestriction.DuringPhase duringPhase -> duringPhaseNames asking duringPhase
  CastingRestriction.AttackedThisStep -> mempty
  CastingRestriction.AfterBlockersDeclared -> mempty
  CastingRestriction.BeforeStep _phase -> history asking HistoryRead.StepBegins
  CastingRestriction.DuringTurn turnScope -> turnScopeNames asking turnScope
  CastingRestriction.NotDuringFirstTurns _turns -> mempty
  CastingRestriction.OnlyIf condition -> conditionNames asking condition
  CastingRestriction.SpendOnlyOnX _color -> mempty

changeTextNames :: (Monoid r) => Asking r -> ChangeText.ChangeText -> r
changeTextNames asking x = case x of
  ChangeText.MkChangeText _families _forbidden slot duration -> slotNames asking slot <> durationNames asking duration

characteristicPTNames :: (Monoid r) => Asking r -> CharacteristicPT.CharacteristicPT -> r
characteristicPTNames asking x = case x of
  CharacteristicPT.MkCharacteristicPT power toughness -> quantityNames asking power <> quantityNames asking toughness

chooseCardNameNames :: (Monoid r) => Asking r -> ChooseCardName.ChooseCardName -> r
chooseCardNameNames asking x = case x of
  ChooseCardName.MkChooseCardName player restriction -> playerRefNames asking player <> filterNames asking restriction

bindAmountNames :: (Monoid r) => Asking r -> BindAmount.BindAmount -> r
bindAmountNames asking x = case x of
  BindAmount.MkBindAmount quantity slot -> quantityNames asking quantity <> slotNames asking slot

chooseNumberNames :: (Monoid r) => Asking r -> ChooseNumber.ChooseNumber -> r
chooseNumberNames asking x = case x of
  ChooseNumber.MkChooseNumber slot _upTo chooser -> slotNames asking slot <> playerRefNames asking chooser

choosePermanentsNames :: (Monoid r) => Asking r -> ChoosePermanents.ChoosePermanents -> r
choosePermanentsNames asking x = case x of
  ChoosePermanents.MkChoosePermanents permanents slot pileChooser -> chosenPermanentsNames asking permanents <> slotNames asking slot <> foldMap (playerRefNames asking) pileChooser

choosePlayerNames :: Asking r -> ChoosePlayer.ChoosePlayer -> r
choosePlayerNames asking x = case x of
  ChoosePlayer.MkChoosePlayer _scope slot -> slotNames asking slot

choosePlayerAtRandomNames :: Asking r -> ChoosePlayerAtRandom.ChoosePlayerAtRandom -> r
choosePlayerAtRandomNames asking x = case x of
  ChoosePlayerAtRandom.MkChoosePlayerAtRandom _scope slot -> slotNames asking slot

chooserNames :: (Monoid r) => Asking r -> Chooser.Chooser -> r
chooserNames asking x = case x of
  Chooser.TheController -> mempty
  Chooser.EachInScope -> mempty
  Chooser.BoundInSlot slotName -> slotNames asking slotName

chosenCardFromAmongNames :: (Monoid r) => Asking r -> ChosenCardFromAmong.ChosenCardFromAmong -> r
chosenCardFromAmongNames asking x = case x of
  ChosenCardFromAmong.MkChosenCardFromAmong slot filter_ count chooser pileChooser -> slotNames asking slot <> filterNames asking filter_ <> foldMap (quantityNames asking) (HowMany.quantity count) <> playerRefNames asking chooser <> foldMap (playerRefNames asking) pileChooser

chosenCardInGraveyardNames :: (Monoid r) => Asking r -> ChosenCardInGraveyard.ChosenCardInGraveyard -> r
chosenCardInGraveyardNames asking x = case x of
  ChosenCardInGraveyard.MkChosenCardInGraveyard chooser players filter_ count -> chooserNames asking chooser <> zoneScopeNames asking players <> filterNames asking filter_ <> quantityNames asking count

chosenCardInHandNames :: (Monoid r) => Asking r -> ChosenCardInHand.ChosenCardInHand -> r
chosenCardInHandNames asking x = case x of
  ChosenCardInHand.MkChosenCardInHand player filter_ count -> playerRefNames asking player <> filterNames asking filter_ <> quantityNames asking count

chosenPermanentsNames :: (Monoid r) => Asking r -> ChosenPermanents.ChosenPermanents -> r
chosenPermanentsNames asking x = case x of
  ChosenPermanents.MkChosenPermanents filter_ chooser count _zone -> filterNames asking filter_ <> playerRefNames asking chooser <> foldMap (quantityNames asking) (HowMany.quantity count)

clauseNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> Clause.Clause card ability -> r
clauseNames asking onCard onAbility x = case x of
  Clause.MkClause _ifTaken condition orElse optionality payGate effects -> foldMap (conditionNames asking) condition <> foldMap (orElseNames asking) orElse <> optionalityNames asking optionality <> foldMap (payGateNames asking) payGate <> foldMap (effectNames asking onCard onAbility) effects

combatRestrictionNames :: (Monoid r) => Asking r -> CombatRestriction.CombatRestriction -> r
combatRestrictionNames asking x = case x of
  CombatRestriction.CantAttack affectedUnless -> affectedUnlessNames asking affectedUnless
  CombatRestriction.CantBlock affectedUnless -> affectedUnlessNames asking affectedUnless
  CombatRestriction.CantBeBlockedBy cantBeBlockedBy -> cantBeBlockedByNames asking cantBeBlockedBy
  CombatRestriction.CantBlockCreatures cantBlockCreatures -> cantBlockCreaturesNames asking cantBlockCreatures
  CombatRestriction.CantAttackPlayer cantAttackPlayer -> cantAttackPlayerNames asking cantAttackPlayer
  CombatRestriction.CantAttackAlone aloneUnless -> aloneUnlessNames asking aloneUnless
  CombatRestriction.CantBlockAlone aloneUnless -> aloneUnlessNames asking aloneUnless
  CombatRestriction.CantAttackMoreThan attackLimitUnless -> attackLimitUnlessNames asking attackLimitUnless
  CombatRestriction.CantBlockMoreThan limitUnless -> limitUnlessNames asking limitUnless

comparesNames :: (Monoid r) => Asking r -> Compares.Compares -> r
comparesNames asking x = case x of
  Compares.MkCompares measured _comparison threshold -> quantityNames asking measured <> quantityNames asking threshold

completedDungeonNames :: (Monoid r) => Asking r -> CompletedDungeon.CompletedDungeon -> r
completedDungeonNames asking x = case x of
  CompletedDungeon.MkCompletedDungeon player _dungeon -> playerRefNames asking player

conditionNames :: (Monoid r) => Asking r -> Condition.Condition -> r
conditionNames asking x = case x of
  Condition.Compares compares -> comparesNames asking compares
  Condition.Any items -> foldMap (conditionNames asking) items
  Condition.All items -> foldMap (conditionNames asking) items
  Condition.During duringPhase -> duringPhaseNames asking duringPhase

conjureNames :: (Monoid r) => Asking r -> (card -> r) -> Conjure.Conjure card -> r
conjureNames asking onCard x = case x of
  Conjure.MkConjure quantity cards _selection _destination slot -> quantityNames asking quantity <> conjureCardsNames asking onCard cards <> foldMap (slotNames asking) slot

conjureCardsNames :: (Monoid r) => Asking r -> (card -> r) -> ConjureCards.ConjureCards card -> r
conjureCardsNames asking onCard x = case x of
  ConjureCards.Written nonEmpty -> foldMap onCard nonEmpty
  ConjureCards.Duplicate objectRef -> objectRefNames asking objectRef
  ConjureCards.Reference fromReference -> fromReferenceNames asking fromReference

conniveNames :: (Monoid r) => Asking r -> Connive.Connive -> r
conniveNames asking x = case x of
  Connive.MkConnive quantity ref -> quantityNames asking quantity <> objectRefNames asking ref

controlPlayerNames :: Asking r -> ControlPlayer.ControlPlayer -> r
controlPlayerNames asking x = case x of
  ControlPlayer.MkControlPlayer slot _manaFromLandsOnly -> slotNames asking slot

controlSidesNames :: (Monoid r) => Asking r -> ControlSides.ControlSides -> r
controlSidesNames asking x = case x of
  ControlSides.WithinSlot slotName -> slotNames asking slotName
  ControlSides.WithSource slotName -> slotNames asking slotName
  ControlSides.BetweenSlots (ControlSlots.MkControlSlots one two) -> slotNames asking one <> slotNames asking two

controllerRelationNames :: (Monoid r) => Asking r -> ControllerRelation.ControllerRelation -> r
controllerRelationNames asking x = case x of
  ControllerRelation.Related _ -> mempty
  ControllerRelation.EnchantedPlayers -> mempty
  ControllerRelation.InSlot slotName -> slotNames asking slotName
  ControllerRelation.Among _playerId -> mempty

copyClauseNames :: (Monoid r) => Asking r -> (ability -> r) -> CopyClause.CopyClause ability -> r
copyClauseNames asking onAbility x = case x of
  CopyClause.MkCopyClause condition exceptions counters -> foldMap (conditionNames asking) condition <> foldMap (copyExceptionNames asking onAbility) exceptions <> foldMap (withCountersNames asking) counters

copyExceptionNames :: (Monoid r) => Asking r -> (ability -> r) -> CopyException.CopyException ability -> r
copyExceptionNames asking onAbility x = case x of
  CopyException.SetPowerToughness _setPowerToughness -> mempty
  CopyException.GainKeywords keyword -> foldMap (keywordNames asking) keyword
  CopyException.GainThisAbility -> mempty
  CopyException.CardTypes _mode _cardType -> mempty
  CopyException.AddSubtypes _subtype -> mempty
  CopyException.AddSupertypes _supertype -> mempty
  CopyException.SetCreatureSubtypes _subtype -> mempty
  CopyException.RemoveSupertypes _supertype -> mempty
  CopyException.SetName _cardName -> mempty
  CopyException.SetColors _color -> mempty
  CopyException.NoManaCost -> mempty
  CopyException.GainAbility ability -> onAbility ability
  CopyException.DontCopyColors -> mempty

copyOriginalNames :: (Monoid r) => Asking r -> CopyOriginal.CopyOriginal -> r
copyOriginalNames asking x = case x of
  CopyOriginal.OfObject objectRef -> objectRefNames asking objectRef
  CopyOriginal.Named _cardName -> mempty

copyStackObjectNames :: (Monoid r) => Asking r -> (ability -> r) -> CopyStackObject.CopyStackObject ability -> r
copyStackObjectNames asking onAbility x = case x of
  CopyStackObject.MkCopyStackObject ref targets quantity copier exceptions -> objectRefNames asking ref <> copyTargetsNames asking targets <> quantityNames asking quantity <> playerRefNames asking copier <> foldMap (copyExceptionNames asking onAbility) exceptions

copyTargetsNames :: (Monoid r) => Asking r -> CopyTargets.CopyTargets -> r
copyTargetsNames asking x = case x of
  CopyTargets.Copied -> mempty
  CopyTargets.ChosenByController -> mempty
  CopyTargets.ForEach objectRef -> foldMap (objectRefNames asking) objectRef
  CopyTargets.Stated objectRef -> objectRefNames asking objectRef

costNames :: (Monoid r) => Asking r -> (keyword -> r) -> Cost.Cost keyword -> r
costNames asking onKeyword x = case x of
  Cost.MkCost _mana components -> foldMap (costComponentNames asking onKeyword) components

costBasisNames :: Asking r -> CostBasis.CostBasis -> r
costBasisNames asking x = case x of
  CostBasis.MkCostBasis slot _reducedBy -> slotNames asking slot

costChoiceNames :: (Monoid r) => Asking r -> CostChoice.CostChoice -> r
costChoiceNames asking x = case x of
  CostChoice.MkCostChoice unwrap -> foldMap (costNames asking (keywordNames asking)) unwrap

costComponentNames :: (Monoid r) => Asking r -> (keyword -> r) -> CostComponent.CostComponent keyword -> r
costComponentNames asking onKeyword x = case x of
  CostComponent.TapThis -> mempty
  CostComponent.UntapThis -> mempty
  CostComponent.SacrificeThis -> mempty
  CostComponent.ReturnThis -> mempty
  CostComponent.PayLife amount -> costAmountNames asking amount
  CostComponent.PayHalfLife _rounding -> mempty
  CostComponent.Sacrifice sacrifice -> sacrificeNames asking sacrifice
  CostComponent.TapForTotalPower tapForTotalPower -> tapForTotalPowerNames asking tapForTotalPower
  CostComponent.TapPermanents tapPermanents -> tapPermanentsNames asking tapPermanents
  CostComponent.ReturnPermanents returnPermanents -> returnPermanentsNames asking returnPermanents
  CostComponent.ExilePermanents exilePermanents -> exilePermanentsNames asking exilePermanents
  CostComponent.DiscardCards discardCards -> discardCardsNames asking discardCards
  CostComponent.DiscardThis _discardCause -> mempty
  CostComponent.PutCardFromHandOntoBattlefield filter_ -> filterNames asking filter_
  CostComponent.PayEnergy amount -> costAmountNames asking amount
  CostComponent.AddLoyaltyToThis _natural -> history asking HistoryRead.LoyaltyActivations
  CostComponent.RemoveLoyaltyFromThis amount -> history asking HistoryRead.LoyaltyActivations <> costAmountNames asking amount
  CostComponent.RemoveCountersFromThis countersOnThis -> countersOnThisNames asking onKeyword countersOnThis
  CostComponent.RemoveCounters countersFromPermanents -> countersFromPermanentsNames asking onKeyword countersFromPermanents
  CostComponent.PutCountersOnThis countersOnThis -> countersOnThisNames asking onKeyword countersOnThis
  CostComponent.Blight amount -> costAmountNames asking amount
  CostComponent.Forage -> mempty
  CostComponent.FlipCoin -> mempty
  CostComponent.ExileThisFromGraveyard -> mempty
  CostComponent.ExileThis -> mempty
  CostComponent.ExileCardsFromGraveyard exileCardsFromGraveyard -> exileCardsFromGraveyardNames asking exileCardsFromGraveyard
  CostComponent.ExileMaterials exileMaterials -> exileMaterialsNames asking exileMaterials
  CostComponent.ExileTopFromGraveyard filter_ -> filterNames asking filter_
  CostComponent.CollectEvidence _natural -> mempty
  CostComponent.CollectEvidenceOfTargets -> mempty
  CostComponent.ExileCardsFromHand exileCardsFromHand -> exileCardsFromHandNames asking exileCardsFromHand
  CostComponent.RevealCardFromHand filter_ -> filterNames asking filter_
  CostComponent.Behold behold -> beholdNames asking behold
  CostComponent.BeholdAndExile filter_ -> filterNames asking filter_
  CostComponent.MillCards _natural -> mempty
  CostComponent.RevealTopOfLibrary _natural -> mempty
  CostComponent.ChooseOpponent _ -> mempty
  CostComponent.Waterbend amount -> costAmountNames asking amount
  CostComponent.WaterbendInstead _natural -> mempty

objectCountNames :: (Monoid r) => Asking r -> ObjectCount.ObjectCount -> r
objectCountNames asking x = case x of
  ObjectCount.Exactly amount -> costAmountNames asking amount
  ObjectCount.Every -> mempty

costAmountNames :: (Monoid r) => Asking r -> CostAmount.CostAmount -> r
costAmountNames asking x = case x of
  CostAmount.Fixed _natural -> mempty
  CostAmount.Announced slot -> slotNames asking slot

costReductionNames :: (Monoid r) => Asking r -> CostReduction.CostReduction -> r
costReductionNames asking x = case x of
  CostReduction.MkCostReduction _amount perEach condition whichTargets _direction -> quantityNames asking perEach <> foldMap (conditionNames asking) condition <> foldMap (filterNames asking) whichTargets

countNames :: (Monoid r) => Asking r -> (quantity -> r) -> Count.Count quantity -> r
countNames asking onQuantity x = case x of
  Count.MkCount scope filter_ aggregation -> scopeNames asking scope <> filterNames asking filter_ <> aggregationNames asking onQuantity aggregation

countedDiscardNames :: (Monoid r) => Asking r -> CountedDiscard.CountedDiscard -> r
countedDiscardNames asking x = case x of
  CountedDiscard.MkCountedDiscard player quantity discarded -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (slotNames asking) discarded

counterNames :: (Monoid r) => Asking r -> Counter.Counter -> r
counterNames asking x = case x of
  Counter.MkCounter ref slot sources instead -> objectRefNames asking ref <> foldMap (slotNames asking) slot <> foldMap (slotNames asking) sources <> foldMap (counterDestinationNames asking) instead

counterDestinationNames :: (Monoid r) => Asking r -> CounterDestination.CounterDestination -> r
counterDestinationNames asking x = case x of
  CounterDestination.MkCounterDestination _zone _position only slot -> foldMap (filterNames asking) only <> foldMap (slotNames asking) slot

counterKindNames :: (Monoid r) => Asking r -> (keyword -> r) -> CounterKind.CounterKind keyword -> r
counterKindNames _asking onKeyword x = case x of
  CounterKind.PlusOnePlusOne -> mempty
  CounterKind.MinusOneMinusOne -> mempty
  CounterKind.Keyword keyword -> onKeyword keyword
  CounterKind.Loyalty -> mempty
  CounterKind.Lore -> mempty
  CounterKind.Defense -> mempty
  CounterKind.Time -> mempty
  CounterKind.Fade -> mempty
  CounterKind.Age -> mempty
  CounterKind.Shield -> mempty
  CounterKind.Finality -> mempty
  CounterKind.Stun -> mempty
  CounterKind.Level -> mempty
  CounterKind.Hone -> mempty
  CounterKind.UnsafePowerToughness _ _ -> mempty
  CounterKind.Named _counterName -> mempty

counterPatternNames :: (Monoid r) => Asking r -> CounterPattern.CounterPattern -> r
counterPatternNames asking x = case x of
  CounterPattern.MkCounterPattern whichKind subject whose onWhat onWho -> foldMap (counterKindNames asking (keywordNames asking)) whichKind <> counterSubjectNames asking subject <> controllerRelationNames asking whose <> filterNames asking onWhat <> foldMap (controllerRelationNames asking) onWho

counterPlacementNames :: (Monoid r) => Asking r -> CounterPlacement.CounterPlacement -> r
counterPlacementNames asking x = case x of
  CounterPlacement.MkCounterPlacement kind permanents -> counterKindNames asking (keywordNames asking) kind <> filterNames asking permanents

counterRNames :: (Monoid r) => Asking r -> CounterR.CounterR -> r
counterRNames asking x = case x of
  CounterR.MkCounterR matching _scaling -> counterPatternNames asking matching

counterRestrictionNames :: (Monoid r) => Asking r -> CounterRestriction.CounterRestriction -> r
counterRestrictionNames asking x = case x of
  CounterRestriction.MkCounterRestriction affected kind -> affectedNames asking affected <> foldMap (counterKindNames asking (keywordNames asking)) kind

counterSubjectNames :: (Monoid r) => Asking r -> CounterSubject.CounterSubject -> r
counterSubjectNames asking x = case x of
  CounterSubject.ByEffect -> mempty
  CounterSubject.ByPlayer controllerRelation -> controllerRelationNames asking controllerRelation
  CounterSubject.ByAnything -> mempty

countersFromPermanentsNames :: (Monoid r) => Asking r -> (keyword -> r) -> CountersFromPermanents.CountersFromPermanents keyword -> r
countersFromPermanentsNames asking onKeyword x = case x of
  CountersFromPermanents.MkCountersFromPermanents count kind whichPermanent _spread -> costAmountNames asking count <> whichCountersNames asking onKeyword kind <> filterNames asking whichPermanent

countersOnThisNames :: (Monoid r) => Asking r -> (keyword -> r) -> CountersOnThis.CountersOnThis keyword -> r
countersOnThisNames asking onKeyword x = case x of
  CountersOnThis.MkCountersOnThis kind _count -> counterKindNames asking onKeyword kind

craftNames :: (Monoid r) => Asking r -> (keyword -> r) -> Craft.Craft keyword -> r
craftNames asking onKeyword x = case x of
  Craft.MkCraft cost materials -> costNames asking onKeyword cost <> exileMaterialsNames asking materials

createNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> Create.Create card ability -> r
createNames asking onCard onAbility x = case x of
  Create.MkCreate quantity card riders slot creator -> quantityNames asking quantity <> onCard card <> entryRidersNames asking (quantityNames asking) onAbility riders <> foldMap (slotNames asking) slot <> playerRefNames asking creator

createEmblemNames :: (Monoid r) => Asking r -> (card -> r) -> CreateEmblem.CreateEmblem card -> r
createEmblemNames asking onCard x = case x of
  CreateEmblem.MkCreateEmblem card player -> onCard card <> playerRefNames asking player

createCopyNames :: (Monoid r) => Asking r -> (ability -> r) -> CreateCopy.CreateCopy ability -> r
createCopyNames asking onAbility x = case x of
  CreateCopy.MkCreateCopy quantity ref riders slot exceptions -> quantityNames asking quantity <> objectRefNames asking ref <> entryRidersNames asking (quantityNames asking) onAbility riders <> foldMap (slotNames asking) slot <> foldMap (copyExceptionNames asking onAbility) exceptions

creatureExploitsNames :: (Monoid r) => Asking r -> CreatureExploits.CreatureExploits -> r
creatureExploitsNames asking x = case x of
  CreatureExploits.MkCreatureExploits exploiter exploited -> filterNames asking exploiter <> filterNames asking exploited

counterProhibitionNames :: (Monoid r) => Asking r -> CounterProhibition.CounterProhibition -> r
counterProhibitionNames asking x = case x of
  CounterProhibition.MkCounterProhibition countered counterers -> filterNames asking countered <> filterNames asking counterers

crewRestrictionNames :: (Monoid r) => Asking r -> CrewRestriction.CrewRestriction -> r
crewRestrictionNames asking x = case x of
  CrewRestriction.MkCrewRestriction affected -> affectedNames asking affected

targetRestrictionNames :: (Monoid r) => Asking r -> (affected -> r) -> TargetRestriction.TargetRestriction affected -> r
targetRestrictionNames asking onAffected x = case x of
  TargetRestriction.MkTargetRestriction affected _kind aimers -> onAffected affected <> filterNames asking aimers

cyclingNames :: (Monoid r) => Asking r -> (keyword -> r) -> Cycling.Cycling keyword -> r
cyclingNames asking onKeyword x = case x of
  Cycling.MkCycling cost searchFor -> costNames asking onKeyword cost <> foldMap (filterNames asking) searchFor

damagePartNames :: (Monoid r) => Asking r -> DamagePart.DamagePart -> r
damagePartNames asking x = case x of
  DamagePart.MkDamagePart ref quantity -> objectRefNames asking ref <> quantityNames asking quantity

damagePatternNames :: (Monoid r) => Asking r -> DamagePattern.DamagePattern -> r
damagePatternNames asking x = case x of
  DamagePattern.MkDamagePattern _whichKind whatSource whatRecipient _whoRecipient whichRecipient whichSource boundRecipient -> filterNames asking whatSource <> foldMap (filterNames asking) whatRecipient <> foldMap (recipientNames asking) whichRecipient <> names asking (`elem` whichSource) <> foldMap (slotNames asking) boundRecipient

damageRNames :: (Monoid r) => Asking r -> (effect -> r) -> DamageR.DamageR effect -> r
damageRNames asking onEffect x = case x of
  DamageR.MkDamageR matching rewrite riders -> damagePatternNames asking matching <> damageRewriteNames asking onEffect rewrite <> foldMap onEffect riders

damageRewriteNames :: (Monoid r) => Asking r -> (effect -> r) -> DamageRewrite.DamageRewrite effect -> r
damageRewriteNames asking onEffect x = case x of
  DamageRewrite.PreventAll -> mempty
  DamageRewrite.PreventRemovingShieldCounter -> mempty
  DamageRewrite.PreventNext _natural -> mempty
  DamageRewrite.PreventAllBut _natural -> mempty
  DamageRewrite.PreventUpTo _natural -> mempty
  DamageRewrite.SetAmount _natural -> mempty
  DamageRewrite.Scale _scaling -> mempty
  DamageRewrite.Redirect recipient -> recipientNames asking recipient
  DamageRewrite.RedirectNext _natural recipient -> recipientNames asking recipient
  DamageRewrite.RedirectMatching filter_ -> filterNames asking filter_
  DamageRewrite.RunEffects seq_ -> foldMap onEffect seq_
  DamageRewrite.TurnFaceUp -> mempty

dealDamageNames :: (Monoid r) => Asking r -> DealDamage.DealDamage -> r
dealDamageNames asking x = case x of
  DealDamage.MkDealDamage parts dealer _excess tally damaged -> foldMap (damagePartNames asking) parts <> foldMap (slotNames asking) dealer <> foldMap (slotNames asking) tally <> foldMap (slotNames asking) damaged

delayedTriggerNames :: (Monoid r) => Asking r -> DelayedTrigger.DelayedTrigger -> r
delayedTriggerNames asking x = case x of
  DelayedTrigger.MkDelayedTrigger ability source _controller bindings _window expiry _createdAt -> triggeredAbilityNames asking (const mempty) (grantedAbilityNames asking (const mempty)) ability <> names asking (== source) <> foldMap (slotNames asking) (Map.keys bindings) <> foldMap (bindingNames asking) bindings <> foldMap (expiryNames asking) expiry

designateNames :: (Monoid r) => Asking r -> Designate.Designate -> r
designateNames asking x = case x of
  Designate.MkDesignate _designation slot value -> slotNames asking slot <> foldMap (quantityNames asking) value

destroyNames :: (Monoid r) => Asking r -> Destroy.Destroy -> r
destroyNames asking x = case x of
  Destroy.MkDestroy ref _regenerability slot buried permanents -> objectRefNames asking ref <> foldMap (slotNames asking) slot <> foldMap (slotNames asking) buried <> foldMap (slotNames asking) permanents

destructionRNames :: (Monoid r) => Asking r -> DestructionR.DestructionR -> r
destructionRNames asking x = case x of
  DestructionR.MkDestructionR matching _rewrite -> foldMap (filterNames asking) matching

devotionNames :: (Monoid r) => Asking r -> Devotion.Devotion -> r
devotionNames asking x = case x of
  Devotion.MkDevotion player _colors -> playerRefNames asking player

devourNames :: (Monoid r) => Asking r -> Devour.Devour keyword -> r
devourNames asking x = case x of
  Devour.MkDevour quality _count -> foldMap (filterNames asking) quality

permanentActedNames :: Asking r -> (permanent -> r) -> PermanentActed.PermanentActed permanent -> r
permanentActedNames _asking onPermanent x = case x of
  PermanentActed.MkPermanentActed _action permanent -> onPermanent permanent

actingPermanentNames :: (Monoid r) => Asking r -> ActingPermanent.ActingPermanent -> r
actingPermanentNames asking x = case x of
  ActingPermanent.Self -> mempty
  ActingPermanent.Matching filter_ -> filterNames asking filter_

dieResultNames :: Asking r -> (player -> r) -> DieResult.DieResult player -> r
dieResultNames _asking onPlayer x = case x of
  DieResult.MkDieResult roller _result -> onPlayer roller

dieRollRNames :: (Monoid r) => Asking r -> DieRollR.DieRollR -> r
dieRollRNames asking x = case x of
  DieRollR.MkDieRollR whose _rewrite -> controllerRelationNames asking whose

discardNames :: (Monoid r) => Asking r -> Discard.Discard -> r
discardNames asking x = case x of
  Discard.Counted countedDiscard -> countedDiscardNames asking countedDiscard
  Discard.These theseDiscard -> theseDiscardNames asking theseDiscard
  Discard.AnyNumber anyNumberDiscard -> anyNumberDiscardNames asking anyNumberDiscard

divideNames :: (Monoid r) => Asking r -> Divide.Divide -> r
divideNames asking x = case x of
  Divide.MkDivide quantity among chooser slot -> quantityNames asking quantity <> objectRefNames asking among <> playerRefNames asking chooser <> slotNames asking slot

discardCardsNames :: (Monoid r) => Asking r -> DiscardCards.DiscardCards keyword -> r
discardCardsNames asking x = case x of
  DiscardCards.MkDiscardCards _count whichCards -> filterNames asking whichCards

doesNotUntapNextNames :: (Monoid r) => Asking r -> DoesNotUntapNext.DoesNotUntapNext -> r
doesNotUntapNextNames asking x = case x of
  DoesNotUntapNext.MkDoesNotUntapNext ref _steps -> objectRefNames asking ref

drawNames :: (Monoid r) => Asking r -> Draw.Draw -> r
drawNames asking x = case x of
  Draw.MkDraw player quantity slot -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (slotNames asking) slot

drawCountRNames :: (Monoid r) => Asking r -> DrawCountR.DrawCountR -> r
drawCountRNames asking x = case x of
  DrawCountR.MkDrawCountR whose _atLeast _rewrite -> controllerRelationNames asking whose

drawRNames :: (Monoid r) => Asking r -> DrawR.DrawR -> r
drawRNames asking x = case x of
  DrawR.MkDrawR whose rewrite -> controllerRelationNames asking whose <> drawRewriteNames asking rewrite

drawRewriteNames :: (Monoid r) => Asking r -> DrawRewrite.DrawRewrite -> r
drawRewriteNames asking x = case x of
  DrawRewrite.GainLife _natural -> mempty
  DrawRewrite.FromOutsideTheGame fromOutsideTheGame -> fromOutsideTheGameNames asking fromOutsideTheGame
  DrawRewrite.Dredge _natural -> mempty
  DrawRewrite.YouDraw -> mempty
  DrawRewrite.OthersMayPayLife _natural -> mempty
  DrawRewrite.FromGraveyardOrLose -> mempty
  DrawRewrite.RevealUntilChosenKind -> mempty

dungeonRoomNames :: (Monoid r) => Asking r -> (card -> r) -> DungeonRoom.DungeonRoom card -> r
dungeonRoomNames asking onCard x = case x of
  DungeonRoom.MkDungeonRoom _name ability _exits -> modalNames asking onCard (grantedAbilityNames asking onCard) ability

durationNames :: (Monoid r) => Asking r -> Duration.Duration -> r
durationNames asking x = case x of
  Duration.UntilEndOfTurn -> mempty
  Duration.Indefinite -> mempty
  Duration.Perpetual -> mempty
  Duration.UntilYourNextTurn -> mempty
  Duration.UntilYourNextStep _ -> mempty
  Duration.UntilEndOfYourNextTurn -> mempty
  Duration.UntilEndOfNextTurnOf playerRef -> playerRefNames asking playerRef
  Duration.DuringNextTurnOf playerRef -> playerRefNames asking playerRef
  Duration.DuringNextUntapStepOf playerRef -> playerRefNames asking playerRef
  Duration.DuringYourNextTurn -> mempty
  Duration.DuringThatExtraTurn -> mempty
  Duration.ForAsLongAs condition -> conditionNames asking condition
  Duration.UntilEndOfCombat -> mempty
  Duration.UntilEndOfCombatOnYourNextTurn -> mempty
  Duration.UntilPaid cost -> costNames asking (keywordNames asking) cost
  Duration.UntilUsed slot -> foldMap (slotNames asking) slot
  Duration.UntilEvent durationEvent -> durationEventNames asking durationEvent

durationEventNames :: (Monoid r) => Asking r -> DurationEvent.DurationEvent -> r
durationEventNames asking x = case x of
  DurationEvent.SourceTurnedFaceDown -> mempty
  DurationEvent.SpellCast filter_ -> filterNames asking filter_
  DurationEvent.Planeswalked -> mempty

eachCardFromAmongNames :: (Monoid r) => Asking r -> EachCardFromAmong.EachCardFromAmong -> r
eachCardFromAmongNames asking x = case x of
  EachCardFromAmong.MkEachCardFromAmong slot filter_ -> slotNames asking slot <> filterNames asking filter_

fromAnywhereNames :: (Monoid r) => Asking r -> FromAnywhere.FromAnywhere -> r
fromAnywhereNames asking x = case x of
  FromAnywhere.MkFromAnywhere slot among -> slotNames asking slot <> foldMap (slotNames asking) among

eachCardInGraveyardNames :: (Monoid r) => Asking r -> EachCardInGraveyard.EachCardInGraveyard -> r
eachCardInGraveyardNames asking x = case x of
  EachCardInGraveyard.MkEachCardInGraveyard graveyards filter_ -> zoneScopeNames asking graveyards <> filterNames asking filter_

eachCardInHandNames :: (Monoid r) => Asking r -> EachCardInHand.EachCardInHand -> r
eachCardInHandNames asking x = case x of
  EachCardInHand.MkEachCardInHand hands filter_ -> zoneScopeNames asking hands <> foldMap (filterNames asking) filter_

earthbendNames :: (Monoid r) => Asking r -> Earthbend.Earthbend -> r
earthbendNames asking x = case x of
  Earthbend.MkEarthbend quantity ref -> quantityNames asking quantity <> objectRefNames asking ref

effectNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> Effect.Effect card ability -> r
effectNames asking onCard onAbility x = case x of
  Effect.DealDamage dealDamage -> dealDamageNames asking dealDamage
  Effect.Fight fight -> fightNames asking fight
  Effect.ModifyTarget modifyTarget -> modifyTargetNames asking onAbility modifyTarget
  Effect.ChangeText changeText -> changeTextNames asking changeText
  Effect.AddMana manaAddition -> manaAdditionNames asking manaAddition
  Effect.ActivateManaAbilities activateManaAbilities -> activateManaAbilitiesNames asking activateManaAbilities
  Effect.MoveMana moveMana -> moveManaNames asking moveMana
  Effect.Search search -> searchNames asking search
  Effect.ExileAllGraveyards -> mempty
  Effect.RestartGame objectRef -> foldMap (objectRefNames asking) objectRef
  Effect.ControlPlayerNextTurn slotName -> slotNames asking slotName
  Effect.ControlPlayerThisResolution controlPlayer -> controlPlayerNames asking controlPlayer
  Effect.Destroy destroy -> destroyNames asking destroy
  Effect.Sacrifice sacrificeEffect -> sacrificeEffectNames asking sacrificeEffect
  Effect.Attach slotName -> slotNames asking slotName
  Effect.AttachAsThoughCreature slotName -> slotNames asking slotName
  Effect.AttachTarget attachTarget -> attachTargetNames asking attachTarget
  Effect.AttachTargetToEach attachTarget -> attachTargetNames asking attachTarget
  Effect.AttachBound attachBound -> attachBoundNames asking attachBound
  Effect.AttachAll attachAll -> attachAllNames asking attachAll
  Effect.Unattach objectRef -> objectRefNames asking objectRef
  Effect.MoveToZone moveToZone -> moveToZoneNames asking onAbility moveToZone
  Effect.Draw draw -> drawNames asking draw
  Effect.Mill mill -> millNames asking mill
  Effect.Reveal reveal -> revealNames asking reveal
  Effect.FromOutsideTheGame fromOutsideTheGame -> fromOutsideTheGameNames asking fromOutsideTheGame
  Effect.ExileThisSpell -> mempty
  Effect.LookAt lookAt -> lookAtNames asking lookAt
  Effect.ArrangeInLibrary (ArrangeInLibrary.MkArrangeInLibrary objectRef chooser) -> objectRefNames asking objectRef <> playerRefNames asking chooser
  Effect.Scry playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.Surveil playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.Fateseal playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.Clash slotName -> slotNames asking slotName
  Effect.AsYouCascade slotName -> slotNames asking slotName
  Effect.Explore objectRef -> objectRefNames asking objectRef
  Effect.Assemble objectRef -> foldMap (objectRefNames asking) objectRef
  Effect.Connive connive -> conniveNames asking connive
  Effect.Discard discard -> discardNames asking discard
  Effect.LoseLife lifeLoss -> lifeLossNames asking lifeLoss
  Effect.GainLife playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.ExchangeLifeTotals exchangeSides -> exchangeSidesNames asking exchangeSides
  Effect.ExchangeValues exchangeValues -> exchangeValuesNames asking exchangeValues
  Effect.ExchangeZones exchangeZones -> exchangeZonesNames asking exchangeZones
  Effect.ExchangeCardZones (ExchangeCardZones.MkExchangeCardZones one other) -> objectRefNames asking one <> objectRefNames asking other
  Effect.SetLifeTotal playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.LoseGame playerRef -> playerRefNames asking playerRef
  Effect.WinGame playerRef -> playerRefNames asking playerRef
  Effect.DrawGame -> mempty
  Effect.RedistributeLifeTotals -> mempty
  Effect.IncreaseSpeed playerQuantity -> playerQuantityNames asking playerQuantity
  Effect.DecreaseSpeed speedDecrease -> speedDecreaseNames asking speedDecrease
  Effect.Create create -> createNames asking onCard onAbility create
  Effect.Conjure conjure -> conjureNames asking onCard conjure
  Effect.CreateCopy createCopy -> createCopyNames asking onAbility createCopy
  Effect.BecomeCopy becomeCopy -> becomeCopyNames asking onAbility becomeCopy
  Effect.CopyStackObject copyStackObject -> copyStackObjectNames asking onAbility copyStackObject
  Effect.Replace replace -> replaceNames asking onCard onAbility (effectNames asking onCard onAbility) replace
  Effect.SkipPhase skipPhase -> skipPhaseNames asking skipPhase
  Effect.PreventNextDamage preventNextDamage -> preventNextDamageNames asking (effectNames asking onCard onAbility) preventNextDamage
  Effect.PreventAllDamage preventAllDamage -> preventAllDamageNames asking (effectNames asking onCard onAbility) preventAllDamage
  Effect.PreventNextDamageInstance preventNextDamageInstance -> preventNextDamageInstanceNames asking (effectNames asking onCard onAbility) preventNextDamageInstance
  Effect.RedirectDamage redirectDamage -> redirectDamageNames asking redirectDamage
  Effect.Counter counter -> counterNames asking counter
  Effect.PutCounters putCounters -> putCountersNames asking putCounters
  Effect.Divide divide -> divideNames asking divide
  Effect.RemoveCounters removeCounters -> removeCountersNames asking removeCounters
  Effect.RemoveCountersAmong removeCountersAmong -> removeCountersAmongNames asking removeCountersAmong
  Effect.MoveCounters moveCounters -> moveCountersNames asking moveCounters
  Effect.PutCountersFrom putCountersFrom -> putCountersFromNames asking putCountersFrom
  Effect.GainPlayerCounters playerCounters -> playerCountersNames asking playerCounters
  Effect.RemovePlayerCounters removal -> removePlayerCountersNames asking removal
  Effect.PayAnyEnergy slotName -> slotNames asking slotName
  Effect.ChooseNumber chooseNumber -> chooseNumberNames asking chooseNumber
  Effect.BindAmount bindAmount -> bindAmountNames asking bindAmount
  Effect.Tap tap -> tapNames asking tap
  Effect.Untap objectRef -> objectRefNames asking objectRef
  Effect.Detain objectRef -> objectRefNames asking objectRef
  Effect.Goad objectRef -> objectRefNames asking objectRef
  Effect.Pair objectRef -> objectRefNames asking objectRef
  Effect.DoesNotUntapNext doesNotUntapNext -> doesNotUntapNextNames asking doesNotUntapNext
  Effect.Transform objectRef -> objectRefNames asking objectRef
  Effect.Convert objectRef -> objectRefNames asking objectRef
  Effect.Flip objectRef -> objectRefNames asking objectRef
  Effect.Meld meld -> meldNames asking onCard meld
  Effect.PhaseOut objectRef -> objectRefNames asking objectRef
  Effect.TurnFaceDown turnFaceDown -> turnFaceDownNames asking onAbility turnFaceDown
  Effect.TurnFaceUp slotName -> slotNames asking slotName
  Effect.RemoveFromCombat objectRef -> objectRefNames asking objectRef
  Effect.BecomesBlocked slotName -> slotNames asking slotName
  Effect.SwitchBlockers slotName -> slotNames asking slotName
  Effect.ExchangeBlocks exchangeBlocks -> exchangeBlocksNames asking exchangeBlocks
  Effect.AddPhases _items -> mempty
  Effect.EndTurn -> mempty
  Effect.EndCombatPhase -> mempty
  Effect.GainControl gainControl -> gainControlNames asking gainControl
  Effect.ExchangeControl controlSides -> controlSidesNames asking controlSides
  Effect.ArmDelayedTrigger armDelayedTrigger -> armDelayedTriggerNames asking onAbility armDelayedTrigger
  Effect.AffectPlayers affectPlayers -> affectPlayersNames asking affectPlayers
  Effect.RequireBlock requireBlock -> requireBlockNames asking requireBlock
  Effect.RequireAttack requireAttack -> requireAttackNames asking requireAttack
  Effect.Prohibit prohibit -> prohibitNames asking prohibit
  Effect.ForbidAttack forbidAttack -> forbidAttackNames asking forbidAttack
  Effect.ForbidBeingBlocked forbidBeingBlocked -> forbidBeingBlockedNames asking forbidBeingBlocked
  Effect.CreateEmblem createEmblem -> createEmblemNames asking onCard createEmblem
  Effect.BecomeMonarch monarchTarget -> monarchTargetNames asking monarchTarget
  Effect.TakeTheInitiative _initiativeTarget -> mempty
  Effect.Designate designate -> designateNames asking designate
  Effect.SetClassLevel setClassLevel -> setClassLevelNames asking setClassLevel
  Effect.Unsuspect objectRef -> objectRefNames asking objectRef
  Effect.SetHalfLocked setHalfLocked -> setHalfLockedNames asking setHalfLocked
  Effect.CounterAndMark counterAndMark -> permanentActedNames asking (slotNames asking) counterAndMark
  Effect.BecomeProtector slotName -> slotNames asking slotName
  Effect.Mentor slotName -> slotNames asking slotName
  Effect.Firebend manaAddition -> manaAdditionNames asking manaAddition
  Effect.Exploit -> mempty
  Effect.GiveGift -> mempty
  Effect.ItBecomes _daytime -> mempty
  Effect.ExileHaunting exileHaunting -> exileHauntingNames asking exileHaunting
  Effect.PlaySubgame slotName -> slotNames asking slotName
  Effect.ChoosePlayer choosePlayer -> choosePlayerNames asking choosePlayer
  Effect.ChoosePlayerAtRandom choosePlayerAtRandom -> choosePlayerAtRandomNames asking choosePlayerAtRandom
  Effect.ChoosePermanents choosePermanents -> choosePermanentsNames asking choosePermanents
  Effect.ChooseSector slot -> slotNames asking slot
  Effect.RollDie rollDie -> rollDieNames asking rollDie
  Effect.Reroll -> mempty
  Effect.RerollStoredResults slotName -> slotNames asking slotName
  Effect.FlipCoin flipCoin -> flipCoinNames asking flipCoin
  Effect.Guess guess -> guessNames asking guess
  Effect.ExileHandThenDraw -> mempty
  Effect.NoteManaSpent -> mempty
  Effect.Proliferate -> mempty
  Effect.ChooseCardName chooseCardName -> chooseCardNameNames asking chooseCardName
  Effect.ChooseQuality _ -> mempty
  Effect.Bolster quantity -> quantityNames asking quantity
  Effect.Amass amass -> amassNames asking amass
  Effect.Blight blight -> blightNames asking blight
  Effect.Earthbend earthbend -> earthbendNames asking earthbend
  Effect.Airbend objectRef -> objectRefNames asking objectRef
  Effect.TemptWithTheRing -> mempty
  Effect.OpenAttraction -> mempty
  Effect.Planeswalk -> mempty
  Effect.ChaosEnsues -> mempty
  Effect.Abandon -> mempty
  Effect.ClaimPrize -> mempty
  Effect.Forage -> mempty
  Effect.Populate -> mempty
  Effect.Learn -> mempty
  Effect.TimeTravel -> mempty
  Effect.Recruit -> mempty
  Effect.Cloak playerRef -> playerRefNames asking playerRef
  Effect.ManifestDread playerRef -> playerRefNames asking playerRef
  Effect.Venture _subtype -> mempty
  Effect.PlayerSacrifices playerSacrifices -> playerSacrificesNames asking playerSacrifices
  Effect.Vote vote -> voteNames asking vote
  Effect.Bid bid -> bidNames asking bid
  Effect.TakeExtraTurn takeExtraTurn -> takeExtraTurnNames asking takeExtraTurn
  Effect.ShuffleIntoLibrary shuffleIntoLibrary -> shuffleIntoLibraryNames asking shuffleIntoLibrary
  Effect.Ante ante -> anteNames asking ante
  Effect.PutSticker putSticker -> putStickerNames asking putSticker
  Effect.SetOwner (SetOwner.MkSetOwner player ref) -> playerRefNames asking player <> objectRefNames asking ref
  Effect.ExchangeOwnership (ExchangeOwnership.MkExchangeOwnership one other) -> objectRefNames asking one <> objectRefNames asking other
  Effect.Shuffle playerRef -> playerRefNames asking playerRef
  Effect.OfferCast offerCast -> offerCastNames asking offerCast
  Effect.OfferNamedCopy _cardName -> mempty
  Effect.OfferNotedCopy castOffer -> castOfferNames asking castOffer
  Effect.GrantPlayFromExile grantPlayFromExile -> grantPlayFromExileNames asking grantPlayFromExile
  Effect.GrantLookAtExiled grantLookAtExiled -> grantLookAtExiledNames asking grantLookAtExiled
  Effect.MakePlotted objectRef -> objectRefNames asking objectRef
  Effect.MakeForetold makeForetold -> makeForetoldNames asking makeForetold
  Effect.MakeWarped objectRef -> objectRefNames asking objectRef
  Effect.ForEach forEach -> forEachNames asking (effectNames asking onCard onAbility) forEach
  Effect.ForEachNumber forEachNumber -> forEachNumberNames asking (effectNames asking onCard onAbility) forEachNumber
  Effect.Repeat repeat_ -> repeatNames asking (effectNames asking onCard onAbility) repeat_
  Effect.RepeatIf repeatIf -> repeatIfNames asking (effectNames asking onCard onAbility) repeatIf
  Effect.Heal objectRef -> objectRefNames asking objectRef
  Effect.ChooseNewTargets objectRef -> objectRefNames asking objectRef
  Effect.ChangeTargets objectRef -> objectRefNames asking objectRef

emergeNames :: (Monoid r) => Asking r -> (keyword -> r) -> Emerge.Emerge keyword -> r
emergeNames asking onKeyword x = case x of
  Emerge.MkEmerge cost quality -> costNames asking onKeyword cost <> foldMap (filterNames asking) quality

entersWithNames :: (Monoid r) => Asking r -> (ability -> r) -> EntersWith.EntersWith ability -> r
entersWithNames asking onAbility x = case x of
  EntersWith.MkEntersWith counters keywords abilities -> foldMap (withCountersNames asking) counters <> foldMap (keywordNames asking) keywords <> foldMap onAbility abilities

entryAttackNames :: (Monoid r) => Asking r -> EntryAttack.EntryAttack -> r
entryAttackNames asking x = case x of
  EntryAttack.Chosen -> mempty
  EntryAttack.SameAs slotName -> slotNames asking slotName
  EntryAttack.UnderPlayer slotName -> slotNames asking slotName

entryBlockNames :: (Monoid r) => Asking r -> EntryBlock.EntryBlock -> r
entryBlockNames asking x = case x of
  EntryBlock.Chosen -> mempty
  EntryBlock.Specified slotName -> slotNames asking slotName

entryHostNames :: (Monoid r) => Asking r -> EntryHost.EntryHost -> r
entryHostNames asking x = case x of
  EntryHost.Specified slotName -> slotNames asking slotName
  EntryHost.Chosen filter_ -> filterNames asking filter_

entryFlipNames :: (Monoid r) => Asking r -> EntryFlip.EntryFlip -> r
entryFlipNames asking x = case x of
  EntryFlip.MkEntryFlip heads tails -> entryOptionNames asking heads <> entryOptionNames asking tails

entryOptionNames :: (Monoid r) => Asking r -> EntryOption.EntryOption -> r
entryOptionNames asking x = case x of
  EntryOption.MkEntryOption _power _toughness keywords _subtypes -> foldMap (keywordNames asking) keywords

entryPriceNames :: (Monoid r) => Asking r -> EntryPrice.EntryPrice -> r
entryPriceNames asking x = case x of
  EntryPrice.PayLife _natural -> mempty
  EntryPrice.Reveal filter_ -> filterNames asking filter_

entryRNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> EntryR.EntryR ability effect -> r
entryRNames asking onAbility onEffect x = case x of
  EntryR.MkEntryR matching rewrite -> filterNames asking matching <> entryRewriteNames asking onAbility onEffect rewrite

entryRestrictionNames :: (Monoid r) => Asking r -> EntryRestriction.EntryRestriction -> r
entryRestrictionNames asking x = case x of
  EntryRestriction.MkEntryRestriction affected _origins -> affectedNames asking affected

entryRewriteNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> EntryRewrite.EntryRewrite ability effect -> r
entryRewriteNames asking onAbility onEffect x = case x of
  EntryRewrite.AsCopy asCopy -> asCopyNames asking onAbility onEffect asCopy
  EntryRewrite.ChoiceOf items -> foldMap (entryOptionNames asking) items
  EntryRewrite.ChoiceByCoinFlip entryFlip -> entryFlipNames asking entryFlip
  EntryRewrite.ChooseQuality _ -> mempty
  EntryRewrite.ChoosePlayer _relation -> mempty
  EntryRewrite.ChooseCardNames filter_ -> filterNames asking filter_
  EntryRewrite.ChooseCardName filter_ -> filterNames asking filter_
  EntryRewrite.WithCounters withCounters -> withCountersNames asking withCounters
  EntryRewrite.EntersWith entersWith -> entersWithNames asking onAbility entersWith
  EntryRewrite.UnderSourceControl -> mempty
  EntryRewrite.SacrificeAnyNumber sacrificeAnyNumber -> sacrificeAnyNumberNames asking sacrificeAnyNumber
  EntryRewrite.SacrificeToEnter sacrificeToEnter -> sacrificeToEnterNames asking sacrificeToEnter
  EntryRewrite.ExileFromGraveyard exileFromGraveyard -> exileFromGraveyardNames asking exileFromGraveyard
  EntryRewrite.EntersAttachedTo filter_ -> filterNames asking filter_
  EntryRewrite.Riot -> mempty
  EntryRewrite.ReadAhead -> mempty
  EntryRewrite.Unleash -> mempty
  EntryRewrite.Sunburst -> mempty
  EntryRewrite.ModularSunburst -> mempty
  EntryRewrite.Bloodthirst _natural -> history asking HistoryRead.Damage
  EntryRewrite.Amplify _natural -> mempty
  EntryRewrite.Tribute _natural -> mempty
  EntryRewrite.Compleated _natural -> mempty
  EntryRewrite.Tapped -> mempty
  EntryRewrite.OrTapped entryPrice -> entryPriceNames asking entryPrice
  EntryRewrite.EntersTransformed -> mempty
  EntryRewrite.RunEffects seq_ -> foldMap onEffect seq_

entryRidersNames :: (Monoid r) => Asking r -> (count -> r) -> (ability -> r) -> EntryRiders.EntryRiders count ability -> r
entryRidersNames asking onCount onAbility x = case x of
  EntryRiders.MkEntryRiders _tapped attacking blocking _transformed counters under _exiledFaceDown attachedTo faceDown _noted characteristics -> entryControllerNames asking under <> foldMap (entryAttackNames asking) attacking <> foldMap (entryBlockNames asking) blocking <> foldMap (counterKindNames asking (keywordNames asking)) (Map.keys counters) <> foldMap onCount counters <> foldMap (entryHostNames asking) attachedTo <> foldMap (faceDownStateNames asking onAbility) faceDown <> foldMap (modificationNames asking onAbility) characteristics

entryControllerNames :: (Monoid r) => Asking r -> EntryController.EntryController -> r
entryControllerNames asking x = case x of
  EntryController.Instructed player -> playerRefNames asking player
  EntryController.Owner -> mempty

equipNames :: (Monoid r) => Asking r -> (keyword -> r) -> Equip.Equip keyword -> r
equipNames asking onKeyword x = case x of
  Equip.MkEquip cost quality _target -> costNames asking onKeyword cost <> foldMap (filterNames asking) quality

exchangeBlocksNames :: (Monoid r) => Asking r -> ExchangeBlocks.ExchangeBlocks -> r
exchangeBlocksNames asking x = case x of
  ExchangeBlocks.MkExchangeBlocks first second -> slotNames asking first <> slotNames asking second

exchangeSidesNames :: Asking r -> ExchangeSides.ExchangeSides -> r
exchangeSidesNames asking x = case x of
  ExchangeSides.WithController slotName -> slotNames asking slotName
  ExchangeSides.BetweenTargets slotName -> slotNames asking slotName

exchangeValuesNames :: (Monoid r) => Asking r -> ExchangeValues.ExchangeValues -> r
exchangeValuesNames asking x = case x of
  ExchangeValues.MkExchangeValues one other duration -> exchangedValueNames asking one <> exchangedValueNames asking other <> durationNames asking duration

exchangeZonesNames :: (Monoid r) => Asking r -> ExchangeZones.ExchangeZones -> r
exchangeZonesNames asking x = case x of
  ExchangeZones.MkExchangeZones player _zones -> playerRefNames asking player

exchangedValueNames :: (Monoid r) => Asking r -> ExchangedValue.ExchangedValue -> r
exchangedValueNames asking x = case x of
  ExchangedValue.LifeTotal playerRef -> playerRefNames asking playerRef
  ExchangedValue.Power objectRef -> objectRefNames asking objectRef
  ExchangedValue.Toughness objectRef -> objectRefNames asking objectRef

exileCardsFromHandNames :: (Monoid r) => Asking r -> ExileCardsFromHand.ExileCardsFromHand keyword -> r
exileCardsFromHandNames asking x = case x of
  ExileCardsFromHand.MkExileCardsFromHand count whichCards -> costAmountNames asking count <> filterNames asking whichCards

exileCardsFromGraveyardNames :: (Monoid r) => Asking r -> ExileCardsFromGraveyard.ExileCardsFromGraveyard keyword -> r
exileCardsFromGraveyardNames asking x = case x of
  ExileCardsFromGraveyard.MkExileCardsFromGraveyard _count whichCards -> filterNames asking whichCards

exileHauntingNames :: (Monoid r) => Asking r -> ExileHaunting.ExileHaunting -> r
exileHauntingNames asking x = case x of
  ExileHaunting.MkExileHaunting card host -> slotNames asking card <> slotNames asking host

exileMaterialsNames :: (Monoid r) => Asking r -> ExileMaterials.ExileMaterials keyword -> r
exileMaterialsNames asking x = case x of
  ExileMaterials.MkExileMaterials _count _orMore whichObjects -> filterNames asking whichObjects

expiryNames :: (Monoid r) => Asking r -> Expiry.Expiry -> r
expiryNames asking x = case x of
  Expiry.AtCleanup -> mempty
  Expiry.Never -> mempty
  Expiry.Perpetual -> mempty
  Expiry.While while -> whileNames asking while
  Expiry.AtTurnOf _playerId -> mempty
  Expiry.AtStepOf _stepBegan -> mempty
  Expiry.AtEndOfTurnOf _afterTurn -> mempty
  Expiry.DuringTurnOf _afterTurn -> mempty
  Expiry.DuringUntapStepOf _playerId -> mempty
  Expiry.DuringTurnOfControllerOf afterObjectTurn -> names asking (== AfterObjectTurn.object afterObjectTurn)
  Expiry.DuringExtraTurn _timestamp -> mempty
  Expiry.AtEndOf _phaseSelector -> mempty
  Expiry.AtEndOfCombatOn _afterTurn -> mempty
  Expiry.WhenPaid paidExpiry -> paidExpiryNames asking paidExpiry
  Expiry.WhenUsed slot -> foldMap (slotNames asking) slot
  Expiry.OnEvent eventExpiry -> eventExpiryNames asking eventExpiry

eventShapeNames :: Asking r -> EventShape.EventShape -> r
eventShapeNames asking x = case x of
  EventShape.MovedBetween _movedBetween -> history asking HistoryRead.Moves
  EventShape.MovedFrom _zone -> history asking HistoryRead.Moves
  EventShape.CardArrivedIn _cardArrivedIn -> history asking HistoryRead.Moves
  EventShape.SpellCast -> history asking HistoryRead.Casts
  EventShape.SpellCastThisGame -> history asking HistoryRead.Casts

eventExpiryNames :: (Monoid r) => Asking r -> EventExpiry.EventExpiry -> r
eventExpiryNames asking x = case x of
  EventExpiry.MkEventExpiry _controller durationEvent -> durationEventNames asking durationEvent

faceNames :: (Monoid r) => Asking r -> (card -> r) -> Face.Face card -> r
faceNames asking onCard x = case x of
  Face.MkFace _name _oracleText _manaCost _typeLine power toughness _loyalty _defense _startingIntensity _vanguard _canBeYourCommander _claimsStartingPlayer _anteOnly keywords _colorIndicator characteristicPT staticAbilities spell activatedAbilities replacementEffects triggeredAbilities delayedAbilities rooms _dungeonEntryQuality _castingPermissions castingRestrictions enchant _counterability additionalCosts additionalCostChoices modeCosts _modeChooser maximumX _minimumX alternativeCosts costReductions playerAbilities blockRequirements blockPermissions attackRequirements combatRestrictions sacrificeRestrictions untapRestrictions crewRestrictions targetRestrictions attackPermissions attachRestrictions entryRestrictions counterRestrictions activationProhibitions attackCosts blockCosts mulliganActions openingHandActions specialActions -> foldMap (powerNames asking) power <> foldMap (toughnessNames asking) toughness <> foldMap (keywordNames asking) (Map.keys keywords) <> foldMap (characteristicPTNames asking) characteristicPT <> foldMap (staticAbilityNames asking (grantedAbilityNames asking onCard)) staticAbilities <> modalNames asking onCard (grantedAbilityNames asking onCard) spell <> foldMap (activatedAbilityNames asking onCard (grantedAbilityNames asking onCard)) activatedAbilities <> foldMap (printedReplacementNames asking onCard (grantedAbilityNames asking onCard) (effectNames asking onCard (grantedAbilityNames asking onCard))) replacementEffects <> foldMap (triggeredAbilityNames asking onCard (grantedAbilityNames asking onCard)) triggeredAbilities <> foldMap (triggeredAbilityNames asking onCard (grantedAbilityNames asking onCard)) delayedAbilities <> foldMap (dungeonRoomNames asking onCard) rooms <> foldMap (castingRestrictionNames asking) castingRestrictions <> foldMap (targetSlotNames asking) enchant <> foldMap (costComponentNames asking (keywordNames asking)) additionalCosts <> foldMap (costChoiceNames asking) additionalCostChoices <> foldMap (costNames asking (keywordNames asking)) modeCosts <> foldMap (quantityNames asking) maximumX <> foldMap (alternativeCostNames asking) alternativeCosts <> foldMap (costReductionNames asking) costReductions <> foldMap (playerStaticAbilityNames asking) playerAbilities <> foldMap (blockRequirementNames asking) blockRequirements <> foldMap (blockPermissionNames asking) blockPermissions <> foldMap (attackRequirementNames asking) attackRequirements <> foldMap (combatRestrictionNames asking) combatRestrictions <> foldMap (sacrificeRestrictionNames asking) sacrificeRestrictions <> foldMap (untapRestrictionNames asking) untapRestrictions <> foldMap (crewRestrictionNames asking) crewRestrictions <> foldMap (targetRestrictionNames asking (affectedNames asking)) targetRestrictions <> foldMap (attackPermissionNames asking) attackPermissions <> foldMap (attachRestrictionNames asking) attachRestrictions <> foldMap (entryRestrictionNames asking) entryRestrictions <> foldMap (counterRestrictionNames asking) counterRestrictions <> foldMap (activationProhibitionNames asking) activationProhibitions <> foldMap (attackCostNames asking) attackCosts <> foldMap (blockCostNames asking) blockCosts <> foldMap (handActionNames asking onCard) mulliganActions <> foldMap (handActionNames asking onCard) openingHandActions <> foldMap (specialActionNames asking) specialActions

faceDownCharacteristicsNames :: (Monoid r) => Asking r -> (ability -> r) -> FaceDownCharacteristics.FaceDownCharacteristics ability -> r
faceDownCharacteristicsNames asking onAbility x = case x of
  FaceDownCharacteristics.MkFaceDownCharacteristics _typeLine power toughness keywords abilities -> foldMap (powerNames asking) power <> foldMap (toughnessNames asking) toughness <> foldMap (keywordNames asking) keywords <> foldMap onAbility abilities

faceDownStateNames :: (Monoid r) => Asking r -> (ability -> r) -> FaceDownState.FaceDownState ability -> r
faceDownStateNames asking onAbility x = case x of
  FaceDownState.MkFaceDownState _reason listed _turnsUpBefore -> faceDownCharacteristicsNames asking onAbility listed

fightNames :: (Monoid r) => Asking r -> Fight.Fight -> r
fightNames asking x = case x of
  Fight.MkFight first second -> slotNames asking first <> slotNames asking second

flipCoinNames :: (Monoid r) => Asking r -> FlipCoin.FlipCoin -> r
flipCoinNames asking x = case x of
  FlipCoin.MkFlipCoin count _reading slot misses flipper -> quantityNames asking count <> slotNames asking slot <> foldMap (slotNames asking) misses <> playerRefNames asking flipper

guessNames :: (Monoid r) => Asking r -> Guess.Guess -> r
guessNames asking x = case x of
  Guess.MkGuess subject slot guesser proposition right -> objectRefNames asking subject <> slotNames asking slot <> playerRefNames asking guesser <> filterNames asking proposition <> slotNames asking right

floatingCandidateNames :: Asking r -> FloatingCandidate.FloatingCandidate -> r
floatingCandidateNames asking x = case x of
  FloatingCandidate.MkFloatingCandidate source _timestamp -> names asking (== source)

forEachNames :: (Monoid r) => Asking r -> (effect -> r) -> ForEach.ForEach effect -> r
forEachNames asking onEffect x = case x of
  ForEach.MkForEach ref _members slot body _individually payGate startingWith -> objectRefNames asking ref <> slotNames asking slot <> foldMap onEffect body <> foldMap (payGateNames asking) payGate <> foldMap (playerRefNames asking) startingWith

forEachNumberNames :: (Monoid r) => Asking r -> (effect -> r) -> ForEachNumber.ForEachNumber effect -> r
forEachNumberNames asking onEffect x = case x of
  ForEachNumber.MkForEachNumber upTo slot body -> quantityNames asking upTo <> slotNames asking slot <> foldMap onEffect body

forbidAttackNames :: (Monoid r) => Asking r -> ForbidAttack.ForbidAttack -> r
forbidAttackNames asking x = case x of
  ForbidAttack.MkForbidAttack duration affected aimedAt -> durationNames asking duration <> restrictedCreaturesNames asking (objectRefNames asking) affected <> foldMap (aimedAtNames asking) aimedAt

forbidBeingBlockedNames :: (Monoid r) => Asking r -> ForbidBeingBlocked.ForbidBeingBlocked -> r
forbidBeingBlockedNames asking x = case x of
  ForbidBeingBlocked.MkForbidBeingBlocked duration affected barred -> durationNames asking duration <> filterNames asking affected <> filterNames asking barred

foretellCostNames :: (Monoid r) => Asking r -> (keyword -> r) -> ForetellCost.ForetellCost keyword -> r
foretellCostNames asking onKeyword x = case x of
  ForetellCost.Stated cost -> costNames asking onKeyword cost
  ForetellCost.ManaCostReducedBy _manaCost -> mempty

fromOutsideTheGameNames :: (Monoid r) => Asking r -> FromOutsideTheGame.FromOutsideTheGame -> r
fromOutsideTheGameNames asking x = case x of
  FromOutsideTheGame.MkFromOutsideTheGame _count _upTo _destination filter_ _reveal -> filterNames asking filter_

fromReferenceNames :: (Monoid r) => Asking r -> FromReference.FromReference -> r
fromReferenceNames asking x = case x of
  FromReference.MkFromReference filter_ amount -> filterNames asking filter_ <> foldMap (quantityNames asking) amount

fullTextNames :: (Monoid r) => Asking r -> (ability -> r) -> FullText.FullText ability -> r
fullTextNames asking onAbility x = case x of
  FullText.MkFullText graveyard alsoHas -> playerRefNames asking graveyard <> foldMap onAbility alsoHas

gainControlNames :: (Monoid r) => Asking r -> GainControl.GainControl -> r
gainControlNames asking x = case x of
  GainControl.MkGainControl duration ref to -> durationNames asking duration <> objectRefNames asking ref <> playerRefNames asking to

grantLookAtExiledNames :: (Monoid r) => Asking r -> GrantLookAtExiled.GrantLookAtExiled -> r
grantLookAtExiledNames asking x = case x of
  GrantLookAtExiled.MkGrantLookAtExiled cards _followsExiler -> objectRefNames asking cards

grantPlayFromExileNames :: (Monoid r) => Asking r -> GrantPlayFromExile.GrantPlayFromExile -> r
grantPlayFromExileNames asking x = case x of
  GrantPlayFromExile.MkGrantPlayFromExile duration player ref _spending _alternativeCost condition _verb _increase _landEnters _upTo -> durationNames asking duration <> playerRefNames asking player <> objectRefNames asking ref <> foldMap (conditionNames asking) condition

-- A granted ability's slots are its OWN: each read resolves against the
-- bindings of the stack object it becomes or of the object it is granted to,
-- which Parun.Engine.Interchangeable.namedByAnother searches and whole-object
-- Eq compares. So inside one, every slot read is Searched, whatever the row
-- granting it stores.
grantedAbilityNames :: (Monoid r) => Asking r -> (card -> r) -> GrantedAbility.GrantedAbility card -> r
grantedAbilityNames asking onCard x =
  let own = asking {context = mempty}
   in case x of
        GrantedAbility.Activated activatedAbility -> activatedAbilityNames own onCard (grantedAbilityNames own onCard) activatedAbility
        GrantedAbility.Triggered triggeredAbility -> triggeredAbilityNames own onCard (grantedAbilityNames own onCard) triggeredAbility
        GrantedAbility.Static staticAbility -> staticAbilityNames own (grantedAbilityNames own onCard) staticAbility
        GrantedAbility.Rules ruleAbilities -> ruleAbilitiesNames own ruleAbilities
        GrantedAbility.Replacement printedReplacement -> printedReplacementNames own onCard (grantedAbilityNames own onCard) (effectNames own onCard (grantedAbilityNames own onCard)) printedReplacement
        GrantedAbility.Player playerStaticAbility -> playerStaticAbilityNames own playerStaticAbility
        GrantedAbility.SelfCostReduction costReduction -> costReductionNames own costReduction
        GrantedAbility.SelfAlternativeCost alternativeCost -> alternativeCostNames own alternativeCost
        GrantedAbility.SelfSpendManaAsThough _spendManaAsThough -> mempty

quotientNames :: (Monoid r) => Asking r -> (quantity -> r) -> Quotient.Quotient quantity -> r
quotientNames _asking onQuantity x = case x of
  Quotient.MkQuotient _rounding quantity divisor -> onQuantity quantity <> onQuantity divisor

handActionNames :: (Monoid r) => Asking r -> (card -> r) -> HandAction.HandAction card -> r
handActionNames asking onCard x = case x of
  HandAction.MkHandAction condition effects -> foldMap (conditionNames asking) condition <> foldMap (effectNames asking onCard (grantedAbilityNames asking onCard)) effects

impendingNames :: (Monoid r) => Asking r -> (keyword -> r) -> Impending.Impending keyword -> r
impendingNames asking onKeyword x = case x of
  Impending.MkImpending _counters cost -> costNames asking onKeyword cost

inZoneNames :: (Monoid r) => Asking r -> InZone.InZone -> r
inZoneNames asking x = case x of
  InZone.MkInZone _zone player -> playerRefNames asking player

instructionRNames :: (Monoid r) => Asking r -> InstructionR.InstructionR -> r
instructionRNames asking x = case x of
  InstructionR.MkInstructionR _instruction whose _rewrite -> controllerRelationNames asking whose

keywordNames :: (Monoid r) => Asking r -> Keyword.Keyword -> r
keywordNames asking x = case x of
  Keyword.Deathtouch -> mempty
  Keyword.Defender -> mempty
  Keyword.DoubleStrike -> mempty
  Keyword.Equip equip -> equipNames asking (keywordNames asking) equip
  Keyword.FirstStrike -> mempty
  Keyword.Flash -> mempty
  Keyword.Flying -> mempty
  Keyword.Haste -> mempty
  Keyword.Hexproof filter_ -> foldMap (filterNames asking) filter_
  Keyword.Indestructible -> mempty
  Keyword.Intimidate -> mempty
  Keyword.Landwalk filter_ -> filterNames asking filter_
  Keyword.Lifelink -> mempty
  Keyword.LivingMetal -> mempty
  Keyword.MoreThanMeetsTheEye cost -> costNames asking (keywordNames asking) cost
  Keyword.Protection protection -> protectionNames asking protection
  Keyword.Reach -> mempty
  Keyword.Shroud -> mempty
  Keyword.Trample -> mempty
  Keyword.TrampleOverPlaneswalkers -> mempty
  Keyword.Vigilance -> mempty
  Keyword.Ward ward -> wardNames asking (keywordNames asking) ward
  Keyword.Banding -> mempty
  Keyword.Rampage _natural -> mempty
  Keyword.CumulativeUpkeep cost -> costNames asking (keywordNames asking) cost
  Keyword.Flanking -> mempty
  Keyword.Phasing -> mempty
  Keyword.Buyback cost -> costNames asking (keywordNames asking) cost
  Keyword.Shadow -> mempty
  Keyword.Cycling cycling -> cyclingNames asking (keywordNames asking) cycling
  Keyword.Echo cost -> costNames asking (keywordNames asking) cost
  Keyword.Horsemanship -> mempty
  Keyword.Fading _natural -> mempty
  Keyword.Kicker cost -> costNames asking (keywordNames asking) cost
  Keyword.Multikicker cost -> costNames asking (keywordNames asking) cost
  Keyword.StickerKicker cost -> costNames asking (keywordNames asking) cost
  Keyword.Flashback cost -> costNames asking (keywordNames asking) cost
  Keyword.Fear -> mempty
  Keyword.Morph morph -> morphNames asking (keywordNames asking) morph
  Keyword.Amplify _natural -> mempty
  Keyword.Provoke -> mempty
  Keyword.Storm -> history asking HistoryRead.Casts
  Keyword.Affinity filter_ -> filterNames asking filter_
  Keyword.Entwine cost -> costNames asking (keywordNames asking) cost
  Keyword.Modular _natural -> mempty
  Keyword.Sunburst -> mempty
  Keyword.Bushido _natural -> mempty
  Keyword.Soulshift _natural -> mempty
  Keyword.Splice splice -> spliceNames asking (keywordNames asking) splice
  Keyword.Offering filter_ -> filterNames asking filter_
  Keyword.Ninjutsu (Ninjutsu.MkNinjutsu cost _variant) -> costNames asking (keywordNames asking) cost
  Keyword.Epic -> mempty
  Keyword.Paradigm -> mempty
  Keyword.Convoke -> mempty
  Keyword.Dredge _natural -> mempty
  Keyword.Bloodthirst _natural -> history asking HistoryRead.Damage
  Keyword.Haunt -> mempty
  Keyword.Replicate cost -> costNames asking (keywordNames asking) cost
  Keyword.Graft _natural -> mempty
  Keyword.Recover cost -> costNames asking (keywordNames asking) cost
  Keyword.Ripple _natural -> mempty
  Keyword.SplitSecond -> mempty
  Keyword.Suspend suspend -> foldMap (suspendNames asking (keywordNames asking)) suspend
  Keyword.Vanishing _natural -> mempty
  Keyword.Absorb _natural -> mempty
  Keyword.AuraSwap cost -> costNames asking (keywordNames asking) cost
  Keyword.Delve -> mempty
  Keyword.Fortify cost -> costNames asking (keywordNames asking) cost
  Keyword.Frenzy _natural -> mempty
  Keyword.Gravestorm -> history asking HistoryRead.Deaths
  Keyword.Poisonous _natural -> mempty
  Keyword.Champion filter_ -> filterNames asking filter_
  Keyword.Changeling -> mempty
  Keyword.Evoke cost -> costNames asking (keywordNames asking) cost
  Keyword.Hideaway _natural -> mempty
  Keyword.Prowl cost -> history asking HistoryRead.Damage <> costNames asking (keywordNames asking) cost
  Keyword.Reinforce reinforce -> reinforceNames asking (keywordNames asking) reinforce
  Keyword.Conspire -> mempty
  Keyword.Persist -> mempty
  Keyword.Wither -> mempty
  Keyword.Devour devour -> devourNames asking devour
  Keyword.Exalted -> mempty
  Keyword.Unearth cost -> costNames asking (keywordNames asking) cost
  Keyword.Cascade -> mempty
  Keyword.Annihilator _natural -> mempty
  Keyword.LevelUp cost -> costNames asking (keywordNames asking) cost
  Keyword.Infect -> mempty
  Keyword.BattleCry -> mempty
  Keyword.LivingWeapon -> mempty
  Keyword.Undying -> mempty
  Keyword.Miracle cost -> costNames asking (keywordNames asking) cost
  Keyword.Soulbond -> mempty
  Keyword.Overload cost -> costNames asking (keywordNames asking) cost
  Keyword.Unleash -> mempty
  Keyword.Cipher -> mempty
  Keyword.Evolve -> mempty
  Keyword.Extort -> mempty
  Keyword.Fuse -> mempty
  Keyword.Tribute _natural -> mempty
  Keyword.Dethrone -> mempty
  Keyword.HiddenAgenda -> mempty
  Keyword.Outlast cost -> costNames asking (keywordNames asking) cost
  Keyword.Prowess -> mempty
  Keyword.Dash cost -> costNames asking (keywordNames asking) cost
  Keyword.Exploit -> mempty
  Keyword.Menace -> mempty
  Keyword.Renown _natural -> mempty
  Keyword.Awaken cost -> costNames asking (keywordNames asking) cost
  Keyword.Devoid -> mempty
  Keyword.Ingest -> mempty
  Keyword.Myriad -> mempty
  Keyword.Surge cost -> history asking HistoryRead.Casts <> costNames asking (keywordNames asking) cost
  Keyword.Skulk -> mempty
  Keyword.SpaceSculptor -> mempty
  Keyword.Emerge emerge -> emergeNames asking (keywordNames asking) emerge
  Keyword.Escalate cost -> costNames asking (keywordNames asking) cost
  Keyword.Melee -> mempty
  Keyword.Crew _natural -> mempty
  Keyword.Fabricate _natural -> mempty
  Keyword.Partner -> mempty
  Keyword.PartnerText _partnerText -> mempty
  Keyword.PartnerWith _cardName -> mempty
  Keyword.ChooseABackground -> mempty
  Keyword.DoctorsCompanion -> mempty
  Keyword.Undaunted -> mempty
  Keyword.Improvise -> mempty
  Keyword.Aftermath -> mempty
  Keyword.Embalm cost -> costNames asking (keywordNames asking) cost
  Keyword.Eternalize cost -> costNames asking (keywordNames asking) cost
  Keyword.Afflict _natural -> mempty
  Keyword.Ascend -> mempty
  Keyword.Assist -> mempty
  Keyword.JumpStart -> mempty
  Keyword.Mentor -> mempty
  Keyword.Afterlife _natural -> mempty
  Keyword.Riot -> mempty
  Keyword.Spectacle cost -> history asking HistoryRead.LifeLosses <> costNames asking (keywordNames asking) cost
  Keyword.Escape cost -> costNames asking (keywordNames asking) cost
  Keyword.Companion filter_ -> filterNames asking filter_
  Keyword.Foretell foretellCost -> foretellCostNames asking (keywordNames asking) foretellCost
  Keyword.Demonstrate -> mempty
  Keyword.Daybound -> mempty
  Keyword.Nightbound -> mempty
  Keyword.Decayed -> mempty
  Keyword.Cleave cost -> costNames asking (keywordNames asking) cost
  Keyword.Training -> mempty
  Keyword.Compleated -> mempty
  Keyword.Reconfigure cost -> costNames asking (keywordNames asking) cost
  Keyword.Blitz cost -> costNames asking (keywordNames asking) cost
  Keyword.Casualty _natural -> mempty
  Keyword.ReadAhead -> history asking HistoryRead.Entries
  Keyword.Ravenous -> mempty
  Keyword.Squad cost -> costNames asking (keywordNames asking) cost
  Keyword.Prototype _prototype -> mempty
  Keyword.ForMirrodin -> mempty
  Keyword.Toxic _natural -> mempty
  Keyword.Backup backup -> backupNames asking (keywordNames asking) backup
  Keyword.Bargain -> mempty
  Keyword.Craft craft -> craftNames asking (keywordNames asking) craft
  Keyword.Disguise cost -> costNames asking (keywordNames asking) cost
  Keyword.Plot cost -> costNames asking (keywordNames asking) cost
  Keyword.Saddle _natural -> mempty
  Keyword.Spree -> mempty
  Keyword.Offspring cost -> costNames asking (keywordNames asking) cost
  Keyword.Gift _gift -> mempty
  Keyword.Freerunning cost -> history asking HistoryRead.Damage <> costNames asking (keywordNames asking) cost
  Keyword.Impending impending -> impendingNames asking (keywordNames asking) impending
  Keyword.Exhaust -> mempty
  Keyword.Boast -> history asking HistoryRead.Attacks
  Keyword.PowerUp -> history asking HistoryRead.Entries
  Keyword.ClassLevel _classLevel -> mempty
  Keyword.Forecast -> mempty
  Keyword.StartYourEngines -> mempty
  Keyword.JobSelect -> mempty
  Keyword.Tiered -> mempty
  Keyword.Exert -> mempty
  Keyword.Enlist -> mempty
  Keyword.Bestow cost -> costNames asking (keywordNames asking) cost
  Keyword.Station -> mempty
  Keyword.Mutate cost -> costNames asking (keywordNames asking) cost
  Keyword.UmbraArmor -> mempty
  Keyword.Retrace -> mempty
  Keyword.Mayhem cost -> history asking HistoryRead.Discards <> foldMap (costNames asking (keywordNames asking)) cost
  Keyword.Madness madnessCost -> madnessCostNames asking (keywordNames asking) madnessCost
  Keyword.Rebound -> mempty
  Keyword.Scavenge cost -> costNames asking (keywordNames asking) cost
  Keyword.Encore cost -> costNames asking (keywordNames asking) cost
  Keyword.Teamwork _natural -> mempty
  Keyword.WebSlinging cost -> costNames asking (keywordNames asking) cost
  Keyword.Sneak cost -> costNames asking (keywordNames asking) cost
  Keyword.Increment -> mempty
  Keyword.Storied -> mempty
  Keyword.Mobilize keywordCount -> keywordCountNames asking keywordCount
  Keyword.Firebending keywordCount -> keywordCountNames asking keywordCount
  Keyword.Transmute cost -> costNames asking (keywordNames asking) cost
  Keyword.Transfigure cost -> costNames asking (keywordNames asking) cost
  Keyword.Warp cost -> costNames asking (keywordNames asking) cost
  Keyword.Disturb cost -> costNames asking (keywordNames asking) cost
  Keyword.Harmonize cost -> costNames asking (keywordNames asking) cost

keywordCountNames :: (Monoid r) => Asking r -> KeywordCount.KeywordCount keyword -> r
keywordCountNames asking x = case x of
  KeywordCount.Fixed _natural -> mempty
  KeywordCount.Power -> mempty
  KeywordCount.Tally keywordTally -> keywordTallyNames asking keywordTally
  KeywordCount.PlayerCounters playerCounterTally -> playerCounterTallyNames asking playerCounterTally

keywordDesignatorNames :: (Monoid r) => Asking r -> KeywordDesignator.KeywordDesignator Keyword.Keyword -> r
keywordDesignatorNames asking x = case x of
  KeywordDesignator.OfFamily _keywordFamily -> mempty
  KeywordDesignator.OfKeyword keyword -> keywordNames asking keyword
  KeywordDesignator.Printed _keywordFamily -> mempty
  KeywordDesignator.OfInstance keyword _ordinal -> keywordNames asking keyword

keywordTallyNames :: (Monoid r) => Asking r -> KeywordTally.KeywordTally keyword -> r
keywordTallyNames asking x = case x of
  KeywordTally.MkKeywordTally scope filter_ -> scopeNames asking scope <> filterNames asking filter_

libraryPlacementNames :: (Monoid r) => Asking r -> LibraryPlacement.LibraryPlacement -> r
libraryPlacementNames asking x = case x of
  LibraryPlacement.Stated _libraryPosition -> mempty
  LibraryPlacement.OwnerChooses -> mempty
  LibraryPlacement.RandomOrder _libraryPosition -> mempty
  LibraryPlacement.ArrangedBy (ArrangedArrival.MkArrangedArrival _libraryPosition chooser) -> playerRefNames asking chooser
  LibraryPlacement.Beneath quantity -> quantityNames asking quantity
  LibraryPlacement.BeneathOrBottom quantity -> quantityNames asking quantity

lifeGainRNames :: (Monoid r) => Asking r -> LifeGainR.LifeGainR -> r
lifeGainRNames asking x = case x of
  LifeGainR.MkLifeGainR whose _rewrite -> controllerRelationNames asking whose

lifeLossNames :: (Monoid r) => Asking r -> LifeLoss.LifeLoss -> r
lifeLossNames asking x = case x of
  LifeLoss.MkLifeLoss player quantity _cause tally -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (slotNames asking) tally

lifeLossPatternNames :: (Monoid r) => Asking r -> LifeLossPattern.LifeLossPattern -> r
lifeLossPatternNames asking x = case x of
  LifeLossPattern.MkLifeLossPattern whose _whichCause -> controllerRelationNames asking whose

lifeLossRNames :: (Monoid r) => Asking r -> LifeLossR.LifeLossR -> r
lifeLossRNames asking x = case x of
  LifeLossR.MkLifeLossR matching _rewrite -> lifeLossPatternNames asking matching

limitUnlessNames :: (Monoid r) => Asking r -> LimitUnless.LimitUnless -> r
limitUnlessNames asking x = case x of
  LimitUnless.MkLimitUnless _limit _comparison attackers unless -> foldMap (affectedNames asking) attackers <> foldMap (conditionNames asking) unless

lookAtNames :: (Monoid r) => Asking r -> LookAt.LookAt -> r
lookAtNames asking x = case x of
  LookAt.MkLookAt ref slot looker -> objectRefNames asking ref <> slotNames asking slot <> playerRefNames asking looker

madnessCostNames :: (Monoid r) => Asking r -> (keyword -> r) -> MadnessCost.MadnessCost keyword -> r
madnessCostNames asking onKeyword x = case x of
  MadnessCost.Stated cost -> costNames asking onKeyword cost
  MadnessCost.OwnManaCost -> mempty

makeForetoldNames :: (Monoid r) => Asking r -> MakeForetold.MakeForetold -> r
makeForetoldNames asking x = case x of
  MakeForetold.MkMakeForetold cards _manaCostReducedBy -> objectRefNames asking cards

manaAdditionNames :: (Monoid r) => Asking r -> ManaAddition.ManaAddition -> r
manaAdditionNames asking x = case x of
  ManaAddition.MkManaAddition player production count _retention restriction rider whenSpent -> playerRefNames asking player <> manaProductionNames asking production <> quantityNames asking count <> foldMap (manaRestrictionNames asking) restriction <> foldMap (manaRiderNames asking) rider <> foldMap (whenSpentNames asking) whenSpent

manaProductionNames :: (Monoid r) => Asking r -> ManaProduction.ManaProduction -> r
manaProductionNames asking x = case x of
  ManaProduction.OfType _manaType -> mempty
  ManaProduction.AnyColor -> mempty
  ManaProduction.Chosen -> mempty
  ManaProduction.SnowSymbol -> mempty
  ManaProduction.Noted -> mempty
  ManaProduction.CouldProduce (CouldProduce.MkCouldProduce among _types) -> filterNames asking among
  ManaProduction.Pooled manaCount -> manaCountNames asking manaCount

manaCountNames :: (Monoid r) => Asking r -> ManaCount.ManaCount -> r
manaCountNames asking x = case x of
  ManaCount.MkManaCount player _filter_ -> playerRefNames asking player

tapForManaNames :: (Monoid r) => Asking r -> TapForMana.TapForMana -> r
tapForManaNames asking x = case x of
  TapForMana.MkTapForMana permanents restriction -> filterNames asking permanents <> foldMap (manaRestrictionNames asking) restriction

manaRestrictionNames :: (Monoid r) => Asking r -> ManaRestriction.ManaRestriction -> r
manaRestrictionNames asking x = case x of
  ManaRestriction.MkManaRestriction casts activations keywordActivations unlocks turnsFaceUp _prohibits -> foldMap (filterNames asking) casts <> foldMap (filterNames asking) activations <> foldMap (keywordDesignatorNames asking) keywordActivations <> foldMap (filterNames asking) unlocks <> foldMap (filterNames asking) turnsFaceUp

manaRiderNames :: (Monoid r) => Asking r -> ManaRider.ManaRider -> r
manaRiderNames asking x = case x of
  ManaRider.MkManaRider condition _effect -> filterNames asking condition

measuresNames :: (Monoid r) => Asking r -> Measures.Measures -> r
measuresNames asking x = case x of
  Measures.MkMeasures _measure _comparison operand -> operandNames asking operand

meldNames :: (Monoid r) => Asking r -> (card -> r) -> Meld.Meld card -> r
meldNames asking onCard x = case x of
  Meld.MkMeld objects result -> objectRefNames asking objects <> onCard result

millNames :: (Monoid r) => Asking r -> Mill.Mill -> r
millNames asking x = case x of
  Mill.MkMill player quantity tally slot -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (millTallyNames asking) tally <> foldMap (slotNames asking) slot

millTallyNames :: (Monoid r) => Asking r -> MillTally.MillTally -> r
millTallyNames asking x = case x of
  MillTally.MkMillTally slot filter_ -> slotNames asking slot <> filterNames asking filter_

modalNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> Modal.Modal card ability -> r
modalNames asking onCard onAbility x = case x of
  Modal.MkModal modes _selection -> foldMap (modeNames asking onCard onAbility) modes

modeNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> Mode.Mode card ability -> r
modeNames asking onCard onAbility x = case x of
  Mode.MkMode clauses targetSlots -> foldMap (clauseNames asking onCard onAbility) clauses <> foldMap (slotNames asking) (Map.keys targetSlots) <> foldMap (targetSlotNames asking) targetSlots

modificationNames :: (Monoid r) => Asking r -> (ability -> r) -> Modification.Modification ability -> r
modificationNames asking onAbility x = case x of
  Modification.GainKeyword keyword -> keywordNames asking keyword
  Modification.GainKeywordAtManaCost _costKeyword -> mempty
  Modification.GainEnchant targetSlot -> targetSlotNames asking targetSlot
  Modification.LoseEnchant targetSlot -> targetSlotNames asking targetSlot
  Modification.GainCastingPermission _castingPermission -> mempty
  Modification.GainAbility ability -> onAbility ability
  Modification.GainAbilitiesOfSource keyword -> foldMap (keywordNames asking) keyword
  Modification.GainExiledCardAbilities (ExiledCardAbilities.MkExiledCardAbilities cards items) -> filterNames asking cards <> foldMap (activationRestrictionNames asking) items
  Modification.GainAbilitiesOfStickers -> mempty
  Modification.LoseAllAbilities -> mempty
  Modification.LoseNamedAbility abilityName -> names asking (`Binding.Engine.isAcquiredFrom` abilityName)
  Modification.LoseKeyword keyword -> keywordNames asking keyword
  Modification.LoseKeywordFamily _keywordFamily -> mempty
  Modification.SetBasePowerToughness setBasePowerToughness -> setBasePowerToughnessNames asking setBasePowerToughness
  Modification.ModifyPowerToughness modifyPowerToughness -> modifyPowerToughnessNames asking modifyPowerToughness
  Modification.LandSubtype _changeMode _subtype -> mempty
  Modification.ChosenSubtype {} -> mempty
  Modification.CreatureSubtype _changeMode _subtype -> mempty
  Modification.AddEveryCreatureSubtype -> mempty
  Modification.LoseEveryCreatureSubtype -> mempty
  Modification.SetCreatureSubtypesOfLastCardExiledWith filter_ -> filterNames asking filter_
  Modification.AddSubtype _subtype -> mempty
  Modification.RemoveSubtype _subtype -> mempty
  Modification.CardType {} -> mempty
  Modification.LoseCardType _cardType -> mempty
  Modification.AddSupertype _supertype -> mempty
  Modification.RemoveSupertype _supertype -> mempty
  Modification.ChangeWord _changeSubtypeWord -> mempty
  Modification.ExchangeTextBoxes -> mempty
  Modification.AddNamesMatching filter_ -> filterNames asking filter_
  Modification.SetName _cardName -> mempty
  Modification.InsertNameWords _nameInsertion -> mempty
  Modification.HasFullText fullText -> fullTextNames asking onAbility fullText
  Modification.SetController _playerId -> mempty
  Modification.SetControllerToSource -> mempty
  Modification.Colors _colorMode _colors -> mempty
  Modification.ChosenColor _ -> mempty
  Modification.SwitchPowerToughness -> mempty
  Modification.AssignCombatDamageWithToughness -> mempty
  Modification.MayAssignCombatDamage _option -> mempty
  Modification.GrantsStationToughness -> mempty
  Modification.Intensify quantity -> quantityNames asking quantity

modifiedRollNames :: (Monoid r) => Asking r -> ModifiedRoll.ModifiedRoll -> r
modifiedRollNames asking x = case x of
  ModifiedRoll.MkModifiedRoll _sides _natural _modifier cost _limit -> foldMap (costNames asking (keywordNames asking)) cost

modifyPowerToughnessNames :: (Monoid r) => Asking r -> ModifyPowerToughness.ModifyPowerToughness -> r
modifyPowerToughnessNames asking x = case x of
  ModifyPowerToughness.MkModifyPowerToughness power toughness -> quantityNames asking power <> quantityNames asking toughness

modifyTargetNames :: (Monoid r) => Asking r -> (ability -> r) -> ModifyTarget.ModifyTarget ability -> r
modifyTargetNames asking onAbility x = case x of
  ModifyTarget.MkModifyTarget duration modification ref each -> durationNames asking duration <> modificationNames asking onAbility modification <> objectRefNames asking ref <> foldMap (slotNames asking) each

monarchTargetNames :: (Monoid r) => Asking r -> MonarchTarget.MonarchTarget -> r
monarchTargetNames asking x = case x of
  MonarchTarget.TheController -> mempty
  MonarchTarget.ControllerOfSource -> mempty
  MonarchTarget.InSlot slotName -> slotNames asking slotName

morphNames :: (Monoid r) => Asking r -> (keyword -> r) -> Morph.Morph keyword -> r
morphNames asking onKeyword x = case x of
  Morph.MkMorph cost _variant -> costNames asking onKeyword cost

moveCountersNames :: (Monoid r) => Asking r -> MoveCounters.MoveCounters -> r
moveCountersNames asking x = case x of
  MoveCounters.MkMoveCounters from kinds slot to -> objectRefNames asking from <> movedKindsNames asking kinds <> foldMap (slotNames asking) slot <> objectRefNames asking to

moveManaNames :: (Monoid r) => Asking r -> MoveMana.MoveMana -> r
moveManaNames asking x = case x of
  MoveMana.MkMoveMana from to -> playerRefNames asking from <> foldMap (playerRefNames asking) to

moveToZoneNames :: (Monoid r) => Asking r -> (ability -> r) -> MoveToZone.MoveToZone ability -> r
moveToZoneNames asking onAbility x = case x of
  MoveToZone.MkMoveToZone ref _zone riders slot _origin placement duration -> foldMap (moveDurationNames asking) duration <> objectRefNames asking ref <> entryRidersNames asking (quantityNames asking) onAbility riders <> foldMap (slotNames asking) slot <> libraryPlacementNames asking placement

moveDurationNames :: (Monoid r) => Asking r -> MoveDuration.MoveDuration -> r
moveDurationNames asking x = case x of
  MoveDuration.UntilSourceLeavesTheBattlefield -> mempty
  MoveDuration.UntilAnOpponentBecomesTheMonarch -> history asking HistoryRead.MonarchChanges

movedKindsNames :: (Monoid r) => Asking r -> MovedKinds.MovedKinds -> r
movedKindsNames asking x = case x of
  MovedKinds.Every -> mempty
  MovedKinds.Named counterKind quantity -> counterKindNames asking (keywordNames asking) counterKind <> quantityNames asking quantity
  MovedKinds.EveryOfKind counterKind -> counterKindNames asking (keywordNames asking) counterKind
  MovedKinds.Chosen quantity -> quantityNames asking quantity
  MovedKinds.AnyNumber -> mempty
  MovedKinds.AtLeastOne -> mempty
  MovedKinds.AnyNumberOfKind counterKind -> counterKindNames asking (keywordNames asking) counterKind
  MovedKinds.EachAbsentKind -> mempty
  MovedKinds.UpToOneChosen -> mempty

objectRefNames :: (Monoid r) => Asking r -> ObjectRef.ObjectRef -> r
objectRefNames asking x = case x of
  ObjectRef.InSlot slotName -> slotNames asking slotName
  ObjectRef.EachMatching filter_ -> filterNames asking filter_
  ObjectRef.EachCardInGraveyard eachCardInGraveyard -> eachCardInGraveyardNames asking eachCardInGraveyard
  ObjectRef.EachCardInYourHand -> mempty
  ObjectRef.EachCardInHand eachCardInHand -> eachCardInHandNames asking eachCardInHand
  ObjectRef.EachCardInYourLibrary filter_ -> foldMap (filterNames asking) filter_
  ObjectRef.EachCardYouOwn filter_ -> filterNames asking filter_
  ObjectRef.EachCardInExiledPile (EachCardInExiledPile.MkEachCardInExiledPile _pile filter_) -> foldMap (filterNames asking) filter_
  ObjectRef.EachCardEncodedOnSource filter_ -> foldMap (filterNames asking) filter_
  ObjectRef.EachSpell filter_ -> filterNames asking filter_
  ObjectRef.EachAbility filter_ -> filterNames asking filter_
  ObjectRef.EachOnStack filter_ -> filterNames asking filter_
  ObjectRef.EachPlayer -> mempty
  ObjectRef.EachOpponent -> mempty
  ObjectRef.ChosenPlayer -> mempty
  ObjectRef.Players (PlayersWho.MkPlayersWho playerRef who) -> playerRefNames asking playerRef <> foldMap (filterNames asking) who
  ObjectRef.TopOfLibrary topOfLibrary -> topOfLibraryNames asking topOfLibrary
  ObjectRef.TopOfLibraryUntil topOfLibraryUntil -> topOfLibraryUntilNames asking topOfLibraryUntil
  ObjectRef.TopOfGraveyard playerRef -> playerRefNames asking playerRef
  ObjectRef.ChosenCardInGraveyard chosenCardInGraveyard -> chosenCardInGraveyardNames asking chosenCardInGraveyard
  ObjectRef.ChosenCardInHand chosenCardInHand -> chosenCardInHandNames asking chosenCardInHand
  ObjectRef.ChosenCardFromAmong chosenCardFromAmong -> chosenCardFromAmongNames asking chosenCardFromAmong
  ObjectRef.EachCardFromAmong eachCardFromAmong -> eachCardFromAmongNames asking eachCardFromAmong
  ObjectRef.RandomCardInHand randomCardInHand -> randomCardInHandNames asking randomCardInHand
  ObjectRef.RandomCardInGraveyard randomCardInGraveyard -> randomCardInGraveyardNames asking randomCardInGraveyard
  ObjectRef.RandomCardInLibrary randomCardInLibrary -> randomCardInLibraryNames asking randomCardInLibrary
  ObjectRef.AtRandom inner -> objectRefNames asking inner
  ObjectRef.ChosenPermanents chosenPermanents -> chosenPermanentsNames asking chosenPermanents
  ObjectRef.AttachedToBound attachedToBound -> attachedToBoundNames asking attachedToBound
  ObjectRef.FromAnywhere fromAnywhere -> history asking HistoryRead.Moves <> fromAnywhereNames asking fromAnywhere
  ObjectRef.AllOf refs -> foldMap (objectRefNames asking) refs

offerCastNames :: (Monoid r) => Asking r -> OfferCast.OfferCast -> r
offerCastNames asking x = case x of
  OfferCast.MkOfferCast ref caster _optionality _verb offer repetition _copied _controlWhileResolving slot -> objectRefNames asking ref <> playerRefNames asking caster <> castOfferNames asking offer <> castRepetitionNames asking repetition <> foldMap (slotNames asking) slot

operandNames :: (Monoid r) => Asking r -> Operand.Operand -> r
operandNames asking x = case x of
  Operand.Literal _integer -> mempty
  Operand.OfSource _measure -> mempty
  Operand.Own _measure -> mempty
  Operand.OfBound bound -> boundMeasureNames asking bound
  Operand.AmountInSlot slot -> slotNames asking slot
  Operand.EnclosingAmount -> contextNames asking
  -- The other candidates' numbers: two objects alike in every respect read
  -- each other's, so the answer is the same for both.
  Operand.OfEachOtherCandidate _measure -> mempty

optionalityNames :: (Monoid r) => Asking r -> Optionality.Optionality -> r
optionalityNames asking x = case x of
  Optionality.Mandatory -> mempty
  Optionality.Optional playerRef -> playerRefNames asking playerRef

orElseNames :: (Monoid r) => Asking r -> OrElse.OrElse -> r
orElseNames asking x = case x of
  OrElse.MkOrElse _sibling chooser _villainous -> playerRefNames asking chooser

paidExpiryNames :: (Monoid r) => Asking r -> PaidExpiry.PaidExpiry -> r
paidExpiryNames asking x = case x of
  PaidExpiry.MkPaidExpiry _player cost -> costNames asking (keywordNames asking) cost

payGateNames :: (Monoid r) => Asking r -> PayGate.PayGate -> r
payGateNames asking x = case x of
  PayGate.MkPayGate payer cost basis _branch _obligation perEach chosenX _offeredAt -> playerRefNames asking payer <> costChoiceNames asking cost <> foldMap (costBasisNames asking) basis <> foldMap (quantityNames asking) perEach <> foldMap (quantityNames asking) chosenX

pendingDamageEffectNames :: (Monoid r) => Asking r -> PendingReplacementEffect.PendingReplacementEffect -> r
pendingDamageEffectNames asking x = case x of
  PendingReplacementEffect.MkPendingReplacementEffect effects targets _controller source -> foldMap (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty))) effects <> foldMap (slotNames asking) (Map.keys targets) <> foldMap (foldMap (recipientNames asking)) targets <> names asking (== source)

pendingEntryEffectNames :: (Monoid r) => Asking r -> PendingEntryEffect.PendingEntryEffect -> r
pendingEntryEffectNames asking x = case x of
  PendingEntryEffect.MkPendingEntryEffect object_ _controller effects -> names asking (== object_) <> foldMap (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty))) effects

perCreatureNames :: (Monoid r) => Asking r -> PerCreature.PerCreature -> r
perCreatureNames asking x = case x of
  PerCreature.Fixed cost -> costNames asking (keywordNames asking) cost
  PerCreature.Counted quantity -> quantityNames asking quantity

permanentBecomesDesignatedNames :: (Monoid r) => Asking r -> PermanentBecomesDesignated.PermanentBecomesDesignated -> r
permanentBecomesDesignatedNames asking x = case x of
  PermanentBecomesDesignated.MkPermanentBecomesDesignated _designation filter_ -> filterNames asking filter_

permanentCandidateNames :: (Monoid r) => Asking r -> PermanentCandidate.PermanentCandidate -> r
permanentCandidateNames asking x = case x of
  PermanentCandidate.MkPermanentCandidate source _provenance effect _ordinal -> names asking (== source) <> replacementEffectNames asking (const mempty) (grantedAbilityNames asking (const mempty)) (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty))) effect

dealsDamageToPlayerNames :: (Monoid r) => Asking r -> DealsDamageToPlayer.DealsDamageToPlayer -> r
dealsDamageToPlayerNames asking x = case x of
  DealsDamageToPlayer.MkDealsDamageToPlayer actor _recipient -> actingPermanentNames asking actor

permanentDealsCombatDamageToPlayerNames :: (Monoid r) => Asking r -> PermanentDealsCombatDamageToPlayer.PermanentDealsCombatDamageToPlayer -> r
permanentDealsCombatDamageToPlayerNames asking x = case x of
  PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer filter_ _recipient _orTheirPlaneswalkers -> filterNames asking filter_

playerActsOnNames :: (Monoid r) => Asking r -> PlayerActsOn.PlayerActsOn -> r
playerActsOnNames asking x = case x of
  PlayerActsOn.MkPlayerActsOn _player filter_ -> filterNames asking filter_

permanentTappedForManaNames :: (Monoid r) => Asking r -> PermanentTappedForMana.PermanentTappedForMana -> r
permanentTappedForManaNames asking x = case x of
  PermanentTappedForMana.MkPermanentTappedForMana _player filter_ _mana -> filterNames asking filter_

permanentsBecomeTargetedNames :: (Monoid r) => Asking r -> PermanentsBecomeTargeted.PermanentsBecomeTargeted -> r
permanentsBecomeTargetedNames asking x = case x of
  PermanentsBecomeTargeted.MkPermanentsBecomeTargeted filter_ _relation _kind -> filterNames asking filter_

permanentsDealCombatDamageToPlayerNames :: (Monoid r) => Asking r -> PermanentsDealCombatDamageToPlayer.PermanentsDealCombatDamageToPlayer -> r
permanentsDealCombatDamageToPlayerNames asking x = case x of
  PermanentsDealCombatDamageToPlayer.MkPermanentsDealCombatDamageToPlayer filter_ _recipient _oneOrMorePlayers -> filterNames asking filter_

playerAttacksWithNames :: (Monoid r) => Asking r -> PlayerAttacksWith.PlayerAttacksWith -> r
playerAttacksWithNames asking x = case x of
  PlayerAttacksWith.MkPlayerAttacksWith _player filter_ _attackers -> filterNames asking filter_

playerCounterTallyNames :: (Monoid r) => Asking r -> PlayerCounterTally.PlayerCounterTally -> r
playerCounterTallyNames asking x = case x of
  PlayerCounterTally.MkPlayerCounterTally player _kind -> playerRefNames asking player

playerCountersNames :: (Monoid r) => Asking r -> PlayerCounters.PlayerCounters -> r
playerCountersNames asking x = case x of
  PlayerCounters.MkPlayerCounters player _kind quantity -> playerRefNames asking player <> quantityNames asking quantity

playerDesignationTallyNames :: (Monoid r) => Asking r -> PlayerDesignationTally.PlayerDesignationTally -> r
playerDesignationTallyNames asking x = case x of
  PlayerDesignationTally.MkPlayerDesignationTally player _designation -> playerRefNames asking player

activationCriteriaNames :: (Monoid r) => Asking r -> ActivationCriteria.ActivationCriteria -> r
activationCriteriaNames asking x = case x of
  ActivationCriteria.MkActivationCriteria grantedBy _whichKind _whichLoyalty -> foldMap (keywordDesignatorNames asking) grantedBy

costAdditionNames :: (Monoid r) => Asking r -> CostAddition.CostAddition -> r
costAdditionNames asking x = case x of
  CostAddition.MkCostAddition components _scale -> foldMap (costComponentNames asking (keywordNames asking)) components

costChangeNames :: (Monoid r) => Asking r -> CostChange.CostChange -> r
costChangeNames asking x = case x of
  CostChange.Increase _manaCost -> mempty
  CostChange.Reduce _appliedReduction -> mempty
  CostChange.Add costAddition -> costAdditionNames asking costAddition

costModifierNames :: (Monoid r) => Asking r -> CostModifier.CostModifier -> r
costModifierNames asking x = case x of
  CostModifier.MkCostModifier subject matching whichTargets perTarget perEach onlyFirst change -> foldMap (\scope -> history asking HistoryRead.Activations <> turnScopeNames asking scope) onlyFirst <> costSubjectNames asking subject <> filterNames asking matching <> foldMap (filterNames asking) whichTargets <> foldMap (filterNames asking) perTarget <> foldMap (quantityNames asking) perEach <> costChangeNames asking change

costSubjectNames :: (Monoid r) => Asking r -> CostSubject.CostSubject -> r
costSubjectNames asking x = case x of
  CostSubject.Spells -> mempty
  CostSubject.Activations activationCriteria -> activationCriteriaNames asking activationCriteria

playerEffectNames :: (Monoid r) => Asking r -> PlayerEffect.PlayerEffect -> r
playerEffectNames asking x = case x of
  PlayerEffect.CantCastSpells -> mempty
  PlayerEffect.CantActivateAbilities keywordDesignator filter_ -> foldMap (keywordDesignatorNames asking) keywordDesignator <> filterNames asking filter_
  PlayerEffect.CantCastMoreThan _natural -> history asking HistoryRead.Casts
  PlayerEffect.ModifyCost costModifier -> costModifierNames asking costModifier
  PlayerEffect.AlternativeActivationCost alternativeActivationCost -> alternativeActivationCostNames asking alternativeActivationCost
  PlayerEffect.PlayAdditionalLands _allowance -> mempty
  PlayerEffect.NoMaximumHandSize -> mempty
  PlayerEffect.SetMaximumHandSize _natural -> mempty
  PlayerEffect.IncreaseMaximumHandSize _natural -> mempty
  PlayerEffect.ReduceMaximumHandSize _natural -> mempty
  PlayerEffect.DontLoseUnspentMana _manaFilter -> mempty
  PlayerEffect.LoseLifeForUnspentMana -> mempty
  PlayerEffect.SpendManaAsThough _spendManaAsThough -> mempty
  PlayerEffect.CantBeTargetedBy _playerScope -> mempty
  PlayerEffect.HasProtectionFrom filter_ -> filterNames asking filter_
  PlayerEffect.CastAsThoughItHadFlash filter_ -> filterNames asking filter_
  PlayerEffect.MayPlayAsThoughItHadFlash filter_ -> filterNames asking filter_
  PlayerEffect.ActivateKeywordAtInstantSpeed keywordDesignator -> keywordDesignatorNames asking keywordDesignator
  -- A once-per-turn grant is spent off CR 602.2's log, by activator
  -- (Activatable.graceUsed).
  PlayerEffect.LoyaltyGrant grant ->
    filterNames asking (LoyaltyGrant.permanents grant) <> case LoyaltyGrant.relaxes grant of
      LoyaltyClause.Window -> mempty
      LoyaltyClause.OncePerTurn -> history asking HistoryRead.Activations
  PlayerEffect.MayTapForMana tapForMana -> tapForManaNames asking tapForMana
  PlayerEffect.CantBeCountered counterProhibition -> counterProhibitionNames asking counterProhibition
  PlayerEffect.RestrictTargeting targetRestriction -> targetRestrictionNames asking (filterNames asking) targetRestriction
  PlayerEffect.DamageCantBePrevented damagePattern -> damagePatternNames asking damagePattern
  PlayerEffect.DamageCantBeRedirected damagePattern -> damagePatternNames asking damagePattern
  PlayerEffect.CantSearchLibraries _cantSearchLibraries -> mempty
  PlayerEffect.CantBecomeMonarch -> mempty
  PlayerEffect.CantSetSchemesInMotion -> mempty
  PlayerEffect.EntriesDontTrigger filter_ -> filterNames asking filter_
  PlayerEffect.ControlledWhileSearching -> mempty
  PlayerEffect.YouChoose _declaration -> mempty
  PlayerEffect.ExilesFoundWhileSearching -> mempty
  PlayerEffect.CantAttackWithCreatures -> mempty
  PlayerEffect.CantCastMatching filter_ -> filterNames asking filter_
  PlayerEffect.CastOnlyAtSorcerySpeed -> mempty
  PlayerEffect.CantPlayLands filter_ -> filterNames asking filter_
  PlayerEffect.CastFrom castFromZone -> castFromZoneNames asking castFromZone
  PlayerEffect.PlayLandsFrom inZone -> inZoneNames asking inZone
  PlayerEffect.PlotFrom plotFromZone -> plotFromZoneNames asking plotFromZone
  PlayerEffect.CastFromHandWithoutPayingManaCost filter_ -> filterNames asking filter_
  PlayerEffect.CantGetCounters _playerCounterKind -> mempty
  PlayerEffect.StateCoinFlip statedFlip -> statedFlipNames asking statedFlip
  PlayerEffect.ModifyDieRoll modifiedRoll -> modifiedRollNames asking modifiedRoll
  PlayerEffect.AdditionalVotes _extraVotes -> mempty
  PlayerEffect.AdditionalSurveilCards _natural -> mempty
  PlayerEffect.PutTappedAsYouCascade filter_ -> filterNames asking filter_
  PlayerEffect.CantGainLife -> mempty
  PlayerEffect.CantLoseLife -> mempty
  PlayerEffect.RevealsDraw _reveal -> mempty
  PlayerEffect.Precluded _outcome -> mempty
  PlayerEffect.Shows _shows -> mempty

playerChoiceNames :: (Monoid r) => Asking r -> PlayerChoice.PlayerChoice -> r
playerChoiceNames asking x = case x of
  PlayerChoice.AsEnters -> mempty
  PlayerChoice.Promised _gift instance_ -> keywordInstanceNames asking instance_

keywordInstanceNames :: (Monoid r) => Asking r -> KeywordInstance.KeywordInstance -> r
keywordInstanceNames asking x = case x of
  KeywordInstance.Own _ordinal -> mempty
  KeywordInstance.Granted objectId _timestamp _ordinal -> names asking (== objectId)

playerQuantityNames :: (Monoid r) => Asking r -> PlayerQuantity.PlayerQuantity -> r
playerQuantityNames asking x = case x of
  PlayerQuantity.MkPlayerQuantity player quantity -> playerRefNames asking player <> quantityNames asking quantity

playerRefNames :: (Monoid r) => Asking r -> PlayerRef.PlayerRef -> r
playerRefNames asking x = case x of
  PlayerRef.EachPlayerExcept slotName -> slotNames asking slotName
  PlayerRef.EachOpponentExcept slotName -> slotNames asking slotName
  PlayerRef.Relative _playerRelation -> mempty
  PlayerRef.InSlot slotName -> slotNames asking slotName
  PlayerRef.EachInSlot slotName -> slotNames asking slotName
  PlayerRef.Specific _playerId -> mempty
  PlayerRef.Candidate -> mempty
  PlayerRef.HolderOfBound _holder _hop slotName -> slotNames asking slotName
  PlayerRef.HolderOfObject _holder objectId -> names asking (== objectId)
  PlayerRef.ChosenPlayerOfBound slotName choice -> slotNames asking slotName <> playerChoiceNames asking choice
  PlayerRef.Attacking attackingPlayers -> attackingPlayersNames asking attackingPlayers
  PlayerRef.Superlative _ -> mempty
  PlayerRef.InRole _ -> mempty

playerSacrificesNames :: (Monoid r) => Asking r -> PlayerSacrifices.PlayerSacrifices -> r
playerSacrificesNames asking x = case x of
  PlayerSacrifices.MkPlayerSacrifices players filter_ quantity permanents -> playerRefNames asking players <> filterNames asking filter_ <> quantityNames asking quantity <> foldMap (slotNames asking) permanents

playerStaticAbilityNames :: (Monoid r) => Asking r -> PlayerStaticAbility.PlayerStaticAbility -> r
playerStaticAbilityNames asking x = case x of
  PlayerStaticAbility.MkPlayerStaticAbility _scope condition _name effect -> foldMap (conditionNames asking) condition <> playerEffectNames asking effect

playsLandNames :: (Monoid r) => Asking r -> PlaysLand.PlaysLand -> r
playsLandNames asking x = case x of
  PlaysLand.MkPlaysLand _player _from filter_ -> filterNames asking filter_

plotFromZoneNames :: (Monoid r) => Asking r -> PlotFromZone.PlotFromZone -> r
plotFromZoneNames asking x = case x of
  PlotFromZone.MkPlotFromZone from matching -> inZoneNames asking from <> filterNames asking matching

plusNames :: (Monoid r) => Asking r -> (quantity -> r) -> Plus.Plus quantity -> r
plusNames _asking onQuantity x = case x of
  Plus.MkPlus left right -> onQuantity left <> onQuantity right

poolNames :: (Monoid r) => Asking r -> Pool.Pool -> r
poolNames asking x = case x of
  Pool.Creatures -> mempty
  Pool.Players -> mempty
  Pool.AnyTarget -> mempty
  Pool.Permanents -> mempty
  Pool.Spells -> mempty
  Pool.Abilities -> mempty
  Pool.SpellsAndPermanents -> mempty
  Pool.PlayersAndPlaneswalkers -> mempty
  Pool.CardsInGraveyard zoneScope -> zoneScopeNames asking zoneScope
  Pool.CardsInExile -> mempty
  Pool.CardsInAnte -> mempty
  Pool.CreaturesAndCardsInGraveyard zoneScope -> zoneScopeNames asking zoneScope

powerNames :: (Monoid r) => Asking r -> Power.Power -> r
powerNames asking x = case x of
  Power.MkPower unwrap -> quantityNames asking unwrap

preventAllDamageNames :: (Monoid r) => Asking r -> (effect -> r) -> PreventAllDamage.PreventAllDamage effect -> r
preventAllDamageNames asking onEffect x = case x of
  PreventAllDamage.MkPreventAllDamage duration _kind ref whatRecipient _whoRecipient _direction chosenSource whatSource riders -> durationNames asking duration <> foldMap (objectRefNames asking) ref <> foldMap (filterNames asking) whatRecipient <> foldMap (filterNames asking) chosenSource <> filterNames asking whatSource <> foldMap onEffect riders

preventNextDamageNames :: (Monoid r) => Asking r -> (effect -> r) -> PreventNextDamage.PreventNextDamage effect -> r
preventNextDamageNames asking onEffect x = case x of
  PreventNextDamage.MkPreventNextDamage duration _kind ref whatRecipient _whoRecipient chosenSource quantity riders -> durationNames asking duration <> foldMap (objectRefNames asking) ref <> foldMap (filterNames asking) whatRecipient <> foldMap (filterNames asking) chosenSource <> quantityNames asking quantity <> foldMap onEffect riders

preventNextDamageInstanceNames :: (Monoid r) => Asking r -> (effect -> r) -> PreventNextDamageInstance.PreventNextDamageInstance effect -> r
preventNextDamageInstanceNames asking onEffect x = case x of
  PreventNextDamageInstance.MkPreventNextDamageInstance duration ref chosenSource riders -> durationNames asking duration <> objectRefNames asking ref <> filterNames asking chosenSource <> foldMap onEffect riders

preventionNames :: (Monoid r) => Asking r -> Prevention.Prevention -> r
preventionNames asking x = case x of
  Prevention.MkPrevention by amounts rider -> candidateIdNames asking by <> names asking (`Map.member` amounts) <> foldMap (foldMap (recipientNames asking) . Map.keys) amounts <> foldMap (preventionRiderNames asking) rider

preventionRiderNames :: (Monoid r) => Asking r -> PreventionRider.PreventionRider -> r
preventionRiderNames asking x = case x of
  PreventionRider.MkPreventionRider effects targets _controller source -> foldMap (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty))) effects <> foldMap (slotNames asking) (Map.keys targets) <> foldMap (foldMap (recipientNames asking)) targets <> names asking (== source)

printedReplacementNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> (effect -> r) -> PrintedReplacement.PrintedReplacement card ability effect -> r
printedReplacementNames asking onCard onAbility onEffect x = case x of
  PrintedReplacement.MkPrintedReplacement condition effect _functionsFrom _name -> foldMap (conditionNames asking) condition <> replacementEffectNames asking onCard onAbility onEffect effect

projectedCharacteristicsNames :: (Monoid r) => Asking r -> ProjectedCharacteristics.ProjectedCharacteristics -> r
projectedCharacteristicsNames asking x = case x of
  ProjectedCharacteristics.MkProjectedCharacteristics _names _supertypes keywords _colors _manaCost _manaValue _power _toughness _loyalty _defense _intensity characteristicPT _cardTypes _subtypes staticAbilities playerAbilities grantedPlayerAbilities grantedStaticAbilities grantedRuleAbilities specialActions activatedAbilities replacementEffects triggeredAbilities delayedAbilities enchant _castingPermissions ruleAbilities _lostAllAbilities _hasFullText _wordChanges textChangedKeywords _assignsCombatDamageWithToughness _combatDamageOptions _grantsStationToughness additionalCosts additionalCostChoices alternativeCosts costReductions grantedCostReductions grantedAlternativeCosts _grantedSpendManaAsThough _halves exceptions mergedDonors prepare alternativeSpell _prototyped spell flipped -> foldMap (keywordNames asking) (Map.keys keywords) <> foldMap (characteristicPTNames asking) characteristicPT <> foldMap (staticAbilityNames asking (grantedAbilityNames asking (const mempty))) staticAbilities <> foldMap (playerStaticAbilityNames asking) playerAbilities <> foldMap (playerStaticAbilityNames asking . snd) grantedPlayerAbilities <> foldMap (staticAbilityNames asking (grantedAbilityNames asking (const mempty)) . snd) grantedStaticAbilities <> ruleAbilitiesNames asking grantedRuleAbilities <> foldMap (specialActionNames asking) specialActions <> foldMap (activatedAbilityNames asking (const mempty) (grantedAbilityNames asking (const mempty))) activatedAbilities <> foldMap (printedReplacementNames asking (const mempty) (grantedAbilityNames asking (const mempty)) (effectNames asking (const mempty) (grantedAbilityNames asking (const mempty)))) replacementEffects <> foldMap (triggeredAbilityNames asking (const mempty) (grantedAbilityNames asking (const mempty))) triggeredAbilities <> foldMap (triggeredAbilityNames asking (const mempty) (grantedAbilityNames asking (const mempty))) delayedAbilities <> foldMap (targetSlotNames asking) enchant <> ruleAbilitiesNames asking ruleAbilities <> foldMap (keywordNames asking) (Map.keys textChangedKeywords) <> foldMap (costComponentNames asking (keywordNames asking)) additionalCosts <> foldMap (costChoiceNames asking) additionalCostChoices <> foldMap (alternativeCostNames asking) alternativeCosts <> foldMap (costReductionNames asking) costReductions <> foldMap (costReductionNames asking) grantedCostReductions <> foldMap (alternativeCostNames asking) grantedAlternativeCosts <> foldMap (copyExceptionNames asking (grantedAbilityNames asking (const mempty))) exceptions <> foldMap (projectedCharacteristicsNames asking) mergedDonors <> foldMap (faceNames asking (const mempty)) prepare <> foldMap (faceNames asking (const mempty)) alternativeSpell <> modalNames asking (const mempty) (grantedAbilityNames asking (const mempty)) spell <> foldMap (projectedCharacteristicsNames asking) flipped

-- What is prohibited names no object.
prohibitNames :: (Monoid r) => Asking r -> Prohibit.Prohibit -> r
prohibitNames asking x = case x of
  Prohibit.MkProhibit _what duration affected -> durationNames asking duration <> restrictedCreaturesNames asking (objectRefNames asking) affected

protectionNames :: (Monoid r) => Asking r -> Protection.Protection keyword -> r
protectionNames asking x = case x of
  Protection.MkProtection quality spares -> filterNames asking quality <> foldMap (filterNames asking) spares

putCountersNames :: (Monoid r) => Asking r -> PutCounters.PutCounters -> r
putCountersNames asking x = case x of
  PutCounters.MkPutCounters kind quantity ref -> counterKindNames asking (keywordNames asking) kind <> quantityNames asking quantity <> objectRefNames asking ref

putCountersFromNames :: (Monoid r) => Asking r -> PutCountersFrom.PutCountersFrom -> r
putCountersFromNames asking x = case x of
  PutCountersFrom.MkPutCountersFrom from kind ref -> slotNames asking from <> foldMap (counterKindNames asking (keywordNames asking)) kind <> objectRefNames asking ref

quantityNames :: (Monoid r) => Asking r -> Quantity.Quantity -> r
quantityNames asking x = case x of
  Quantity.Literal _integer -> mempty
  Quantity.Measure _ -> mempty
  Quantity.Intensity -> mempty
  Quantity.InSlot slotName -> slotNames asking slotName
  Quantity.Share slotName -> slotNames asking slotName
  Quantity.WasBound slotName -> slotNames asking slotName
  Quantity.BoundCount slotName -> slotNames asking slotName
  Quantity.UniqueVowelsOnSticker slotName -> slotNames asking slotName
  Quantity.VotesReceived votesReceived -> slotNames asking (VotesReceived.slot votesReceived) <> playerRefNames asking (VotesReceived.player votesReceived)
  Quantity.Star -> mempty
  Quantity.Arithmetic arithmetic -> arithmeticNames asking (quantityNames asking) arithmetic
  Quantity.Count count -> countNames asking (quantityNames asking) count
  Quantity.ManaCount manaCount -> manaCountNames asking manaCount
  Quantity.LifeTotal playerRef -> playerRefNames asking playerRef
  Quantity.StartingLifeTotal playerRef -> playerRefNames asking playerRef
  Quantity.Speed playerRef -> playerRefNames asking playerRef
  Quantity.IsMonarch playerRef -> playerRefNames asking playerRef
  Quantity.HasPlayerDesignation playerDesignationTally -> playerDesignationTallyNames asking playerDesignationTally
  Quantity.IsStartingPlayer playerRef -> playerRefNames asking playerRef
  Quantity.IsActivePlayer playerRef -> playerRefNames asking playerRef
  Quantity.Devotion devotion -> devotionNames asking devotion
  Quantity.PartySize playerRef -> playerRefNames asking playerRef
  Quantity.PlayerCounters playerCounterTally -> playerCounterTallyNames asking playerCounterTally
  Quantity.ObjectCounters counterKind -> counterKindNames asking (keywordNames asking) counterKind
  Quantity.ObjectCountersOfAnyKind -> mempty
  Quantity.LettersOnNameStickers _ -> mempty
  Quantity.NameStickers -> mempty
  Quantity.PowerOfStickers -> mempty
  Quantity.ToughnessOfStickers -> mempty
  Quantity.HasDesignation _designation -> mempty
  Quantity.DesignationValue _designation -> mempty
  Quantity.StoredResultsOfSameValue -> mempty
  Quantity.ClassLevel -> mempty
  Quantity.WasForetold -> mempty
  Quantity.TributeWasPaid -> mempty
  Quantity.TimesPaid designator -> keywordDesignatorNames asking designator
  Quantity.CastUsing designator -> keywordDesignatorNames asking designator
  Quantity.TagWasSpent _productionTag -> mempty
  Quantity.TagWasSpentOfOwnColor _productionTag -> mempty
  Quantity.ChosenColorsItIs -> mempty
  Quantity.ManaSpent -> mempty
  Quantity.WasToken -> mempty
  Quantity.WasAttacking -> mempty
  Quantity.WasBlocking -> mempty
  Quantity.WasBlockedThisTurn -> history asking HistoryRead.Blocks
  Quantity.ControlGainedSinceLastUpkeep playerRef -> playerRefNames asking playerRef
  Quantity.PlayedBy playerRef -> playerRefNames asking playerRef
  Quantity.OpponentsAttacked playerRef -> playerRefNames asking playerRef
  Quantity.AttackersDeclaredThisTurn playerRef -> history asking HistoryRead.Attacks <> playerRefNames asking playerRef
  Quantity.AttackersDeclaredThisCombat -> mempty
  Quantity.AttackedInLastTurnOf playerRef -> playerRefNames asking playerRef
  Quantity.AttackersInTheirLastTurn playerRef -> history asking HistoryRead.Attacks <> playerRefNames asking playerRef
  Quantity.CardsDiscardedThisTurn playerRef -> history asking HistoryRead.Discards <> playerRefNames asking playerRef
  Quantity.CardsDrawnThisTurn playerRef -> playerRefNames asking playerRef
  Quantity.BendingsThisTurn playerRef -> history asking HistoryRead.Bendings <> playerRefNames asking playerRef
  Quantity.LifeGainedThisTurn playerRef -> history asking HistoryRead.LifeGains <> playerRefNames asking playerRef
  Quantity.PlayersDealtDamageThisTurn tally -> history asking HistoryRead.Damage <> playerRefNames asking (DealtDamage.recipient tally)
  Quantity.DamageDealtToPlayersThisTurn playerRef -> history asking HistoryRead.Damage <> playerRefNames asking playerRef
  Quantity.DamageDealtToThisTurn -> history asking HistoryRead.Damage
  Quantity.SpellsCastLastTurn playerRef -> playerRefNames asking playerRef
  Quantity.SpellsCastThisTurn playerRef -> history asking HistoryRead.Casts <> playerRefNames asking playerRef
  Quantity.TimesThisTurn act -> history asking $ case act of
    AbilityAct.Activated -> HistoryRead.Activations
    AbilityAct.Resolved -> HistoryRead.Resolutions
  Quantity.ActivationsThisTurn tally -> history asking HistoryRead.Activations <> playerRefNames asking (ActivationsThisTurn.activator tally) <> filterNames asking (ActivationsThisTurn.source tally) <> activationCriteriaNames asking (ActivationsThisTurn.criteria tally)
  Quantity.SpellsCastBefore -> history asking HistoryRead.Casts
  Quantity.PermanentsDiedThisTurn -> history asking HistoryRead.Deaths
  Quantity.SpellsCastUsingThisTurn _keywordFamily -> history asking HistoryRead.Casts
  Quantity.SubgamesThisMatch -> mempty
  Quantity.DungeonsCompleted playerRef -> playerRefNames asking playerRef
  Quantity.CommanderCasts playerRef -> playerRefNames asking playerRef
  Quantity.CompletedDungeon completedDungeon -> completedDungeonNames asking completedDungeon
  Quantity.EnteredThisTurn -> history asking HistoryRead.Entries
  Quantity.EnteredFrom inZone -> history asking HistoryRead.Entries <> inZoneNames asking inZone
  Quantity.WasCastFrom castFrom -> history asking HistoryRead.Entries <> history asking HistoryRead.Casts <> castFromNames asking castFrom
  Quantity.BlockersBeyond _ -> mempty
  Quantity.AgainstSlot againstSlot -> againstSlotNames asking (quantityNames asking) againstSlot
  Quantity.AgainstExiledPile (AgainstExiledPile.MkAgainstExiledPile _pile quantity) -> quantityNames asking quantity
  Quantity.AgainstLastCardExiledWith againstLastCardExiledWith -> againstLastCardExiledWithNames asking (quantityNames asking) againstLastCardExiledWith
  Quantity.StationMeasure -> mempty

randomCardInGraveyardNames :: (Monoid r) => Asking r -> RandomCardInGraveyard.RandomCardInGraveyard -> r
randomCardInGraveyardNames asking x = case x of
  RandomCardInGraveyard.MkRandomCardInGraveyard players filter_ count -> zoneScopeNames asking players <> filterNames asking filter_ <> quantityNames asking count

randomCardInHandNames :: (Monoid r) => Asking r -> RandomCardInHand.RandomCardInHand -> r
randomCardInHandNames asking x = case x of
  RandomCardInHand.MkRandomCardInHand player filter_ count -> playerRefNames asking player <> filterNames asking filter_ <> quantityNames asking count

randomCardInLibraryNames :: (Monoid r) => Asking r -> RandomCardInLibrary.RandomCardInLibrary -> r
randomCardInLibraryNames asking x = case x of
  RandomCardInLibrary.MkRandomCardInLibrary player filter_ count -> playerRefNames asking player <> filterNames asking filter_ <> quantityNames asking count

recipientNames :: (Monoid r) => Asking r -> Recipient.Recipient -> r
recipientNames asking x = case x of
  Recipient.ToCreature objectId -> names asking (== objectId)
  Recipient.ToPlaneswalker objectId -> names asking (== objectId)
  Recipient.ToBattle objectId -> names asking (== objectId)
  Recipient.ToPlayer _playerId -> mempty
  Recipient.ToObject objectId -> names asking (== objectId)
  Recipient.ToPile _pile -> mempty

redirectDamageNames :: (Monoid r) => Asking r -> RedirectDamage.RedirectDamage -> r
redirectDamageNames asking x = case x of
  RedirectDamage.MkRedirectDamage duration _kind amount from whatRecipient _whoRecipient to chosenSource _uses whatSource -> durationNames asking duration <> foldMap (quantityNames asking) amount <> foldMap (objectRefNames asking) from <> foldMap (filterNames asking) whatRecipient <> objectRefNames asking to <> foldMap (filterNames asking) chosenSource <> filterNames asking whatSource

reinforceNames :: (Monoid r) => Asking r -> (keyword -> r) -> Reinforce.Reinforce keyword -> r
reinforceNames asking onKeyword x = case x of
  Reinforce.MkReinforce _amount cost -> costNames asking onKeyword cost

removalCountNames :: (Monoid r) => Asking r -> RemovalCount.RemovalCount -> r
removalCountNames asking x = case x of
  RemovalCount.Exactly quantity -> quantityNames asking quantity
  RemovalCount.UpTo quantity -> quantityNames asking quantity
  RemovalCount.AnyNumber -> mempty

removeCountersNames :: (Monoid r) => Asking r -> RemoveCounters.RemoveCounters -> r
removeCountersNames asking x = case x of
  RemoveCounters.MkRemoveCounters kind quantity slot tally -> counterKindNames asking (keywordNames asking) kind <> quantityNames asking quantity <> slotNames asking slot <> foldMap (slotNames asking) tally

removePlayerCountersNames :: (Monoid r) => Asking r -> RemovePlayerCounters.RemovePlayerCounters -> r
removePlayerCountersNames asking x = case x of
  RemovePlayerCounters.MkRemovePlayerCounters player _kind quantity tally -> playerRefNames asking player <> quantityNames asking quantity <> foldMap (slotNames asking) tally

removeCountersAmongNames :: (Monoid r) => Asking r -> RemoveCountersAmong.RemoveCountersAmong -> r
removeCountersAmongNames asking x = case x of
  RemoveCountersAmong.MkRemoveCountersAmong count from kind tally -> removalCountNames asking count <> objectRefNames asking from <> whichCountersNames asking (keywordNames asking) kind <> foldMap (slotNames asking) tally

repeatNames :: (Monoid r) => Asking r -> (effect -> r) -> Repeat.Repeat effect -> r
repeatNames asking onEffect x = case x of
  Repeat.MkRepeat chooser body gate -> playerRefNames asking chooser <> foldMap onEffect body <> foldMap (conditionNames asking) gate

repeatIfNames :: (Monoid r) => Asking r -> (effect -> r) -> RepeatIf.RepeatIf effect -> r
repeatIfNames asking onEffect x = case x of
  RepeatIf.MkRepeatIf process condition ifHolds -> foldMap onEffect process <> conditionNames asking condition <> foldMap onEffect ifHolds

replaceNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> (effect -> r) -> Replace.Replace card ability effect -> r
replaceNames asking onCard onAbility onEffect x = case x of
  Replace.MkReplace duration _uses _origin condition effect -> durationNames asking duration <> foldMap (conditionNames asking) condition <> replacementEffectNames asking onCard onAbility onEffect effect

replacementEffectNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> (effect -> r) -> ReplacementEffect.ReplacementEffect card ability effect -> r
replacementEffectNames asking onCard onAbility onEffect x = case x of
  ReplacementEffect.ZoneChangeR zoneChangeR -> zoneChangeRNames asking zoneChangeR
  ReplacementEffect.EntryR entryR -> entryRNames asking onAbility onEffect entryR
  ReplacementEffect.DamageR damageR -> damageRNames asking onEffect damageR
  ReplacementEffect.DestructionR destructionR -> destructionRNames asking destructionR
  ReplacementEffect.CounterR counterR -> counterRNames asking counterR
  ReplacementEffect.TokenR tokenR -> tokenRNames asking onCard tokenR
  ReplacementEffect.TurnUpR turnUpR -> turnUpRNames asking onAbility onEffect turnUpR
  ReplacementEffect.AttachR attachR -> attachRNames asking onAbility onEffect attachR
  ReplacementEffect.UntapR untapR -> untapRNames asking untapR
  ReplacementEffect.LifeLossR lifeLossR -> lifeLossRNames asking lifeLossR
  ReplacementEffect.LifeGainR lifeGainR -> lifeGainRNames asking lifeGainR
  ReplacementEffect.DrawR drawR -> drawRNames asking drawR
  ReplacementEffect.DrawCountR drawCountR -> drawCountRNames asking drawCountR
  ReplacementEffect.InstructionR instructionR -> instructionRNames asking instructionR
  ReplacementEffect.DieRollR dieRollR -> dieRollRNames asking dieRollR
  ReplacementEffect.AssembleR matching -> filterNames asking matching
  ReplacementEffect.ManaR (ManaR.MkManaR matching _) -> filterNames asking matching
  ReplacementEffect.GameLossR (GameLossR.MkGameLossR whose effects) -> controllerRelationNames asking whose <> foldMap onEffect effects
  ReplacementEffect.PlaneswalkR (PlaneswalkR.MkPlaneswalkR whose _cause rewrite) ->
    controllerRelationNames asking whose <> case rewrite of
      PlaneswalkRewrite.ArrangeTopTwo -> mempty
      PlaneswalkRewrite.RunEffects effects -> foldMap onEffect effects
  ReplacementEffect.PhaseR _phasePattern -> mempty

requireAttackNames :: (Monoid r) => Asking r -> RequireAttack.RequireAttack -> r
requireAttackNames asking x = case x of
  RequireAttack.MkRequireAttack duration attacker defender -> durationNames asking duration <> restrictedCreaturesNames asking (objectRefNames asking) attacker <> foldMap (attackTargetRefNames asking) defender

requireBlockNames :: (Monoid r) => Asking r -> RequireBlock.RequireBlock -> r
requireBlockNames asking x = case x of
  RequireBlock.MkRequireBlock duration blocker attacker _ -> durationNames asking duration <> restrictedCreaturesNames asking (objectRefNames asking) blocker <> foldMap (restrictedCreaturesNames asking (objectRefNames asking)) attacker

restrictedCreaturesNames :: (Monoid r) => Asking r -> (named -> r) -> RestrictedCreatures.RestrictedCreatures named -> r
restrictedCreaturesNames asking onNamed x = case x of
  RestrictedCreatures.Named named -> onNamed named
  RestrictedCreatures.Matching filter_ -> filterNames asking filter_

exilePermanentsNames :: (Monoid r) => Asking r -> ExilePermanents.ExilePermanents keyword -> r
exilePermanentsNames asking x = case x of
  ExilePermanents.MkExilePermanents _count whichPermanents -> filterNames asking whichPermanents

returnPermanentsNames :: (Monoid r) => Asking r -> ReturnPermanents.ReturnPermanents keyword -> r
returnPermanentsNames asking x = case x of
  ReturnPermanents.MkReturnPermanents _count whichPermanents -> filterNames asking whichPermanents

revealNames :: (Monoid r) => Asking r -> Reveal.Reveal -> r
revealNames asking x = case x of
  Reveal.MkReveal ref slot -> objectRefNames asking ref <> foldMap (slotNames asking) slot

rollDieNames :: (Monoid r) => Asking r -> RollDie.RollDie -> r
rollDieNames asking x = case x of
  RollDie.MkRollDie _sides count modifier _reading slot other _roller highest store -> quantityNames asking count <> foldMap (quantityNames asking) modifier <> slotNames asking slot <> foldMap (slotNames asking) other <> foldMap (slotNames asking) highest <> foldMap (slotNames asking) store

ruleAbilitiesNames :: (Monoid r) => Asking r -> RuleAbilities.RuleAbilities -> r
ruleAbilitiesNames asking x = case x of
  RuleAbilities.MkRuleAbilities activationProhibitions attachRestrictions attackCosts attackPermissions attackRequirements blockCosts blockPermissions blockRequirements combatRestrictions counterRestrictions crewRestrictions entryRestrictions sacrificeRestrictions targetRestrictions untapRestrictions -> foldMap (activationProhibitionNames asking) activationProhibitions <> foldMap (attachRestrictionNames asking) attachRestrictions <> foldMap (attackCostNames asking) attackCosts <> foldMap (attackPermissionNames asking) attackPermissions <> foldMap (attackRequirementNames asking) attackRequirements <> foldMap (blockCostNames asking) blockCosts <> foldMap (blockPermissionNames asking) blockPermissions <> foldMap (blockRequirementNames asking) blockRequirements <> foldMap (combatRestrictionNames asking) combatRestrictions <> foldMap (counterRestrictionNames asking) counterRestrictions <> foldMap (crewRestrictionNames asking) crewRestrictions <> foldMap (entryRestrictionNames asking) entryRestrictions <> foldMap (sacrificeRestrictionNames asking) sacrificeRestrictions <> foldMap (targetRestrictionNames asking (affectedNames asking)) targetRestrictions <> foldMap (untapRestrictionNames asking) untapRestrictions

sacrificeNames :: (Monoid r) => Asking r -> Sacrifice.Sacrifice keyword -> r
sacrificeNames asking x = case x of
  Sacrifice.MkSacrifice count whichPermanents -> objectCountNames asking count <> filterNames asking whichPermanents

exileFromGraveyardNames :: (Monoid r) => Asking r -> ExileFromGraveyard.ExileFromGraveyard -> r
exileFromGraveyardNames asking x = case x of
  ExileFromGraveyard.MkExileFromGraveyard filter_ _players count _orGraveyard kinds each -> filterNames asking filter_ <> foldMap (quantityNames asking) (HowMany.quantity count) <> foldMap (counterKindNames asking (keywordNames asking)) kinds <> quantityNames asking each

sacrificeAnyNumberNames :: (Monoid r) => Asking r -> SacrificeAnyNumber.SacrificeAnyNumber -> r
sacrificeAnyNumberNames asking x = case x of
  SacrificeAnyNumber.MkSacrificeAnyNumber filter_ kind each -> filterNames asking filter_ <> foldMap (counterKindNames asking (keywordNames asking)) kind <> quantityNames asking each

sacrificeEffectNames :: (Monoid r) => Asking r -> SacrificeEffect.SacrificeEffect -> r
sacrificeEffectNames asking x = case x of
  SacrificeEffect.MkSacrificeEffect ref _sacrificer sacrificed -> objectRefNames asking ref <> foldMap (slotNames asking) sacrificed

sacrificeRestrictionNames :: (Monoid r) => Asking r -> SacrificeRestriction.SacrificeRestriction -> r
sacrificeRestrictionNames asking x = case x of
  SacrificeRestriction.MkSacrificeRestriction affected -> affectedNames asking affected

sacrificeToEnterNames :: (Monoid r) => Asking r -> SacrificeToEnter.SacrificeToEnter -> r
sacrificeToEnterNames asking x = case x of
  SacrificeToEnter.MkSacrificeToEnter _count filter_ -> filterNames asking filter_

scopeNames :: (Monoid r) => Asking r -> Scope.Scope -> r
scopeNames asking x = case x of
  Scope.InZone inZone -> inZoneNames asking inZone
  Scope.InHistory eventShape -> eventShapeNames asking eventShape
  Scope.OverPlayers playerRef -> playerRefNames asking playerRef
  Scope.OverBound slotName -> slotNames asking slotName
  Scope.TopOf inZone -> inZoneNames asking inZone

searchNames :: (Monoid r) => Asking r -> Search.Search -> r
searchNames asking x = case x of
  Search.MkSearch searcher owner _zones _outsideTheGame quantity filter_ descriptions _upTo _destination subject slot _differentIn _exactly _andOr -> playerRefNames asking searcher <> playerRefNames asking owner <> foldMap (quantityNames asking) quantity <> filterNames asking filter_ <> foldMap (filterNames asking) descriptions <> foldMap (slotNames asking) subject <> foldMap (slotNames asking) slot

selfCountersReachedNames :: (Monoid r) => Asking r -> SelfCountersReached.SelfCountersReached -> r
selfCountersReachedNames asking x = case x of
  SelfCountersReached.MkSelfCountersReached kind _amount -> counterKindNames asking (keywordNames asking) kind

selfCountersRemovedNames :: (Monoid r) => Asking r -> SelfCountersRemoved.SelfCountersRemoved -> r
selfCountersRemovedNames asking x = case x of
  SelfCountersRemoved.MkSelfCountersRemoved kind -> counterKindNames asking (keywordNames asking) kind

setBasePowerToughnessNames :: (Monoid r) => Asking r -> SetBasePowerToughness.SetBasePowerToughness -> r
setBasePowerToughnessNames asking x = case x of
  SetBasePowerToughness.MkSetBasePowerToughness power toughness -> foldMap (quantityNames asking) power <> foldMap (quantityNames asking) toughness

setClassLevelNames :: Asking r -> SetClassLevel.SetClassLevel -> r
setClassLevelNames asking x = case x of
  SetClassLevel.MkSetClassLevel _level slot -> slotNames asking slot

setHalfLockedNames :: Asking r -> SetHalfLocked.SetHalfLocked -> r
setHalfLockedNames asking x = case x of
  SetHalfLocked.MkSetHalfLocked _every _locked slot -> slotNames asking slot

anteNames :: (Monoid r) => Asking r -> Ante.Ante -> r
anteNames asking x = case x of
  Ante.MkAnte player ref slot -> playerRefNames asking player <> objectRefNames asking ref <> foldMap (slotNames asking) slot

putStickerNames :: (Monoid r) => Asking r -> PutSticker.PutSticker -> r
putStickerNames asking x = case x of
  PutSticker.MkPutSticker player ref _kinds cap _free bound -> playerRefNames asking player <> objectRefNames asking ref <> foldMap (quantityNames asking) cap <> foldMap (slotNames asking) bound

shuffleIntoLibraryNames :: (Monoid r) => Asking r -> ShuffleIntoLibrary.ShuffleIntoLibrary -> r
shuffleIntoLibraryNames asking x = case x of
  ShuffleIntoLibrary.MkShuffleIntoLibrary library refs slot -> foldMap (playerRefNames asking) library <> foldMap (objectRefNames asking) refs <> foldMap (slotNames asking) slot

skipPhaseNames :: (Monoid r) => Asking r -> SkipPhase.SkipPhase -> r
skipPhaseNames asking x = case x of
  SkipPhase.MkSkipPhase player _selector _uses duration -> playerRefNames asking player <> durationNames asking duration

slotCountNames :: (Monoid r) => Asking r -> SlotCount.SlotCount -> r
slotCountNames asking x = case x of
  SlotCount.Printed _targetCount -> mempty
  SlotCount.AnnouncedX -> mempty
  SlotCount.UpToAnnouncedX -> mempty
  SlotCount.UpToComputed quantity -> quantityNames asking quantity

slotPerPlayerNames :: Asking r -> SlotPerPlayer.SlotPerPlayer -> r
slotPerPlayerNames asking x = case x of
  SlotPerPlayer.MkSlotPerPlayer _players slot -> slotNames asking slot

specialActionNames :: (Monoid r) => Asking r -> SpecialAction.SpecialAction -> r
specialActionNames asking x = case x of
  SpecialAction.DiscardThisAnyTime -> mempty
  SpecialAction.IgnoreThisUntilEndOfTurn _abilityName cost -> costNames asking (keywordNames asking) cost

speedDecreaseNames :: (Monoid r) => Asking r -> SpeedDecrease.SpeedDecrease -> r
speedDecreaseNames asking x = case x of
  SpeedDecrease.MkSpeedDecrease player quantity _floor_ -> playerRefNames asking player <> quantityNames asking quantity

spellCastNames :: (Monoid r) => Asking r -> SpellCast.SpellCast -> r
spellCastNames asking x = case x of
  SpellCast.MkSpellCast filter_ scope _zone ordinal _phase _copies -> filterNames asking filter_ <> turnScopeNames asking scope <> foldMap (const (history asking HistoryRead.Casts)) ordinal

spliceNames :: (Monoid r) => Asking r -> (keyword -> r) -> Splice.Splice keyword -> r
spliceNames asking onKeyword x = case x of
  Splice.MkSplice onto cost -> filterNames asking onto <> costNames asking onKeyword cost

statedFlipNames :: (Monoid r) => Asking r -> StatedFlip.StatedFlip -> r
statedFlipNames asking x = case x of
  StatedFlip.MkStatedFlip _face _wins firstEachTurn -> if firstEachTurn then history asking HistoryRead.CoinFlips else mempty

stepBeginsNames :: (Monoid r) => Asking r -> StepBegins.StepBegins -> r
stepBeginsNames asking x = case x of
  StepBegins.MkStepBegins _phase ordinal scope -> foldMap (const (history asking HistoryRead.StepBegins)) ordinal <> turnScopeNames asking scope

-- CR 102.1: a named player's turn reads whatever its reference reads.
turnScopeNames :: (Monoid r) => Asking r -> TurnScope.TurnScope -> r
turnScopeNames asking x = case x of
  TurnScope.EachTurn -> mempty
  TurnScope.ControllersTurn -> mempty
  TurnScope.OpponentsTurn -> mempty
  TurnScope.PlayersTurn playerRef -> playerRefNames asking playerRef

duringPhaseNames :: (Monoid r) => Asking r -> DuringPhase.DuringPhase -> r
duringPhaseNames asking x = case x of
  DuringPhase.MkDuringPhase _window scope -> turnScopeNames asking scope

staticAbilityNames :: (Monoid r) => Asking r -> (ability -> r) -> StaticAbility.StaticAbility ability -> r
staticAbilityNames asking onAbility x = case x of
  StaticAbility.MkStaticAbility affected condition _functionsFrom lingers _name modifications -> affectedNames asking affected <> foldMap (conditionNames asking) condition <> foldMap (durationNames asking) lingers <> foldMap (modificationNames asking onAbility) modifications

suspendNames :: (Monoid r) => Asking r -> (keyword -> r) -> Suspend.Suspend keyword -> r
suspendNames asking onKeyword x = case x of
  Suspend.MkSuspend _counters cost -> costNames asking onKeyword cost

takeExtraTurnNames :: (Monoid r) => Asking r -> TakeExtraTurn.TakeExtraTurn -> r
takeExtraTurnNames asking x = case x of
  TakeExtraTurn.MkTakeExtraTurn player _skips count -> playerRefNames asking player <> quantityNames asking count

tapNames :: (Monoid r) => Asking r -> Tap.Tap -> r
tapNames asking x = case x of
  Tap.MkTap ref tapped -> objectRefNames asking ref <> foldMap (slotNames asking) tapped

tapForTotalPowerNames :: (Monoid r) => Asking r -> TapForTotalPower.TapForTotalPower keyword -> r
tapForTotalPowerNames asking x = case x of
  TapForTotalPower.MkTapForTotalPower _totalPower whichPermanents -> filterNames asking whichPermanents

tapPermanentsNames :: (Monoid r) => Asking r -> TapPermanents.TapPermanents keyword -> r
tapPermanentsNames asking x = case x of
  TapPermanents.MkTapPermanents count whichPermanents _sharingACreatureType -> costAmountNames asking count <> filterNames asking whichPermanents

targetSlotNames :: (Monoid r) => Asking r -> TargetSlot.TargetSlot -> r
targetSlotNames asking x = case x of
  TargetSlot.MkTargetSlot pool filter_ count amount chooser perPlayer divided _together -> poolNames asking pool <> foldMap (filterNames asking) filter_ <> slotCountNames asking count <> foldMap (quantityNames asking) amount <> foldMap (playerRefNames asking) chooser <> foldMap (slotPerPlayerNames asking) perPlayer <> foldMap (quantityNames asking) divided

theseDiscardNames :: (Monoid r) => Asking r -> TheseDiscard.TheseDiscard -> r
theseDiscardNames asking x = case x of
  TheseDiscard.MkTheseDiscard cards discarded -> objectRefNames asking cards <> foldMap (slotNames asking) discarded

timesNames :: Asking r -> (quantity -> r) -> Times.Times quantity -> r
timesNames _asking onQuantity x = case x of
  Times.MkTimes _factor quantity -> onQuantity quantity

tokenPatternNames :: (Monoid r) => Asking r -> TokenPattern.TokenPattern -> r
tokenPatternNames asking x = case x of
  TokenPattern.MkTokenPattern whose whatToken -> controllerRelationNames asking whose <> filterNames asking whatToken

tokenPlusNames :: Asking r -> (card -> r) -> TokenPlus.TokenPlus card -> r
tokenPlusNames _asking onCard x = case x of
  TokenPlus.One card -> onCard card
  TokenPlus.ThatMany card -> onCard card

tokenRNames :: (Monoid r) => Asking r -> (card -> r) -> TokenR.TokenR card -> r
tokenRNames asking onCard x = case x of
  TokenR.MkTokenR matching _scaling plus -> tokenPatternNames asking matching <> foldMap (tokenPlusNames asking onCard) plus

topOfLibraryNames :: (Monoid r) => Asking r -> TopOfLibrary.TopOfLibrary -> r
topOfLibraryNames asking x = case x of
  TopOfLibrary.MkTopOfLibrary player count -> playerRefNames asking player <> quantityNames asking count

topOfLibraryUntilNames :: (Monoid r) => Asking r -> TopOfLibraryUntil.TopOfLibraryUntil -> r
topOfLibraryUntilNames asking x = case x of
  TopOfLibraryUntil.MkTopOfLibraryUntil player filter_ count -> playerRefNames asking player <> filterNames asking filter_ <> quantityNames asking count

toughnessNames :: (Monoid r) => Asking r -> Toughness.Toughness -> r
toughnessNames asking x = case x of
  Toughness.MkToughness unwrap -> quantityNames asking unwrap

triggerConditionNames :: (Monoid r) => Asking r -> TriggerCondition.TriggerCondition -> r
triggerConditionNames asking x = case x of
  TriggerCondition.SelfEnters -> mempty
  TriggerCondition.PermanentEnters filter_ -> filterNames asking filter_
  TriggerCondition.PermanentsEnter filter_ -> filterNames asking filter_
  TriggerCondition.StepBegins stepBegins -> stepBeginsNames asking stepBegins
  TriggerCondition.StateIs condition -> conditionNames asking condition
  TriggerCondition.SelfDealsCombatDamageToPlayer _playerRelation -> mempty
  TriggerCondition.SelfDealsCombatDamageToPlayerOrBattle -> mempty
  TriggerCondition.DealsCombatDamage actingPermanent -> actingPermanentNames asking actingPermanent
  TriggerCondition.DealsDamageToPlayer dealsDamageToPlayer -> dealsDamageToPlayerNames asking dealsDamageToPlayer
  TriggerCondition.SelfDealsDamageToCreature _ -> mempty
  TriggerCondition.DealsDamage actingPermanent -> actingPermanentNames asking actingPermanent
  TriggerCondition.IsDealtDamage dealt -> actingPermanentNames asking (DealtDamage.recipient dealt)
  TriggerCondition.PlayerIsDealtDamage _playerIsDealtDamage -> mempty
  TriggerCondition.PermanentDealsCombatDamageToPlayer permanentDealsCombatDamageToPlayer -> permanentDealsCombatDamageToPlayerNames asking permanentDealsCombatDamageToPlayer
  TriggerCondition.PermanentsDealCombatDamageToPlayer permanentsDealCombatDamageToPlayer -> permanentsDealCombatDamageToPlayerNames asking permanentsDealCombatDamageToPlayer
  TriggerCondition.CreatureDealtCombatDamageToMonarch -> mempty
  TriggerCondition.CreaturesDealtCombatDamageToInitiative -> mempty
  TriggerCondition.PlayerTookInitiative -> mempty
  TriggerCondition.OpponentLostLifeDuringYourTurn -> mempty
  TriggerCondition.SelfCycled -> mempty
  TriggerCondition.SelfRevealedForMiracle -> mempty
  TriggerCondition.RevealedThisWay (RevealedThisWay.MkRevealedThisWay filter_ _timing) -> filterNames asking filter_
  TriggerCondition.SelfDiscarded -> mempty
  TriggerCondition.SelfExiledForMadness -> mempty
  TriggerCondition.PlayerDiscards playerActsOn -> playerActsOnNames asking playerActsOn
  TriggerCondition.PlayerDiscardsCards playerActsOn -> playerActsOnNames asking playerActsOn
  TriggerCondition.PlayerCycles _playerRelation -> mempty
  TriggerCondition.PlayerDrawsNthCard _playerDrawsNthCard -> mempty
  TriggerCondition.SelfAttacks triggerFrequency -> triggerFrequencyNames asking HistoryRead.Attacks triggerFrequency
  TriggerCondition.SelfAttacksWithAnother filter_ -> filterNames asking filter_
  TriggerCondition.SelfAttacksPermanent filter_ -> filterNames asking filter_
  TriggerCondition.CreatureAttacksAlone filter_ -> filterNames asking filter_
  TriggerCondition.CreatureAttacksYou -> mempty
  TriggerCondition.CreatureAttacks filter_ -> filterNames asking filter_
  TriggerCondition.AttachedPlayerIsAttacked -> mempty
  TriggerCondition.SelfIsAttacked -> mempty
  TriggerCondition.PlayerAttacks _playerRelation -> mempty
  TriggerCondition.PlayerAttacksWith playerAttacksWith -> playerAttacksWithNames asking playerAttacksWith
  TriggerCondition.PlayerAttacksPlayer _playerAttacksPlayer -> mempty
  TriggerCondition.SelfAttacksPlayerWithMostLife -> mempty
  TriggerCondition.SelfAttacksWhileSaddled -> mempty
  TriggerCondition.SelfAttacksWhile condition -> conditionNames asking condition
  TriggerCondition.SelfBlocks -> mempty
  TriggerCondition.CreatureBlocks filter_ -> filterNames asking filter_
  TriggerCondition.SelfBlocksCreature filter_ -> filterNames asking filter_
  TriggerCondition.SelfBlocksAtLeast _natural -> mempty
  TriggerCondition.SelfBlocksOneOrMore filter_ -> filterNames asking filter_
  TriggerCondition.SelfBecomesBlocked -> mempty
  TriggerCondition.SelfBecomesBlockedBy filter_ -> filterNames asking filter_
  TriggerCondition.SelfBecomesBlockedByOneOrMore filter_ -> filterNames asking filter_
  TriggerCondition.CreatureBecomesBlockedByAtLeast _creatureBecomesBlockedByAtLeast -> mempty
  TriggerCondition.SelfAttacksUnblocked -> mempty
  TriggerCondition.SelfPutIntoGraveyardFromLibrary -> mempty
  TriggerCondition.SelfPutIntoGraveyardFromAnywhere -> mempty
  TriggerCondition.SelfPutIntoGraveyardDuringResolution -> mempty
  TriggerCondition.CardPutIntoGraveyard cardPutIntoGraveyard -> cardPutIntoGraveyardNames asking cardPutIntoGraveyard
  TriggerCondition.SelfDies -> mempty
  TriggerCondition.PermanentDies filter_ -> filterNames asking filter_
  TriggerCondition.PermanentsDie filter_ -> filterNames asking filter_
  TriggerCondition.SelfLeavesTheBattlefield -> mempty
  TriggerCondition.SelfPutFromBattlefieldInto _ownedZone -> mempty
  TriggerCondition.PermanentLeavesTheBattlefield filter_ -> filterNames asking filter_
  TriggerCondition.PermanentReturnedToHand filter_ -> filterNames asking filter_
  TriggerCondition.PermanentsReturnedToHand filter_ -> filterNames asking filter_
  TriggerCondition.CardLeavesZone cardLeavesZone -> cardLeavesZoneNames asking cardLeavesZone
  TriggerCondition.CardsLeaveZone cardLeavesZone -> cardLeavesZoneNames asking cardLeavesZone
  TriggerCondition.CardsPutIntoZone cardsPutIntoZone -> cardsPutIntoZoneNames asking cardsPutIntoZone
  TriggerCondition.SelfLeavesGraveyard -> mempty
  TriggerCondition.AttachedCreatureDies -> mempty
  TriggerCondition.BecomesTapState becomesTapState -> actingPermanentNames asking (BecomesTapState.actor becomesTapState)
  TriggerCondition.PermanentsBecomeTapped filter_ -> filterNames asking filter_
  TriggerCondition.AttachedPermanentTappedForMana -> mempty
  TriggerCondition.PermanentTappedForMana permanentTappedForMana -> permanentTappedForManaNames asking permanentTappedForMana
  TriggerCondition.AbilityAddsMana abilityAddsMana -> abilityAddsManaNames asking abilityAddsMana
  TriggerCondition.SelfManaAbilityResolves -> mempty
  TriggerCondition.HauntedCreatureDies -> mempty
  TriggerCondition.SpellOrAbilityCounters _playerRelation -> mempty
  TriggerCondition.AbilityIsCountered -> mempty
  TriggerCondition.DamageToPlayerPrevented _playerRelation -> mempty
  TriggerCondition.SelfPreventsDamage filter_ -> filterNames asking filter_
  TriggerCondition.PlayerGainsLife _playerRelation -> mempty
  TriggerCondition.PlayersGainLife _playerRelation -> mempty
  TriggerCondition.PlayerLosesLife _playerRelation -> mempty
  TriggerCondition.SelfCountersReached selfCountersReached -> selfCountersReachedNames asking selfCountersReached
  TriggerCondition.SelfBecomesClassLevel _classLevel -> mempty
  TriggerCondition.SelfLastCounterRemoved selfCountersRemoved -> selfCountersRemovedNames asking selfCountersRemoved
  TriggerCondition.SelfCountersRemoved selfCountersRemoved -> selfCountersRemovedNames asking selfCountersRemoved
  TriggerCondition.SelfCounterRemoved selfCountersRemoved -> selfCountersRemovedNames asking selfCountersRemoved
  TriggerCondition.PermanentsGetCounters counterPlacement -> counterPlacementNames asking counterPlacement
  TriggerCondition.PermanentGetsCounters counterPlacement -> counterPlacementNames asking counterPlacement
  TriggerCondition.SpellCast spellCast -> spellCastNames asking spellCast
  TriggerCondition.SelfCast -> mempty
  TriggerCondition.AbilityActivated filter_ -> filterNames asking filter_
  TriggerCondition.SelfBecomesTargeted _playerRelation -> mempty
  TriggerCondition.ControllerBecomesTarget _controllerBecomesTarget -> mempty
  TriggerCondition.PermanentsBecomeTargeted permanentsBecomeTargeted -> permanentsBecomeTargetedNames asking permanentsBecomeTargeted
  TriggerCondition.PermanentBecomesTargeted permanentsBecomeTargeted -> permanentsBecomeTargetedNames asking permanentsBecomeTargeted
  TriggerCondition.SelfHalfUnlocked _cardName -> mempty
  TriggerCondition.RoomFullyUnlocked _playerRelation -> mempty
  TriggerCondition.AnyOf items -> foldMap (triggerConditionNames asking) items
  TriggerCondition.CausedBy narrowed -> triggerConditionNames asking (CausedBy.condition narrowed)
  TriggerCondition.SelfTurnedFaceUp -> mempty
  TriggerCondition.SelfTransformedInto _cardName -> mempty
  TriggerCondition.PermanentTransforms filter_ -> filterNames asking filter_
  TriggerCondition.PermanentTurnedFaceUp filter_ -> filterNames asking filter_
  TriggerCondition.FaceDownPermanentLeavesRevealed -> mempty
  TriggerCondition.PermanentBecomesDesignated permanentBecomesDesignated -> permanentBecomesDesignatedNames asking permanentBecomesDesignated
  TriggerCondition.PermanentActs permanentActs -> permanentActedNames asking (actingPermanentNames asking) permanentActs
  TriggerCondition.AttachedCreatureMentors -> mempty
  TriggerCondition.SelfExploits -> mempty
  TriggerCondition.CreatureExploits creatureExploits -> creatureExploitsNames asking creatureExploits
  TriggerCondition.SelfBecomesCrewed triggerFrequency -> triggerFrequencyNames asking HistoryRead.Crews triggerFrequency
  TriggerCondition.SelfCrewsVehicle -> mempty
  TriggerCondition.PermanentSacrificed permanentSacrificed -> playerActsOnNames asking permanentSacrificed
  TriggerCondition.SagaFinalChapterTriggers _playerRelation -> mempty
  TriggerCondition.PlayerBecomesMonarch _playerRelation -> mempty
  TriggerCondition.LoseControlOfBound slotName -> slotNames asking slotName
  TriggerCondition.BoundDiesOrIsExiled slotName -> slotNames asking slotName
  TriggerCondition.BoundDies slotName -> slotNames asking slotName
  TriggerCondition.RoomEntered _roomIndex -> mempty
  TriggerCondition.PlayerActs _playerActs -> mempty
  TriggerCondition.PlayerLosesGame _playerRelation -> mempty
  TriggerCondition.PlayerPlaysLand playsLand -> playsLandNames asking playsLand
  TriggerCondition.PlayerManifestsDread _playerRelation -> mempty
  TriggerCondition.ChaosEnsues -> mempty
  TriggerCondition.PlayerRollsPlaneswalker _playerRelation -> mempty
  TriggerCondition.SelfTurnedUpOffDeck -> mempty
  TriggerCondition.SelfPlaneswalkedAwayFrom -> mempty
  TriggerCondition.PlayerRollsResult dieResult -> dieResultNames asking (const mempty) dieResult
  TriggerCondition.Visit -> mempty
  TriggerCondition.PlayerWinsCoinFlip _playerRelation -> mempty
  TriggerCondition.PlayerLosesCoinFlip _playerRelation -> mempty
  TriggerCondition.SelfBecomesPlotted -> mempty
  TriggerCondition.SelfBecomesAttachedBy filter_ -> filterNames asking filter_
  TriggerCondition.SelfBecomesAttachedTo filter_ -> filterNames asking filter_
  TriggerCondition.SelfBecomesUnattachedFrom filter_ -> filterNames asking filter_
  TriggerCondition.Reflexive -> mempty
  TriggerCondition.PermanentBecomesBlockedBy filter_ -> filterNames asking filter_
  TriggerCondition.PlacesSticker placesSticker -> filterNames asking (PlacesSticker.object placesSticker)

-- The look-back a first-time-each-turn trigger makes, over the events its
-- condition names.
triggerFrequencyNames :: (Monoid r) => Asking r -> HistoryRead.HistoryRead -> TriggerFrequency.TriggerFrequency -> r
triggerFrequencyNames asking events x = case x of
  TriggerFrequency.EveryTime -> mempty
  TriggerFrequency.FirstTimeEachTurn -> history asking events

triggerLimitNames :: (Monoid r) => Asking r -> TriggerLimit.TriggerLimit -> r
triggerLimitNames asking x = case x of
  TriggerLimit.Unlimited -> mempty
  TriggerLimit.OncePerTurn -> history asking HistoryRead.Triggers
  -- GameState.triggeredThisGame, which Parun.Engine.Fragmented.digest keeps.
  TriggerLimit.OncePerGame -> mempty

triggeredAbilityNames :: (Monoid r) => Asking r -> (card -> r) -> (ability -> r) -> TriggeredAbility.TriggeredAbility card ability -> r
triggeredAbilityNames asking onCard onAbility x = case x of
  TriggeredAbility.MkTriggeredAbility condition modal intervening _name limit _functionsFrom -> triggerLimitNames asking limit <> triggerConditionNames asking condition <> modalNames asking onCard onAbility modal <> foldMap (conditionNames asking) intervening

turnFaceDownNames :: (Monoid r) => Asking r -> (ability -> r) -> TurnFaceDown.TurnFaceDown ability -> r
turnFaceDownNames asking onAbility x = case x of
  TurnFaceDown.MkTurnFaceDown ref characteristics -> objectRefNames asking ref <> faceDownCharacteristicsNames asking onAbility characteristics

turnUpRNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> TurnUpR.TurnUpR ability effect -> r
turnUpRNames asking onAbility onEffect x = case x of
  TurnUpR.MkTurnUpR matching _requiring paying rewrite -> filterNames asking matching <> foldMap (costNames asking (keywordNames asking)) paying <> turnUpRewriteNames asking onAbility onEffect rewrite

turnUpRewriteNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> TurnUpRewrite.TurnUpRewrite ability effect -> r
turnUpRewriteNames asking onAbility onEffect x = case x of
  TurnUpRewrite.WithCounters withCounters -> withCountersNames asking withCounters
  TurnUpRewrite.MayAttachTo filter_ -> filterNames asking filter_
  TurnUpRewrite.AsCopy asCopy -> asCopyNames asking onAbility onEffect asCopy

attachRNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> AttachR.AttachR ability effect -> r
attachRNames asking onAbility onEffect x = case x of
  AttachR.MkAttachR matching rewrite -> filterNames asking matching <> attachRewriteNames asking onAbility onEffect rewrite

attachRewriteNames :: (Monoid r) => Asking r -> (ability -> r) -> (effect -> r) -> AttachRewrite.AttachRewrite ability effect -> r
attachRewriteNames asking onAbility onEffect x = case x of
  AttachRewrite.AsCopy asCopy -> asCopyNames asking onAbility onEffect asCopy
  AttachRewrite.ChooseQuality _ -> mempty

untapRNames :: (Monoid r) => Asking r -> UntapR.UntapR -> r
untapRNames asking x = case x of
  UntapR.MkUntapR _during rewrite -> untapRewriteNames asking rewrite

untapRestrictionNames :: (Monoid r) => Asking r -> UntapRestriction.UntapRestriction -> r
untapRestrictionNames asking x = case x of
  UntapRestriction.MkUntapRestriction affected _hold while -> affectedNames asking affected <> foldMap (conditionNames asking) while

untapRewriteNames :: (Monoid r) => Asking r -> UntapRewrite.UntapRewrite -> r
untapRewriteNames asking x = case x of
  UntapRewrite.RemoveStunCounter -> mempty
  UntapRewrite.RemoveCounterToUntap counterKind -> counterKindNames asking (keywordNames asking) counterKind

voteNames :: (Monoid r) => Asking r -> Vote.Vote -> r
voteNames asking x = case x of
  Vote.MkVote starter choices _ -> playerRefNames asking starter <> voteChoicesNames asking choices

bidNames :: (Monoid r) => Asking r -> Bid.Bid -> r
bidNames asking x = case x of
  Bid.MkBid opening highBid highBidder -> quantityNames asking opening <> slotNames asking highBid <> slotNames asking highBidder

voteChoicesNames :: (Monoid r) => Asking r -> VoteChoices.VoteChoices -> r
voteChoicesNames asking x = case x of
  VoteChoices.Objects voteObjects -> voteObjectsNames asking voteObjects
  VoteChoices.Words slotName -> foldMap (slotNames asking) slotName
  VoteChoices.Players votePlayers -> slotNames asking (VotePlayers.slot votePlayers)

voteObjectsNames :: (Monoid r) => Asking r -> VoteObjects.VoteObjects -> r
voteObjectsNames asking x = case x of
  VoteObjects.MkVoteObjects filter_ slot -> filterNames asking filter_ <> slotNames asking slot

wardNames :: (Monoid r) => Asking r -> (keyword -> r) -> Ward.Ward keyword -> r
wardNames asking onKeyword x = case x of
  Ward.MkWard cost perEach -> costNames asking onKeyword cost <> foldMap (playerCounterTallyNames asking) perEach

whenSpentNames :: (Monoid r) => Asking r -> WhenSpent.WhenSpent -> r
whenSpentNames asking x = case x of
  WhenSpent.MkWhenSpent casts _ability -> filterNames asking casts

whichCountersNames :: (Monoid r) => Asking r -> (keyword -> r) -> WhichCounters.WhichCounters keyword -> r
whichCountersNames asking onKeyword x = case x of
  WhichCounters.OfKind counterKind -> counterKindNames asking onKeyword counterKind
  WhichCounters.OfAnyKind -> mempty

whileNames :: (Monoid r) => Asking r -> While.While -> r
whileNames asking x = case x of
  While.MkWhile _player condition -> conditionNames asking condition

withCountersNames :: (Monoid r) => Asking r -> WithCounters.WithCounters -> r
withCountersNames asking x = case x of
  WithCounters.MkWithCounters counters -> foldMap (counterKindNames asking (keywordNames asking)) (Map.keys counters) <> foldMap (quantityNames asking) counters

zoneChangePatternNames :: (Monoid r) => Asking r -> ZoneChangePattern.ZoneChangePattern -> r
zoneChangePatternNames asking x = case x of
  ZoneChangePattern.MkZoneChangePattern _whenDestination whoseObject whatObject _whenDiscarded _causedBy _duringResolution -> controllerRelationNames asking whoseObject <> filterNames asking whatObject

zoneChangeRNames :: (Monoid r) => Asking r -> ZoneChangeR.ZoneChangeR -> r
zoneChangeRNames asking x = case x of
  ZoneChangeR.MkZoneChangeR matching _destination _revealing _shuffling _position _optional -> zoneChangePatternNames asking matching

zoneScopeNames :: (Monoid r) => Asking r -> ZoneScope.ZoneScope -> r
zoneScopeNames asking x = case x of
  ZoneScope.Scoped _playerScope -> mempty
  ZoneScope.InSlot slotName -> slotNames asking slotName
  ZoneScope.ControllerOfBound slotName -> slotNames asking slotName
  ZoneScope.BoundPlayer _playerId -> mempty

-- The slot an Anchor names; the evaluated object and the source name none.
anchorNames :: (Monoid r) => Asking r -> Anchor.Anchor -> r
anchorNames asking anchor = case anchor of
  Anchor.Bound slot -> slotNames asking slot
  Anchor.Evaluated -> mempty
  Anchor.Source -> mempty
