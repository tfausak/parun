module Parun.Test where

import qualified Control.Monad.IO.Class as MonadIO
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Writer as Writer
import qualified Data.List as List
import qualified Parun.AbilitySlotLintSpec
import qualified Parun.ActivateSpec
import qualified Parun.ActivationProhibitionSpec
import qualified Parun.AdventureSpec
import qualified Parun.AirbendSpec
import qualified Parun.AlternatingTeamsSpec
import qualified Parun.AnteSpec
import qualified Parun.ArchenemySpec
import qualified Parun.AttackKeywordTriggerSpec
import qualified Parun.AttractionSpec
import qualified Parun.AuraSpec
import qualified Parun.BattleSpec
import qualified Parun.BindingSpec
import qualified Parun.BoardEffectSpec
import qualified Parun.BotSpec
import qualified Parun.CardSpec
import qualified Parun.CardTriggerSpec
import qualified Parun.CardsSpec
import qualified Parun.CaseSpec
import qualified Parun.CastPermissionSpec
import qualified Parun.CastProhibitionSpec
import qualified Parun.CastRestrictionSpec
import qualified Parun.CastSpec
import qualified Parun.ClashSpec
import qualified Parun.ClassSpec
import qualified Parun.ClientSpec
import qualified Parun.CloakSpec
import qualified Parun.Codec.AbilityAddsManaSpec
import qualified Parun.Codec.AbilityKindSpec
import qualified Parun.Codec.AbilityNameSpec
import qualified Parun.Codec.AbilityTriggeredSpec
import qualified Parun.Codec.AbilityViewSpec
import qualified Parun.Codec.AcquisitionSpec
import qualified Parun.Codec.ActingPermanentSpec
import qualified Parun.Codec.ActivateManaAbilitiesSpec
import qualified Parun.Codec.ActivatedAbilitySourceSpec
import qualified Parun.Codec.ActivatedAbilitySpec
import qualified Parun.Codec.ActivationProhibitionSpec
import qualified Parun.Codec.ActivationRestrictionSpec
import qualified Parun.Codec.ActivationSpec
import qualified Parun.Codec.ActivatorSpec
import qualified Parun.Codec.ActiveAttackProhibitionSpec
import qualified Parun.Codec.ActiveAttackRequirementSpec
import qualified Parun.Codec.ActiveBlockRequirementSpec
import qualified Parun.Codec.ActiveCopySpec
import qualified Parun.Codec.ActiveEvasionSpec
import qualified Parun.Codec.ActiveObjectProhibitionSpec
import qualified Parun.Codec.ActivePlayerEffectSpec
import qualified Parun.Codec.ActiveReplacementSpec
import qualified Parun.Codec.AffectPlayersSpec
import qualified Parun.Codec.AffectedPlayersSpec
import qualified Parun.Codec.AffectedSpec
import qualified Parun.Codec.AffectedUnlessSpec
import qualified Parun.Codec.AfterObjectTurnSpec
import qualified Parun.Codec.AfterTurnSpec
import qualified Parun.Codec.AgainstExiledPileSpec
import qualified Parun.Codec.AgainstLastCardExiledWithSpec
import qualified Parun.Codec.AgainstSlotSpec
import qualified Parun.Codec.AggregationSpec
import qualified Parun.Codec.AimedAtSpec
import qualified Parun.Codec.AimedPlayersSpec
import qualified Parun.Codec.AloneUnlessSpec
import qualified Parun.Codec.AlternativeActivationCostSpec
import qualified Parun.Codec.AlternativeCostSpec
import qualified Parun.Codec.AnchorSpec
import qualified Parun.Codec.AnswerSpec
import qualified Parun.Codec.AnyNumberDiscardSpec
import qualified Parun.Codec.AnyNumberMatchingSpec
import qualified Parun.Codec.ArmDelayedTriggerSpec
import qualified Parun.Codec.ArrangeInLibrarySpec
import qualified Parun.Codec.ArrivalSpec
import qualified Parun.Codec.AsCopySpec
import qualified Parun.Codec.AttachAllSpec
import qualified Parun.Codec.AttachBoundSpec
import qualified Parun.Codec.AttachRSpec
import qualified Parun.Codec.AttachRestrictionSpec
import qualified Parun.Codec.AttachRewriteSpec
import qualified Parun.Codec.AttachTargetSpec
import qualified Parun.Codec.AttachedToBoundSpec
import qualified Parun.Codec.AttackCostSpec
import qualified Parun.Codec.AttackLimitUnlessSpec
import qualified Parun.Codec.AttackOptionSpec
import qualified Parun.Codec.AttackPermissionSpec
import qualified Parun.Codec.AttackRequirementSpec
import qualified Parun.Codec.AttackTargetKindSpec
import qualified Parun.Codec.AttackTargetRefSpec
import qualified Parun.Codec.AttackTargetSpec
import qualified Parun.Codec.AttackedPlayerSpec
import qualified Parun.Codec.AttackerBlockedSpec
import qualified Parun.Codec.AttackerDeclaredSpec
import qualified Parun.Codec.AttackerUnblockedSpec
import qualified Parun.Codec.AttackersAreSpec
import qualified Parun.Codec.AttackingPlayersSpec
import qualified Parun.Codec.AudienceSpec
import qualified Parun.Codec.BackupSpec
import qualified Parun.Codec.BattlefieldCandidateSpec
import qualified Parun.Codec.BecameAttackedSpec
import qualified Parun.Codec.BecameBlockingSpec
import qualified Parun.Codec.BecameDesignatedSpec
import qualified Parun.Codec.BecomeCopySpec
import qualified Parun.Codec.BeginningStepSpec
import qualified Parun.Codec.BeholdSpec
import qualified Parun.Codec.BidSpec
import qualified Parun.Codec.BindingSpec
import qualified Parun.Codec.BlockCostSpec
import qualified Parun.Codec.BlockPermissionSpec
import qualified Parun.Codec.BlockProducerSpec
import qualified Parun.Codec.BlockRequirementSpec
import qualified Parun.Codec.BlockRoleSpec
import qualified Parun.Codec.BlockStatusSpec
import qualified Parun.Codec.BlockersAreSpec
import qualified Parun.Codec.BlocksDeclaredSpec
import qualified Parun.Codec.BoardSpec
import qualified Parun.Codec.BoundMeasureSpec
import qualified Parun.Codec.CandidateIdSpec
import qualified Parun.Codec.CantAttackPlayerSpec
import qualified Parun.Codec.CantBeBlockedBySpec
import qualified Parun.Codec.CantBlockCreaturesSpec
import qualified Parun.Codec.CantSearchLibrariesSpec
import qualified Parun.Codec.CardArrivedInSpec
import qualified Parun.Codec.CardIdentitySpec
import qualified Parun.Codec.CardLeavesZoneSpec
import qualified Parun.Codec.CardNameSpec
import qualified Parun.Codec.CardPutIntoGraveyardSpec
import qualified Parun.Codec.CardSpec
import qualified Parun.Codec.CardTypeSpec
import qualified Parun.Codec.CardsPutIntoZoneSpec
import qualified Parun.Codec.CastFromSpec
import qualified Parun.Codec.CastFromZoneSpec
import qualified Parun.Codec.CastObligationSpec
import qualified Parun.Codec.CastOfferSpec
import qualified Parun.Codec.CastRepetitionSpec
import qualified Parun.Codec.CastingPermissionSpec
import qualified Parun.Codec.CastingRestrictionSpec
import qualified Parun.Codec.CastingSpec
import qualified Parun.Codec.ChangeTextSpec
import qualified Parun.Codec.ChangeWordSpec
import qualified Parun.Codec.CharacteristicPTSpec
import qualified Parun.Codec.CheckSpec
import qualified Parun.Codec.ChoicesSpec
import qualified Parun.Codec.ChooseBetweenSpec
import qualified Parun.Codec.ChooseNumberSpec
import qualified Parun.Codec.ChoosePermanentsSpec
import qualified Parun.Codec.ChoosePlayerAtRandomSpec
import qualified Parun.Codec.ChoosePlayerSpec
import qualified Parun.Codec.ChooserSpec
import qualified Parun.Codec.ChosenCardFromAmongSpec
import qualified Parun.Codec.ChosenCardInGraveyardSpec
import qualified Parun.Codec.ChosenCardInHandSpec
import qualified Parun.Codec.ChosenQualitySpec
import qualified Parun.Codec.ClassLevelChangeSpec
import qualified Parun.Codec.ClassLevelSpec
import qualified Parun.Codec.ClauseIndexSpec
import qualified Parun.Codec.ClauseSpec
import qualified Parun.Codec.CoinFaceSpec
import qualified Parun.Codec.CoinFlippedSpec
import qualified Parun.Codec.CoinReadingSpec
import qualified Parun.Codec.ColorModeSpec
import qualified Parun.Codec.ColorSpec
import qualified Parun.Codec.CombatDamageOptionSpec
import qualified Parun.Codec.CombatRestrictionSpec
import qualified Parun.Codec.CombatSpec
import qualified Parun.Codec.CombatStepSpec
import qualified Parun.Codec.ComparesSpec
import qualified Parun.Codec.ComparisonSpec
import qualified Parun.Codec.CompletedDungeonSpec
import qualified Parun.Codec.ComponentCardSpec
import qualified Parun.Codec.ConditionSpec
import qualified Parun.Codec.ConjureCardsSpec
import qualified Parun.Codec.ConjureDestinationSpec
import qualified Parun.Codec.ConjureSelectionSpec
import qualified Parun.Codec.ConjureSpec
import qualified Parun.Codec.ContinuousEffectSpec
import qualified Parun.Codec.ControlChangedSpec
import qualified Parun.Codec.ControlClockSpec
import qualified Parun.Codec.ControlDurationSpec
import qualified Parun.Codec.ControlMarginSpec
import qualified Parun.Codec.ControlPlayerSpec
import qualified Parun.Codec.ControlSidesSpec
import qualified Parun.Codec.ControlSlotsSpec
import qualified Parun.Codec.ControllerBecomesTargetSpec
import qualified Parun.Codec.ControllerRelationSpec
import qualified Parun.Codec.ConvokingSpec
import qualified Parun.Codec.CopyClauseSpec
import qualified Parun.Codec.CopyCoverageSpec
import qualified Parun.Codec.CopyDomainSpec
import qualified Parun.Codec.CopyExceptionSpec
import qualified Parun.Codec.CopyOriginalSpec
import qualified Parun.Codec.CopyRecipientSpec
import qualified Parun.Codec.CopyStackObjectSpec
import qualified Parun.Codec.CopyTargetsSpec
import qualified Parun.Codec.CostAmountSpec
import qualified Parun.Codec.CostBasisSpec
import qualified Parun.Codec.CostChangeSpec
import qualified Parun.Codec.CostChoiceSpec
import qualified Parun.Codec.CostComponentSpec
import qualified Parun.Codec.CostDirectionSpec
import qualified Parun.Codec.CostKeywordSpec
import qualified Parun.Codec.CostModifierSpec
import qualified Parun.Codec.CostReductionSpec
import qualified Parun.Codec.CostScaleSpec
import qualified Parun.Codec.CostSpec
import qualified Parun.Codec.CostSubjectSpec
import qualified Parun.Codec.CouldProduceSpec
import qualified Parun.Codec.CountIsSpec
import qualified Parun.Codec.CountSpec
import qualified Parun.Codec.CountedDiscardSpec
import qualified Parun.Codec.CounterChangeSpec
import qualified Parun.Codec.CounterDestinationSpec
import qualified Parun.Codec.CounterKindSpec
import qualified Parun.Codec.CounterNameSpec
import qualified Parun.Codec.CounterPatternSpec
import qualified Parun.Codec.CounterPlacementSpec
import qualified Parun.Codec.CounterRSpec
import qualified Parun.Codec.CounterRestrictionSpec
import qualified Parun.Codec.CounterSpec
import qualified Parun.Codec.CounterSpreadSpec
import qualified Parun.Codec.CounterSubjectSpec
import qualified Parun.Codec.CounterabilitySpec
import qualified Parun.Codec.CounteredEndSpec
import qualified Parun.Codec.CounteringSpec
import qualified Parun.Codec.CountersAreSpec
import qualified Parun.Codec.CountersFromPermanentsSpec
import qualified Parun.Codec.CountersFromThisSpec
import qualified Parun.Codec.CraftSpec
import qualified Parun.Codec.CreateCopySpec
import qualified Parun.Codec.CreateSpec
import qualified Parun.Codec.CreatureBecomesBlockedByAtLeastSpec
import qualified Parun.Codec.CreatureExploitsSpec
import qualified Parun.Codec.CrewRestrictionSpec
import qualified Parun.Codec.CrewingSpec
import qualified Parun.Codec.CyclingSpec
import qualified Parun.Codec.DamageDirectionSpec
import qualified Parun.Codec.DamageEventSpec
import qualified Parun.Codec.DamageIsSpec
import qualified Parun.Codec.DamageKindSpec
import qualified Parun.Codec.DamagePartSpec
import qualified Parun.Codec.DamagePatternSpec
import qualified Parun.Codec.DamagePreventedSpec
import qualified Parun.Codec.DamageRSpec
import qualified Parun.Codec.DamageRewriteSpec
import qualified Parun.Codec.DamagedPartySpec
import qualified Parun.Codec.DaytimeSpec
import qualified Parun.Codec.DealDamageSpec
import qualified Parun.Codec.DealsDamageToPlayerSpec
import qualified Parun.Codec.DealtDamageToSpec
import qualified Parun.Codec.DeciderSpec
import qualified Parun.Codec.DefendersAreSpec
import qualified Parun.Codec.DefenseSpec
import qualified Parun.Codec.DelayedTriggerSpec
import qualified Parun.Codec.DepartureSpec
import qualified Parun.Codec.DesignateSpec
import qualified Parun.Codec.DesignationSpec
import qualified Parun.Codec.DestroySpec
import qualified Parun.Codec.DestructionRSpec
import qualified Parun.Codec.DestructionRewriteSpec
import qualified Parun.Codec.DevotionSpec
import qualified Parun.Codec.DevourCountSpec
import qualified Parun.Codec.DevourSpec
import qualified Parun.Codec.DiceReadingSpec
import qualified Parun.Codec.DieRollRSpec
import qualified Parun.Codec.DieRollRewriteSpec
import qualified Parun.Codec.DifferentInSpec
import qualified Parun.Codec.DiscardCardsSpec
import qualified Parun.Codec.DiscardCauseSpec
import qualified Parun.Codec.DiscardSpec
import qualified Parun.Codec.DiscardedSpec
import qualified Parun.Codec.DistinctOfSpec
import qualified Parun.Codec.DivideSpec
import qualified Parun.Codec.DoesNotUntapNextSpec
import qualified Parun.Codec.DrawCountRSpec
import qualified Parun.Codec.DrawCountRewriteSpec
import qualified Parun.Codec.DrawRSpec
import qualified Parun.Codec.DrawRevealSpec
import qualified Parun.Codec.DrawRewriteSpec
import qualified Parun.Codec.DrawSpec
import qualified Parun.Codec.DrawnUnderSpec
import qualified Parun.Codec.DrewSpec
import qualified Parun.Codec.DungeonRoomSpec
import qualified Parun.Codec.DurationEventSpec
import qualified Parun.Codec.DurationSpec
import qualified Parun.Codec.DuringPhaseSpec
import qualified Parun.Codec.EachCardFromAmongSpec
import qualified Parun.Codec.EachCardInExiledPileSpec
import qualified Parun.Codec.EachCardInGraveyardSpec
import qualified Parun.Codec.EachCardInHandSpec
import qualified Parun.Codec.EffectSpec
import qualified Parun.Codec.EmergeSpec
import qualified Parun.Codec.EmperorsSpec
import qualified Parun.Codec.EndTurnSignalSpec
import qualified Parun.Codec.EndingStepSpec
import qualified Parun.Codec.EnteredZoneSpec
import qualified Parun.Codec.EnteringTogetherSpec
import qualified Parun.Codec.EntersWithSpec
import qualified Parun.Codec.EntrantSpec
import qualified Parun.Codec.EntryAttackSpec
import qualified Parun.Codec.EntryBlockSpec
import qualified Parun.Codec.EntryControllerSpec
import qualified Parun.Codec.EntryFlipSpec
import qualified Parun.Codec.EntryHostSpec
import qualified Parun.Codec.EntryOptionSpec
import qualified Parun.Codec.EntryPriceSpec
import qualified Parun.Codec.EntryRSpec
import qualified Parun.Codec.EntryRestrictionSpec
import qualified Parun.Codec.EntryRewriteSpec
import qualified Parun.Codec.EntryRidersSpec
import qualified Parun.Codec.EntrySpec
import qualified Parun.Codec.EquipSpec
import qualified Parun.Codec.EventExpirySpec
import qualified Parun.Codec.EventGroupSpec
import qualified Parun.Codec.EventShapeSpec
import qualified Parun.Codec.ExcessDestinationSpec
import qualified Parun.Codec.ExchangeBlocksSpec
import qualified Parun.Codec.ExchangeSidesSpec
import qualified Parun.Codec.ExchangeValuesSpec
import qualified Parun.Codec.ExchangeZonesSpec
import qualified Parun.Codec.ExchangedValueSpec
import qualified Parun.Codec.ExileCardsFromGraveyardSpec
import qualified Parun.Codec.ExileCardsFromHandSpec
import qualified Parun.Codec.ExileFromGraveyardSpec
import qualified Parun.Codec.ExileHauntingSpec
import qualified Parun.Codec.ExileLinkSpec
import qualified Parun.Codec.ExileLookerSpec
import qualified Parun.Codec.ExileMaterialsSpec
import qualified Parun.Codec.ExilePermanentsSpec
import qualified Parun.Codec.ExilePlayPermissionSpec
import qualified Parun.Codec.ExiledCardAbilitiesSpec
import qualified Parun.Codec.ExiledPileSpec
import qualified Parun.Codec.ExpansionSpec
import qualified Parun.Codec.ExpirySpec
import qualified Parun.Codec.ExploitedSpec
import qualified Parun.Codec.ExtraPhaseSpec
import qualified Parun.Codec.ExtraTurnSpec
import qualified Parun.Codec.ExtraVotesSpec
import qualified Parun.Codec.FaceDownCharacteristicsSpec
import qualified Parun.Codec.FaceDownReasonSpec
import qualified Parun.Codec.FaceDownStateSpec
import qualified Parun.Codec.FaceSpec
import qualified Parun.Codec.FacingSpec
import qualified Parun.Codec.FightSpec
import qualified Parun.Codec.FilterSpec
import qualified Parun.Codec.FlipCoinSpec
import qualified Parun.Codec.FloatingCandidateSpec
import qualified Parun.Codec.ForEachNumberSpec
import qualified Parun.Codec.ForEachSpec
import qualified Parun.Codec.ForbidAttackSpec
import qualified Parun.Codec.ForbidBeingBlockedSpec
import qualified Parun.Codec.ForetellCostSpec
import qualified Parun.Codec.FromAnywhereSpec
import qualified Parun.Codec.FromOutsideTheGameSpec
import qualified Parun.Codec.FromReferenceSpec
import qualified Parun.Codec.GainControlSpec
import qualified Parun.Codec.GameEventSpec
import qualified Parun.Codec.GameLossRSpec
import qualified Parun.Codec.GameOutcomeSpec
import qualified Parun.Codec.GameSettingsSpec
import qualified Parun.Codec.GiftSpec
import qualified Parun.Codec.GrantLookAtExiledSpec
import qualified Parun.Codec.GrantPlayFromExileSpec
import qualified Parun.Codec.GrantedAbilitySpec
import qualified Parun.Codec.GraveyardOrderSpec
import qualified Parun.Codec.HalfUnlockedSpec
import qualified Parun.Codec.HalvedSpec
import qualified Parun.Codec.HandActionSpec
import qualified Parun.Codec.HybridSpec
import qualified Parun.Codec.IfTakenSpec
import qualified Parun.Codec.IgnoredAbilitySpec
import qualified Parun.Codec.ImpendingSpec
import qualified Parun.Codec.InZoneSpec
import qualified Parun.Codec.InherentTriggerSourceSpec
import qualified Parun.Codec.InitiativeTargetSpec
import qualified Parun.Codec.InstanceOrdinalSpec
import qualified Parun.Codec.InstructionRSpec
import qualified Parun.Codec.InstructionRewriteSpec
import qualified Parun.Codec.KeywordCountSpec
import qualified Parun.Codec.KeywordDesignatorSpec
import qualified Parun.Codec.KeywordFamilySpec
import qualified Parun.Codec.KeywordInstanceSpec
import qualified Parun.Codec.KeywordSpec
import qualified Parun.Codec.KeywordsAreSpec
import qualified Parun.Codec.LabelSpec
import qualified Parun.Codec.LandAllowanceSpec
import qualified Parun.Codec.LandPlayedSpec
import qualified Parun.Codec.LastKnownSpec
import qualified Parun.Codec.LayoutSpec
import qualified Parun.Codec.LeftTheGameSpec
import qualified Parun.Codec.LibraryDepthSpec
import qualified Parun.Codec.LibraryPlacementSpec
import qualified Parun.Codec.LibraryPositionSpec
import qualified Parun.Codec.LifeChangeSpec
import qualified Parun.Codec.LifeGainRSpec
import qualified Parun.Codec.LifeGainRewriteSpec
import qualified Parun.Codec.LifeIsSpec
import qualified Parun.Codec.LifeLossCauseSpec
import qualified Parun.Codec.LifeLossPatternSpec
import qualified Parun.Codec.LifeLossRSpec
import qualified Parun.Codec.LifeLossRewriteSpec
import qualified Parun.Codec.LifeLossSpec
import qualified Parun.Codec.LimitUnlessSpec
import qualified Parun.Codec.LoggedEventSpec
import qualified Parun.Codec.LookAtSpec
import qualified Parun.Codec.LookedSpec
import qualified Parun.Codec.LoopMembersSpec
import qualified Parun.Codec.LoyaltyKindSpec
import qualified Parun.Codec.LoyaltySpec
import qualified Parun.Codec.MadnessCostSpec
import qualified Parun.Codec.MakeForetoldSpec
import qualified Parun.Codec.ManaAbilityResolvedSpec
import qualified Parun.Codec.ManaAddedCauseSpec
import qualified Parun.Codec.ManaAddedSpec
import qualified Parun.Codec.ManaAdditionSpec
import qualified Parun.Codec.ManaCostSpec
import qualified Parun.Codec.ManaCountSpec
import qualified Parun.Codec.ManaFilterSpec
import qualified Parun.Codec.ManaProductionSpec
import qualified Parun.Codec.ManaRestrictionSpec
import qualified Parun.Codec.ManaRetentionSpec
import qualified Parun.Codec.ManaRiderEffectSpec
import qualified Parun.Codec.ManaRiderSpec
import qualified Parun.Codec.ManaSpec
import qualified Parun.Codec.ManaSpecificationSpec
import qualified Parun.Codec.ManaSpendingSpec
import qualified Parun.Codec.ManaSymbolSpec
import qualified Parun.Codec.ManaTypeSpec
import qualified Parun.Codec.ManaUnitSpec
import qualified Parun.Codec.ManifestedDreadSpec
import qualified Parun.Codec.MeasureSpec
import qualified Parun.Codec.MeasuresSpec
import qualified Parun.Codec.MeldSourceSpec
import qualified Parun.Codec.MeldSpec
import qualified Parun.Codec.MentoredSpec
import qualified Parun.Codec.MergeComponentSpec
import qualified Parun.Codec.MillSpec
import qualified Parun.Codec.MillTallySpec
import qualified Parun.Codec.MilledSpec
import qualified Parun.Codec.ModalSpec
import qualified Parun.Codec.ModeIndexSpec
import qualified Parun.Codec.ModeSelectionSpec
import qualified Parun.Codec.ModeSpec
import qualified Parun.Codec.ModificationSpec
import qualified Parun.Codec.ModifiedRollSpec
import qualified Parun.Codec.ModifyPowerToughnessSpec
import qualified Parun.Codec.ModifyTargetSpec
import qualified Parun.Codec.MonarchIsSpec
import qualified Parun.Codec.MonarchTargetSpec
import qualified Parun.Codec.MonarchWatchSpec
import qualified Parun.Codec.MorphSpec
import qualified Parun.Codec.MorphVariantSpec
import qualified Parun.Codec.MoveCountersSpec
import qualified Parun.Codec.MoveDurationSpec
import qualified Parun.Codec.MoveManaSpec
import qualified Parun.Codec.MoveSpec
import qualified Parun.Codec.MoveToZoneSpec
import qualified Parun.Codec.MovedBetweenSpec
import qualified Parun.Codec.MovedKindsSpec
import qualified Parun.Codec.MovedSpec
import qualified Parun.Codec.NameChooserSpec
import qualified Parun.Codec.NamesAreSpec
import qualified Parun.Codec.NinjutsuSpec
import qualified Parun.Codec.NinjutsuVariantSpec
import qualified Parun.Codec.ObjectCountSpec
import qualified Parun.Codec.ObjectIdSpec
import qualified Parun.Codec.ObjectRefSpec
import qualified Parun.Codec.ObjectSnapshotSpec
import qualified Parun.Codec.ObjectSpec
import qualified Parun.Codec.ObjectViewSpec
import qualified Parun.Codec.OfferCastSpec
import qualified Parun.Codec.OnsetSpec
import qualified Parun.Codec.OperandSpec
import qualified Parun.Codec.OptionalDecisionSpec
import qualified Parun.Codec.OptionalitySpec
import qualified Parun.Codec.OrElseSpec
import qualified Parun.Codec.OutsideCardSpec
import qualified Parun.Codec.OutsideDestinationSpec
import qualified Parun.Codec.OutsideObjectSpec
import qualified Parun.Codec.OwnedZoneSpec
import qualified Parun.Codec.PaidExpirySpec
import qualified Parun.Codec.PairingSpec
import qualified Parun.Codec.PartnerTextSpec
import qualified Parun.Codec.PastActivationSpec
import qualified Parun.Codec.PayBranchSpec
import qualified Parun.Codec.PayGateSpec
import qualified Parun.Codec.PayObligationSpec
import qualified Parun.Codec.PayingSpec
import qualified Parun.Codec.PaymentDecisionSpec
import qualified Parun.Codec.PendingEntryEffectSpec
import qualified Parun.Codec.PendingReplacementEffectSpec
import qualified Parun.Codec.PermanentActionSpec
import qualified Parun.Codec.PermanentBecomesDesignatedSpec
import qualified Parun.Codec.PermanentCandidateSpec
import qualified Parun.Codec.PermanentDealsCombatDamageToPlayerSpec
import qualified Parun.Codec.PermanentSacrificedSpec
import qualified Parun.Codec.PermanentTappedForManaSpec
import qualified Parun.Codec.PermanentWasSacrificedSpec
import qualified Parun.Codec.PermanentsBecomeTargetedSpec
import qualified Parun.Codec.PermanentsDealCombatDamageToPlayerSpec
import qualified Parun.Codec.PermissionCostSpec
import qualified Parun.Codec.PermissionLimitSpec
import qualified Parun.Codec.PermissionPoolSpec
import qualified Parun.Codec.PermissionVerbSpec
import qualified Parun.Codec.PhasePatternSpec
import qualified Parun.Codec.PhaseSelectorSpec
import qualified Parun.Codec.PhaseSpec
import qualified Parun.Codec.PhasedOutSpec
import qualified Parun.Codec.PileDrawSpec
import qualified Parun.Codec.PileSpec
import qualified Parun.Codec.PlacementSpec
import qualified Parun.Codec.PlanarDieFaceSpec
import qualified Parun.Codec.PlanarDieRolledSpec
import qualified Parun.Codec.PlaneswalkCauseSpec
import qualified Parun.Codec.PlaneswalkRSpec
import qualified Parun.Codec.PlaneswalkRewriteSpec
import qualified Parun.Codec.PlayBudgetSpec
import qualified Parun.Codec.PlayPermissionOriginSpec
import qualified Parun.Codec.PlayerActionSpec
import qualified Parun.Codec.PlayerAttacksPlayerSpec
import qualified Parun.Codec.PlayerAttacksWithSpec
import qualified Parun.Codec.PlayerChoiceSpec
import qualified Parun.Codec.PlayerControlSpec
import qualified Parun.Codec.PlayerCounterKindSpec
import qualified Parun.Codec.PlayerCounterTallySpec
import qualified Parun.Codec.PlayerCountersAreSpec
import qualified Parun.Codec.PlayerCountersSpec
import qualified Parun.Codec.PlayerDesignationSpec
import qualified Parun.Codec.PlayerDesignationTallySpec
import qualified Parun.Codec.PlayerDrawsNthCardSpec
import qualified Parun.Codec.PlayerEffectSpec
import qualified Parun.Codec.PlayerIdSpec
import qualified Parun.Codec.PlayerInstructionSpec
import qualified Parun.Codec.PlayerQuantitySpec
import qualified Parun.Codec.PlayerRefSpec
import qualified Parun.Codec.PlayerRelationSpec
import qualified Parun.Codec.PlayerSacrificesSpec
import qualified Parun.Codec.PlayerScopeSpec
import qualified Parun.Codec.PlayerSpec
import qualified Parun.Codec.PlayerStaticAbilitySpec
import qualified Parun.Codec.PlayerViewSpec
import qualified Parun.Codec.PlayersDealtDamageSpec
import qualified Parun.Codec.PlayersWhoSpec
import qualified Parun.Codec.PlaysLandSpec
import qualified Parun.Codec.PlotFromZoneSpec
import qualified Parun.Codec.PlusSpec
import qualified Parun.Codec.PoolSpec
import qualified Parun.Codec.PowerSpec
import qualified Parun.Codec.PowerToughnessIsSpec
import qualified Parun.Codec.PreventAllDamageSpec
import qualified Parun.Codec.PreventNextDamageSpec
import qualified Parun.Codec.PreventionRiderSpec
import qualified Parun.Codec.PreventionSpec
import qualified Parun.Codec.PrintedReplacementSpec
import qualified Parun.Codec.PrintingIdSpec
import qualified Parun.Codec.PrintingSpec
import qualified Parun.Codec.ProductionTagSpec
import qualified Parun.Codec.ProhibitSpec
import qualified Parun.Codec.ProhibitionSpec
import qualified Parun.Codec.ProjectedCharacteristicsSpec
import qualified Parun.Codec.ProtectionSpec
import qualified Parun.Codec.PrototypeSpec
import qualified Parun.Codec.PutCountersFromSpec
import qualified Parun.Codec.PutCountersSpec
import qualified Parun.Codec.QuantitySpec
import qualified Parun.Codec.QuestionSpec
import qualified Parun.Codec.RangeOfInfluenceSpec
import qualified Parun.Codec.ReadinessSpec
import qualified Parun.Codec.RecipientSpec
import qualified Parun.Codec.RedirectDamageSpec
import qualified Parun.Codec.ReferenceSpec
import qualified Parun.Codec.RegenerabilitySpec
import qualified Parun.Codec.ReinforceSpec
import qualified Parun.Codec.RemoveCountersSpec
import qualified Parun.Codec.RemovePlayerCountersSpec
import qualified Parun.Codec.RepeatIfSpec
import qualified Parun.Codec.RepeatSpec
import qualified Parun.Codec.ReplaceSpec
import qualified Parun.Codec.ReplacementEffectSpec
import qualified Parun.Codec.ReplacementOriginSpec
import qualified Parun.Codec.ReplacementProvenanceSpec
import qualified Parun.Codec.RequestSpec
import qualified Parun.Codec.RequireAttackSpec
import qualified Parun.Codec.RequireBlockSpec
import qualified Parun.Codec.RequiredDefenderSpec
import qualified Parun.Codec.RequirementAritySpec
import qualified Parun.Codec.RestartSignalSpec
import qualified Parun.Codec.RestrictedCreaturesSpec
import qualified Parun.Codec.ResultSpec
import qualified Parun.Codec.ReturnEndingSpec
import qualified Parun.Codec.ReturnPermanentsSpec
import qualified Parun.Codec.ReturnWatchSpec
import qualified Parun.Codec.RevealCauseSpec
import qualified Parun.Codec.RevealObligationSpec
import qualified Parun.Codec.RevealSpec
import qualified Parun.Codec.RevealTimingSpec
import qualified Parun.Codec.RevealWindowSpec
import qualified Parun.Codec.RevealedSpec
import qualified Parun.Codec.RevealedThisWaySpec
import qualified Parun.Codec.RollDieSpec
import qualified Parun.Codec.RollModifierSpec
import qualified Parun.Codec.RoomHalfSpec
import qualified Parun.Codec.RoomIndexSpec
import qualified Parun.Codec.RoundingSpec
import qualified Parun.Codec.RuleAbilitiesSpec
import qualified Parun.Codec.SacrificeAnyNumberSpec
import qualified Parun.Codec.SacrificeEffectSpec
import qualified Parun.Codec.SacrificeRestrictionSpec
import qualified Parun.Codec.SacrificeSpec
import qualified Parun.Codec.SacrificeToEnterSpec
import qualified Parun.Codec.SacrificerSpec
import qualified Parun.Codec.SaddlingSpec
import qualified Parun.Codec.ScalingSpec
import qualified Parun.Codec.ScenarioSpec
import qualified Parun.Codec.ScopeSpec
import qualified Parun.Codec.SearchDestinationSpec
import qualified Parun.Codec.SearchSpec
import qualified Parun.Codec.SeatSpec
import qualified Parun.Codec.SeatViewSpec
import qualified Parun.Codec.SelfCountersReachedSpec
import qualified Parun.Codec.SelfCountersRemovedSpec
import qualified Parun.Codec.SetBasePowerToughnessSpec
import qualified Parun.Codec.SetClassLevelSpec
import qualified Parun.Codec.SetHalfLockedSpec
import qualified Parun.Codec.SetPowerToughnessSpec
import qualified Parun.Codec.ShownCardsSpec
import qualified Parun.Codec.ShownComponentSpec
import qualified Parun.Codec.ShowsSpec
import qualified Parun.Codec.ShuffleIntoLibrarySpec
import qualified Parun.Codec.SicknessSpec
import qualified Parun.Codec.SideDeckSpec
import qualified Parun.Codec.SkipPhaseSpec
import qualified Parun.Codec.SlotCountSpec
import qualified Parun.Codec.SlotNameSpec
import qualified Parun.Codec.SlotPerPlayerSpec
import qualified Parun.Codec.SourceChoicesSpec
import qualified Parun.Codec.SourceSpec
import qualified Parun.Codec.SpecialActionSpec
import qualified Parun.Codec.SpeedDecreaseSpec
import qualified Parun.Codec.SpellCastSpec
import qualified Parun.Codec.SpellWasCastSpec
import qualified Parun.Codec.SpellWasCopiedSpec
import qualified Parun.Codec.SpendManaAsThoughSpec
import qualified Parun.Codec.SpendTriggerSpec
import qualified Parun.Codec.SpliceSpec
import qualified Parun.Codec.StackObjectKindSpec
import qualified Parun.Codec.StatedFlipSpec
import qualified Parun.Codec.StaticAbilitySpec
import qualified Parun.Codec.StatusSpec
import qualified Parun.Codec.StepBeganSpec
import qualified Parun.Codec.StepBeginsSpec
import qualified Parun.Codec.StickerKindSpec
import qualified Parun.Codec.StickerSheetSpec
import qualified Parun.Codec.StoredResultSpec
import qualified Parun.Codec.SubtypeSpec
import qualified Parun.Codec.SubtypesAreSpec
import qualified Parun.Codec.SuperlativeSpec
import qualified Parun.Codec.SupertypeSpec
import qualified Parun.Codec.SuspendCountersSpec
import qualified Parun.Codec.SuspendSpec
import qualified Parun.Codec.TakeExtraTurnSpec
import qualified Parun.Codec.TakingSpec
import qualified Parun.Codec.TapForManaSpec
import qualified Parun.Codec.TapForTotalPowerSpec
import qualified Parun.Codec.TapPermanentsSpec
import qualified Parun.Codec.TapSpec
import qualified Parun.Codec.TapStateSpec
import qualified Parun.Codec.TappedForManaSpec
import qualified Parun.Codec.TappedIsSpec
import qualified Parun.Codec.TargetChooserSpec
import qualified Parun.Codec.TargetCountSpec
import qualified Parun.Codec.TargetRestrictionSpec
import qualified Parun.Codec.TargetSlotSpec
import qualified Parun.Codec.TeamIdSpec
import qualified Parun.Codec.TeamsSpec
import qualified Parun.Codec.TextWordSpec
import qualified Parun.Codec.TheseDiscardSpec
import qualified Parun.Codec.TimedSpec
import qualified Parun.Codec.TimesSpec
import qualified Parun.Codec.TimestampSpec
import qualified Parun.Codec.TogetherSpec
import qualified Parun.Codec.TokenPatternSpec
import qualified Parun.Codec.TokenRSpec
import qualified Parun.Codec.TopOfLibrarySpec
import qualified Parun.Codec.TopOfLibraryUntilSpec
import qualified Parun.Codec.ToughnessSpec
import qualified Parun.Codec.TraitSpec
import qualified Parun.Codec.TransformedSpec
import qualified Parun.Codec.TriggerConditionSpec
import qualified Parun.Codec.TriggerFrequencySpec
import qualified Parun.Codec.TriggerLimitSpec
import qualified Parun.Codec.TriggerSourceSpec
import qualified Parun.Codec.TriggeredAbilitySourceSpec
import qualified Parun.Codec.TriggeredAbilitySpec
import qualified Parun.Codec.TurnFaceDownSpec
import qualified Parun.Codec.TurnRoleSpec
import qualified Parun.Codec.TurnScopeSpec
import qualified Parun.Codec.TurnUpEventSpec
import qualified Parun.Codec.TurnUpProcedureSpec
import qualified Parun.Codec.TurnUpRSpec
import qualified Parun.Codec.TurnUpRewriteSpec
import qualified Parun.Codec.TurnWindowSpec
import qualified Parun.Codec.TurnedFaceUpSpec
import qualified Parun.Codec.TurnedUpOffDeckSpec
import qualified Parun.Codec.TypeLineSpec
import qualified Parun.Codec.TypesAreSpec
import qualified Parun.Codec.UntapHoldSpec
import qualified Parun.Codec.UntapRSpec
import qualified Parun.Codec.UntapRestrictionSpec
import qualified Parun.Codec.UntapRewriteSpec
import qualified Parun.Codec.UsesSpec
import qualified Parun.Codec.VanguardSpec
import qualified Parun.Codec.VentureMarkerEnteredSpec
import qualified Parun.Codec.ViewIsSpec
import qualified Parun.Codec.VoteSpec
import qualified Parun.Codec.VotedSpec
import qualified Parun.Codec.WardSpec
import qualified Parun.Codec.WhenSpec
import qualified Parun.Codec.WhenSpentSpec
import qualified Parun.Codec.WhichCountersSpec
import qualified Parun.Codec.WhileSpec
import qualified Parun.Codec.WithCountersSpec
import qualified Parun.Codec.WordFamilySpec
import qualified Parun.Codec.ZoneChangePatternSpec
import qualified Parun.Codec.ZoneChangeRSpec
import qualified Parun.Codec.ZoneChangeSpec
import qualified Parun.Codec.ZonePairSpec
import qualified Parun.Codec.ZoneScopeSpec
import qualified Parun.Codec.ZoneSpec
import qualified Parun.CodecIntegrationSpec
import qualified Parun.CoinSpec
import qualified Parun.ColorSpec
import qualified Parun.CombatCostSpec
import qualified Parun.CombatEffectSpec
import qualified Parun.CombatSpec
import qualified Parun.CommanderSpec
import qualified Parun.CompanionSpec
import qualified Parun.ConditionSpec
import qualified Parun.ConjureSpec
import qualified Parun.ConspiracySpec
import qualified Parun.ContraptionSpec
import qualified Parun.CopySpec
import qualified Parun.CoreSpec
import qualified Parun.CostSpec
import qualified Parun.CountSpec
import qualified Parun.CounterKeywordTriggerSpec
import qualified Parun.CounterRestrictionSpec
import qualified Parun.CounterspellSpec
import qualified Parun.CrewSpec
import qualified Parun.DamageReplacementSpec
import qualified Parun.DamageSpec
import qualified Parun.DaytimeSpec
import qualified Parun.DecideSpec
import qualified Parun.DecimalSpec
import qualified Parun.DeckListSpec
import qualified Parun.DecksSpec
import qualified Parun.DepartureSpec
import qualified Parun.DetainSpec
import qualified Parun.DevotionSpec
import qualified Parun.DiceSpec
import qualified Parun.DriverSpec
import qualified Parun.DungeonSpec
import qualified Parun.EarthbendSpec
import qualified Parun.EffectLintSpec
import qualified Parun.EmperorSpec
import qualified Parun.EngineSpec
import qualified Parun.EntryReplacementSpec
import qualified Parun.EntryRestrictionSpec
import qualified Parun.EventSpec
import qualified Parun.EventTriggerSpec
import qualified Parun.ExileSpec
import qualified Parun.ExpirySpec
import qualified Parun.Extra.BuilderSpec
import qualified Parun.Extra.EitherSpec
import qualified Parun.Extra.IntSpec
import qualified Parun.Extra.IntegerSpec
import qualified Parun.Extra.MonoidSpec
import qualified Parun.Extra.NaturalSpec
import qualified Parun.Extra.OrdSpec
import qualified Parun.Extra.ParsecSpec
import qualified Parun.Extra.SemigroupSpec
import qualified Parun.Extra.Word64Spec
import qualified Parun.Extra.Word8Spec
import qualified Parun.FaceDownSpec
import qualified Parun.FilterPositionLintSpec
import qualified Parun.FilterSpec
import qualified Parun.FlipSpec
import qualified Parun.ForageSpec
import qualified Parun.FragmentedSpec
import qualified Parun.GameSpec
import qualified Parun.GoadSpec
import qualified Parun.HarnessSpec
import qualified Parun.HealSpec
import qualified Parun.IngestSpec
import qualified Parun.InitiativeSpec
import qualified Parun.InvestigateSpec
import qualified Parun.Json.ArraySpec
import qualified Parun.Json.BooleanSpec
import qualified Parun.Json.NullSpec
import qualified Parun.Json.NumberSpec
import qualified Parun.Json.ObjectSpec
import qualified Parun.Json.PairSpec
import qualified Parun.Json.StringSpec
import qualified Parun.Json.ValueSpec
import qualified Parun.JsonCodec.ArmSpec
import qualified Parun.JsonCodec.CommonSpec
import qualified Parun.JsonCodec.FieldsSpec
import qualified Parun.JsonPointer.EvaluateSpec
import qualified Parun.JsonPointer.PointerSpec
import qualified Parun.JsonPointer.TokenSpec
import qualified Parun.JsonSchema.DefineSpec
import qualified Parun.JsonSchema.NameSpec
import qualified Parun.JsonSchema.PatternSpec
import qualified Parun.JsonSchema.SchemaSpec
import qualified Parun.JsonSchema.ValidateSpec
import qualified Parun.KeywordTriggerSpec
import qualified Parun.LearnSpec
import qualified Parun.LeavesTriggerSpec
import qualified Parun.LibraryOrderSpec
import qualified Parun.LifeReplacementSpec
import qualified Parun.LifeTriggerSpec
import qualified Parun.ManaSourceSpec
import qualified Parun.ManaSpec
import qualified Parun.ManaSymbolSpec
import qualified Parun.MassEffectSpec
import qualified Parun.MeldSpec
import qualified Parun.ModalDoubleFacedSpec
import qualified Parun.ModalSpec
import qualified Parun.MoveCounterSpec
import qualified Parun.MtgishSpec
import qualified Parun.MulliganSpec
import qualified Parun.MutateSpec
import qualified Parun.OmenSpec
import qualified Parun.OracleSpec
import qualified Parun.OutsideTheGameSpec
import qualified Parun.PhasingSpec
import qualified Parun.PlanechaseSpec
import qualified Parun.PlaneswalkerCombatSpec
import qualified Parun.PlaneswalkerSpec
import qualified Parun.Play.SplitMixSpec
import qualified Parun.PlayerDesignationSpec
import qualified Parun.PlayerEffectSpec
import qualified Parun.PlayerViewSpec
import qualified Parun.PopulateSpec
import qualified Parun.PowerToughnessSpec
import qualified Parun.PreparationSpec
import qualified Parun.PreventionSpec
import qualified Parun.ProjectionSpec
import qualified Parun.ProtocolSpec
import qualified Parun.PrototypeSpec
import qualified Parun.PutCounterSpec
import qualified Parun.RadSpec
import qualified Parun.RangeOfInfluenceSpec
import qualified Parun.RecordSpec
import qualified Parun.RecruitSpec
import qualified Parun.Registry as Registry
import qualified Parun.RegistrySpec
import qualified Parun.RemoveCounterSpec
import qualified Parun.ReplacementSpec
import qualified Parun.ReplaySpec
import qualified Parun.ReplySpec
import qualified Parun.ResolveSpec
import qualified Parun.RestampSpec
import qualified Parun.ReversalSpec
import qualified Parun.RingSpec
import qualified Parun.RoomSpec
import qualified Parun.SacrificeRestrictionSpec
import qualified Parun.SaddleSpec
import qualified Parun.SagaSpec
import qualified Parun.ScenarioSpec
import qualified Parun.SetupSpec
import qualified Parun.ShieldCounterSpec
import qualified Parun.SlugSpec
import qualified Parun.SpaceSculptorSpec
import qualified Parun.Spec as Spec
import qualified Parun.SpecialActionSpec
import qualified Parun.SpeedSpec
import qualified Parun.SplitSecondSpec
import qualified Parun.StationSpec
import qualified Parun.StickerSpec
import qualified Parun.TargetPerPlayerSpec
import qualified Parun.TargetSpec
import qualified Parun.TeamSpec
import qualified Parun.TransformSpec
import qualified Parun.TriggerSpec
import qualified Parun.TurnSpec
import qualified Parun.UntapRestrictionSpec
import qualified Parun.Uri.FragmentSpec
import qualified Parun.VanguardSpec
import qualified Parun.VariableEffectSpec
import qualified Parun.VisibilitySpec
import qualified Parun.VoteSpec
import qualified Parun.ZoneChangeSpec
import qualified Parun.ZoneReplacementSpec
import qualified Parun.ZoneTriggerSpec
import qualified Test.Tasty as Tasty
import qualified Test.Tasty.HUnit as HU

main :: IO ()
main = do
  root <- Registry.defaultRoot
  registry <- Registry.fileRegistry root
  testTree <- buildTestTree registry
  Tasty.defaultMain testTree

tasty :: (Monad n) => Spec.Spec IO (Writer.WriterT [Tasty.TestTree] n)
tasty =
  Spec.MkSpec
    { Spec.assertFailure = HU.assertFailure,
      Spec.describe = \s w -> do
        ts <- Trans.lift $ Writer.execWriterT w
        Writer.tell [Tasty.testGroup s ts],
      Spec.it = \s -> Writer.tell . List.singleton . HU.testCase s
    }

buildTestTree :: Registry.Registry IO -> IO Tasty.TestTree
buildTestTree = fmap (Tasty.testGroup "parun") . Writer.execWriterT . spec tasty

-- Specs that reach for card data take a registry over the same monad they
-- assert in. The rest need none at all.
spec :: (MonadIO.MonadIO n) => Spec.Spec IO n -> Registry.Registry IO -> n ()
spec s registry = do
  -- Parun.EngineSpec comes first because tasty hands tests to its thread
  -- pool in tree order, and this group holds the suite's two longest cases
  -- by an order of magnitude. Started last they were the whole tail.
  Parun.EngineSpec.spec s registry

  Parun.AbilitySlotLintSpec.spec s registry
  Parun.ActivateSpec.spec s registry
  Parun.ActivationProhibitionSpec.spec s registry
  Parun.AdventureSpec.spec s registry
  Parun.AirbendSpec.spec s registry
  Parun.AlternatingTeamsSpec.spec s registry
  Parun.AnteSpec.spec s registry
  Parun.ArchenemySpec.spec s registry
  Parun.AttackKeywordTriggerSpec.spec s registry
  Parun.AttractionSpec.spec s registry
  Parun.AuraSpec.spec s registry
  Parun.BattleSpec.spec s registry
  Parun.BindingSpec.spec s
  Parun.BoardEffectSpec.spec s registry
  Parun.CardSpec.spec s registry
  Parun.CardsSpec.spec s
  Parun.CardTriggerSpec.spec s registry
  Parun.CaseSpec.spec s registry
  Parun.CastPermissionSpec.spec s registry
  Parun.CastProhibitionSpec.spec s registry
  Parun.CastRestrictionSpec.spec s registry
  Parun.CastSpec.spec s registry
  Parun.ClashSpec.spec s registry
  Parun.ClassSpec.spec s registry
  Parun.CloakSpec.spec s registry
  Parun.Codec.AbilityAddsManaSpec.spec s
  Parun.Codec.AbilityKindSpec.spec s
  Parun.Codec.AbilityNameSpec.spec s
  Parun.Codec.AbilityTriggeredSpec.spec s
  Parun.Codec.AcquisitionSpec.spec s
  Parun.Codec.ActingPermanentSpec.spec s
  Parun.Codec.ActivatedAbilitySourceSpec.spec s
  Parun.Codec.ActivatedAbilitySpec.spec s
  Parun.Codec.ActivateManaAbilitiesSpec.spec s
  Parun.Codec.ActivationProhibitionSpec.spec s
  Parun.Codec.ActivationRestrictionSpec.spec s
  Parun.Codec.ActivationSpec.spec s
  Parun.Codec.ActivatorSpec.spec s
  Parun.Codec.ActiveAttackProhibitionSpec.spec s
  Parun.Codec.ActiveAttackRequirementSpec.spec s
  Parun.Codec.ActiveBlockRequirementSpec.spec s
  Parun.Codec.ActiveCopySpec.spec s
  Parun.Codec.ActiveEvasionSpec.spec s
  Parun.Codec.ActiveObjectProhibitionSpec.spec s
  Parun.Codec.ActivePlayerEffectSpec.spec s
  Parun.Codec.ActiveReplacementSpec.spec s
  Parun.Codec.AffectedPlayersSpec.spec s
  Parun.Codec.AffectedSpec.spec s
  Parun.Codec.AffectedUnlessSpec.spec s
  Parun.Codec.AnchorSpec.spec s
  Parun.Codec.AloneUnlessSpec.spec s
  Parun.Codec.AffectPlayersSpec.spec s
  Parun.Codec.AfterObjectTurnSpec.spec s
  Parun.Codec.AfterTurnSpec.spec s
  Parun.Codec.AgainstExiledPileSpec.spec s
  Parun.Codec.AgainstLastCardExiledWithSpec.spec s
  Parun.Codec.AgainstSlotSpec.spec s
  Parun.Codec.AggregationSpec.spec s
  Parun.Codec.AimedAtSpec.spec s
  Parun.Codec.AimedPlayersSpec.spec s
  Parun.Codec.AlternativeActivationCostSpec.spec s
  Parun.Codec.AlternativeCostSpec.spec s
  Parun.Codec.AnswerSpec.spec s
  Parun.Codec.AnyNumberDiscardSpec.spec s
  Parun.Codec.AnyNumberMatchingSpec.spec s
  Parun.Codec.ArmDelayedTriggerSpec.spec s
  Parun.Codec.ArrivalSpec.spec s
  Parun.Codec.AsCopySpec.spec s
  Parun.Codec.AttachAllSpec.spec s
  Parun.Codec.AttachBoundSpec.spec s
  Parun.Codec.AttachedToBoundSpec.spec s
  Parun.Codec.AttachRestrictionSpec.spec s
  Parun.Codec.AttachTargetSpec.spec s
  Parun.Codec.AttackCostSpec.spec s
  Parun.Codec.AttackedPlayerSpec.spec s
  Parun.Codec.AttackerBlockedSpec.spec s
  Parun.Codec.AttackerDeclaredSpec.spec s
  Parun.Codec.AttackerUnblockedSpec.spec s
  Parun.Codec.AttackersAreSpec.spec s
  Parun.Codec.AttackingPlayersSpec.spec s
  Parun.Codec.AttackLimitUnlessSpec.spec s
  Parun.Codec.AttackOptionSpec.spec s
  Parun.Codec.AttackPermissionSpec.spec s
  Parun.Codec.AttackRequirementSpec.spec s
  Parun.Codec.AttackTargetKindSpec.spec s
  Parun.Codec.AttackTargetRefSpec.spec s
  Parun.Codec.AttackTargetSpec.spec s
  Parun.Codec.AudienceSpec.spec s
  Parun.Codec.BackupSpec.spec s
  Parun.Codec.BattlefieldCandidateSpec.spec s
  Parun.Codec.BecameAttackedSpec.spec s
  Parun.Codec.BecameBlockingSpec.spec s
  Parun.Codec.BecameDesignatedSpec.spec s
  Parun.Codec.BecomeCopySpec.spec s
  Parun.Codec.BeginningStepSpec.spec s
  Parun.Codec.BeholdSpec.spec s
  Parun.Codec.BidSpec.spec s
  Parun.Codec.BindingSpec.spec s
  Parun.Codec.BlockCostSpec.spec s
  Parun.Codec.BlockersAreSpec.spec s
  Parun.Codec.BlockPermissionSpec.spec s
  Parun.Codec.BlockProducerSpec.spec s
  Parun.Codec.BlockRequirementSpec.spec s
  Parun.Codec.BlocksDeclaredSpec.spec s
  Parun.Codec.BlockRoleSpec.spec s
  Parun.Codec.BlockStatusSpec.spec s
  Parun.Codec.BoardSpec.spec s
  Parun.Codec.BoundMeasureSpec.spec s
  Parun.Codec.CandidateIdSpec.spec s
  Parun.Codec.CantAttackPlayerSpec.spec s
  Parun.Codec.CantBeBlockedBySpec.spec s
  Parun.Codec.CantBlockCreaturesSpec.spec s
  Parun.Codec.CantSearchLibrariesSpec.spec s
  Parun.Codec.CardArrivedInSpec.spec s
  Parun.Codec.ObjectCountSpec.spec s
  Parun.Codec.CardIdentitySpec.spec s
  Parun.Codec.CardLeavesZoneSpec.spec s
  Parun.Codec.CardNameSpec.spec s
  Parun.Codec.CardPutIntoGraveyardSpec.spec s
  Parun.Codec.CardSpec.spec s
  Parun.Codec.CardsPutIntoZoneSpec.spec s
  Parun.Codec.CardTypeSpec.spec s
  Parun.Codec.CastFromSpec.spec s
  Parun.Codec.CastFromZoneSpec.spec s
  Parun.Codec.CastingPermissionSpec.spec s
  Parun.Codec.CastingRestrictionSpec.spec s
  Parun.Codec.CastingSpec.spec s
  Parun.Codec.CastObligationSpec.spec s
  Parun.Codec.CastOfferSpec.spec s
  Parun.Codec.CastRepetitionSpec.spec s
  Parun.Codec.ChangeWordSpec.spec s
  Parun.Codec.ChangeTextSpec.spec s
  Parun.Codec.CharacteristicPTSpec.spec s
  Parun.Codec.CheckSpec.spec s
  Parun.Codec.ChoicesSpec.spec s
  Parun.Codec.ChooseBetweenSpec.spec s
  Parun.Codec.ChooseNumberSpec.spec s
  Parun.Codec.ChoosePermanentsSpec.spec s
  Parun.Codec.ChoosePlayerAtRandomSpec.spec s
  Parun.Codec.ChoosePlayerSpec.spec s
  Parun.Codec.ChooserSpec.spec s
  Parun.Codec.ChosenCardFromAmongSpec.spec s
  Parun.Codec.ChosenCardInGraveyardSpec.spec s
  Parun.Codec.ChosenCardInHandSpec.spec s
  Parun.Codec.ChosenQualitySpec.spec s
  Parun.Codec.ClassLevelChangeSpec.spec s
  Parun.Codec.ClassLevelSpec.spec s
  Parun.Codec.ClauseIndexSpec.spec s
  Parun.Codec.ClauseSpec.spec s
  Parun.Codec.CoinFaceSpec.spec s
  Parun.Codec.CoinFlippedSpec.spec s
  Parun.Codec.CoinReadingSpec.spec s
  Parun.Codec.ColorModeSpec.spec s
  Parun.Codec.ColorSpec.spec s
  Parun.Codec.CombatRestrictionSpec.spec s
  Parun.Codec.CombatSpec.spec s
  Parun.Codec.CombatStepSpec.spec s
  Parun.Codec.ComparesSpec.spec s
  Parun.Codec.ComparisonSpec.spec s
  Parun.Codec.CompletedDungeonSpec.spec s
  Parun.Codec.ComponentCardSpec.spec s
  Parun.Codec.ConditionSpec.spec s
  Parun.Codec.ConjureCardsSpec.spec s
  Parun.Codec.ConjureDestinationSpec.spec s
  Parun.Codec.ConjureSelectionSpec.spec s
  Parun.Codec.ConjureSpec.spec s
  Parun.Codec.ContinuousEffectSpec.spec s
  Parun.Codec.ControlChangedSpec.spec s
  Parun.Codec.ControlClockSpec.spec s
  Parun.Codec.ControlDurationSpec.spec s
  Parun.Codec.ControlMarginSpec.spec s
  Parun.Codec.ControllerBecomesTargetSpec.spec s
  Parun.Codec.ControllerRelationSpec.spec s
  Parun.Codec.ControlPlayerSpec.spec s
  Parun.Codec.ControlSidesSpec.spec s
  Parun.Codec.ControlSlotsSpec.spec s
  Parun.Codec.ConvokingSpec.spec s
  Parun.Codec.CopyClauseSpec.spec s
  Parun.Codec.CopyCoverageSpec.spec s
  Parun.Codec.CopyExceptionSpec.spec s
  Parun.Codec.CopyOriginalSpec.spec s
  Parun.Codec.CopyRecipientSpec.spec s
  Parun.Codec.CopyDomainSpec.spec s
  Parun.Codec.AttachRewriteSpec.spec s
  Parun.Codec.AttachRSpec.spec s
  Parun.Codec.CopyStackObjectSpec.spec s
  Parun.Codec.CopyTargetsSpec.spec s
  Parun.Codec.CostAmountSpec.spec s
  Parun.Codec.CostBasisSpec.spec s
  Parun.Codec.CostChangeSpec.spec s
  Parun.Codec.CostChoiceSpec.spec s
  Parun.Codec.CostComponentSpec.spec s
  Parun.Codec.CostDirectionSpec.spec s
  Parun.Codec.CostKeywordSpec.spec s
  Parun.Codec.CostModifierSpec.spec s
  Parun.Codec.CostReductionSpec.spec s
  Parun.Codec.CostScaleSpec.spec s
  Parun.Codec.CostSpec.spec s
  Parun.Codec.CostSubjectSpec.spec s
  Parun.Codec.CouldProduceSpec.spec s
  Parun.Codec.CountedDiscardSpec.spec s
  Parun.Codec.CounterabilitySpec.spec s
  Parun.Codec.CounterChangeSpec.spec s
  Parun.Codec.CounterDestinationSpec.spec s
  Parun.Codec.CounteredEndSpec.spec s
  Parun.Codec.CounteringSpec.spec s
  Parun.Codec.CounterKindSpec.spec s
  Parun.Codec.CounterNameSpec.spec s
  Parun.Codec.CounterPatternSpec.spec s
  Parun.Codec.CounterPlacementSpec.spec s
  Parun.Codec.CounterRestrictionSpec.spec s
  Parun.Codec.CounterRSpec.spec s
  Parun.Codec.CountersAreSpec.spec s
  Parun.Codec.CountersFromPermanentsSpec.spec s
  Parun.Codec.CountersFromThisSpec.spec s
  Parun.Codec.CounterSpec.spec s
  Parun.Codec.CounterSpreadSpec.spec s
  Parun.Codec.CounterSubjectSpec.spec s
  Parun.Codec.CountIsSpec.spec s
  Parun.Codec.CountSpec.spec s
  Parun.Codec.CraftSpec.spec s
  Parun.Codec.CreateCopySpec.spec s
  Parun.Codec.CreateSpec.spec s
  Parun.Codec.CreatureBecomesBlockedByAtLeastSpec.spec s
  Parun.Codec.CreatureExploitsSpec.spec s
  Parun.Codec.CrewingSpec.spec s
  Parun.Codec.CrewRestrictionSpec.spec s
  Parun.Codec.CyclingSpec.spec s
  Parun.Codec.DamageDirectionSpec.spec s
  Parun.Codec.DamageEventSpec.spec s
  Parun.Codec.DamageIsSpec.spec s
  Parun.Codec.DamageKindSpec.spec s
  Parun.Codec.DamagePartSpec.spec s
  Parun.Codec.DamagePatternSpec.spec s
  Parun.Codec.DamagePreventedSpec.spec s
  Parun.Codec.DamagedPartySpec.spec s
  Parun.Codec.DealtDamageToSpec.spec s
  Parun.Codec.DamageRewriteSpec.spec s
  Parun.Codec.DamageRSpec.spec s
  Parun.Codec.DaytimeSpec.spec s
  Parun.Codec.DealDamageSpec.spec s
  Parun.Codec.DealsDamageToPlayerSpec.spec s
  Parun.Codec.DeciderSpec.spec s
  Parun.Codec.DefendersAreSpec.spec s
  Parun.Codec.DefenseSpec.spec s
  Parun.Codec.DelayedTriggerSpec.spec s
  Parun.Codec.DepartureSpec.spec s
  Parun.Codec.DesignateSpec.spec s
  Parun.Codec.DesignationSpec.spec s
  Parun.Codec.DestroySpec.spec s
  Parun.Codec.DivideSpec.spec s
  Parun.Codec.DestructionRewriteSpec.spec s
  Parun.Codec.DestructionRSpec.spec s
  Parun.Codec.DevotionSpec.spec s
  Parun.Codec.DevourCountSpec.spec s
  Parun.Codec.DevourSpec.spec s
  Parun.Codec.DiceReadingSpec.spec s
  Parun.Codec.DieRollRewriteSpec.spec s
  Parun.Codec.DieRollRSpec.spec s
  Parun.Codec.DifferentInSpec.spec s
  Parun.Codec.DiscardCardsSpec.spec s
  Parun.Codec.DiscardCauseSpec.spec s
  Parun.Codec.DiscardedSpec.spec s
  Parun.Codec.DiscardSpec.spec s
  Parun.Codec.DistinctOfSpec.spec s
  Parun.Codec.DoesNotUntapNextSpec.spec s
  Parun.Codec.DrawCountRewriteSpec.spec s
  Parun.Codec.DrawCountRSpec.spec s
  Parun.Codec.DrawRewriteSpec.spec s
  Parun.Codec.DrawRSpec.spec s
  Parun.Codec.DrawSpec.spec s
  Parun.Codec.DrewSpec.spec s
  Parun.Codec.DungeonRoomSpec.spec s
  Parun.Codec.DurationEventSpec.spec s
  Parun.Codec.DurationSpec.spec s
  Parun.Codec.DuringPhaseSpec.spec s
  Parun.Codec.EachCardFromAmongSpec.spec s
  Parun.Codec.EnteredZoneSpec.spec s
  Parun.Codec.FromAnywhereSpec.spec s
  Parun.Codec.EachCardInGraveyardSpec.spec s
  Parun.Codec.EachCardInExiledPileSpec.spec s
  Parun.Codec.EachCardInHandSpec.spec s
  Parun.Codec.EffectSpec.spec s
  Parun.Codec.EmergeSpec.spec s
  Parun.Codec.EmperorsSpec.spec s
  Parun.Codec.EndingStepSpec.spec s
  Parun.Codec.EndTurnSignalSpec.spec s
  Parun.Codec.EnteringTogetherSpec.spec s
  Parun.Codec.EntersWithSpec.spec s
  Parun.Codec.EntrantSpec.spec s
  Parun.Codec.EntryAttackSpec.spec s
  Parun.Codec.EntryBlockSpec.spec s
  Parun.Codec.EntryHostSpec.spec s
  Parun.Codec.EntryControllerSpec.spec s
  Parun.Codec.EntryFlipSpec.spec s
  Parun.Codec.EntryOptionSpec.spec s
  Parun.Codec.EntryPriceSpec.spec s
  Parun.Codec.EntryRestrictionSpec.spec s
  Parun.Codec.EntryRewriteSpec.spec s
  Parun.Codec.EntryRidersSpec.spec s
  Parun.Codec.EntryRSpec.spec s
  Parun.Codec.EntrySpec.spec s
  Parun.Codec.EquipSpec.spec s
  Parun.Codec.EventGroupSpec.spec s
  Parun.Codec.EventExpirySpec.spec s
  Parun.Codec.EventShapeSpec.spec s
  Parun.Codec.ExcessDestinationSpec.spec s
  Parun.Codec.ExchangeBlocksSpec.spec s
  Parun.Codec.ExchangedValueSpec.spec s
  Parun.Codec.ExchangeSidesSpec.spec s
  Parun.Codec.ExchangeValuesSpec.spec s
  Parun.Codec.ExchangeZonesSpec.spec s
  Parun.Codec.ExileCardsFromGraveyardSpec.spec s
  Parun.Codec.ExileCardsFromHandSpec.spec s
  Parun.Codec.ExiledCardAbilitiesSpec.spec s
  Parun.Codec.ExiledPileSpec.spec s
  Parun.Codec.ExileFromGraveyardSpec.spec s
  Parun.Codec.ExileHauntingSpec.spec s
  Parun.Codec.ExileLinkSpec.spec s
  Parun.Codec.ExileLookerSpec.spec s
  Parun.Codec.ExileMaterialsSpec.spec s
  Parun.Codec.ExilePermanentsSpec.spec s
  Parun.Codec.ExilePlayPermissionSpec.spec s
  Parun.Codec.ExpansionSpec.spec s
  Parun.Codec.ExpirySpec.spec s
  Parun.Codec.ExploitedSpec.spec s
  Parun.Codec.ExtraPhaseSpec.spec s
  Parun.Codec.ExtraTurnSpec.spec s
  Parun.Codec.ExtraVotesSpec.spec s
  Parun.Codec.FaceDownCharacteristicsSpec.spec s
  Parun.Codec.FaceDownReasonSpec.spec s
  Parun.Codec.FaceDownStateSpec.spec s
  Parun.Codec.FaceSpec.spec s
  Parun.Codec.FacingSpec.spec s
  Parun.Codec.FightSpec.spec s
  Parun.Codec.FilterSpec.spec s
  Parun.Codec.FlipCoinSpec.spec s
  Parun.Codec.FloatingCandidateSpec.spec s
  Parun.Codec.ForbidAttackSpec.spec s
  Parun.Codec.ForbidBeingBlockedSpec.spec s
  Parun.Codec.ForEachNumberSpec.spec s
  Parun.Codec.ForEachSpec.spec s
  Parun.Codec.ForetellCostSpec.spec s
  Parun.Codec.FromOutsideTheGameSpec.spec s
  Parun.Codec.FromReferenceSpec.spec s
  Parun.Codec.GainControlSpec.spec s
  Parun.Codec.GameEventSpec.spec s
  Parun.Codec.GameLossRSpec.spec s
  Parun.Codec.GameOutcomeSpec.spec s
  Parun.Codec.GameSettingsSpec.spec s
  Parun.Codec.GiftSpec.spec s
  Parun.Codec.GrantedAbilitySpec.spec s
  Parun.Codec.GrantLookAtExiledSpec.spec s
  Parun.Codec.GrantPlayFromExileSpec.spec s
  Parun.Codec.GraveyardOrderSpec.spec s
  Parun.Codec.HalfUnlockedSpec.spec s
  Parun.Codec.HalvedSpec.spec s
  Parun.Codec.HandActionSpec.spec s
  Parun.Codec.HybridSpec.spec s
  Parun.Codec.IfTakenSpec.spec s
  Parun.Codec.IgnoredAbilitySpec.spec s
  Parun.Codec.ImpendingSpec.spec s
  Parun.Codec.InherentTriggerSourceSpec.spec s
  Parun.Codec.InitiativeTargetSpec.spec s
  Parun.Codec.InstanceOrdinalSpec.spec s
  Parun.Codec.InZoneSpec.spec s
  Parun.Codec.InstructionRSpec.spec s
  Parun.Codec.InstructionRewriteSpec.spec s
  Parun.Codec.KeywordCountSpec.spec s
  Parun.Codec.KeywordDesignatorSpec.spec s
  Parun.Codec.KeywordFamilySpec.spec s
  Parun.Codec.KeywordInstanceSpec.spec s
  Parun.Codec.KeywordsAreSpec.spec s
  Parun.Codec.KeywordSpec.spec s
  Parun.Codec.LabelSpec.spec s
  Parun.Codec.LandAllowanceSpec.spec s
  Parun.Codec.LandPlayedSpec.spec s
  Parun.Codec.LastKnownSpec.spec s
  Parun.Codec.LayoutSpec.spec s
  Parun.Codec.LeftTheGameSpec.spec s
  Parun.Codec.LibraryDepthSpec.spec s
  Parun.Codec.LibraryPlacementSpec.spec s
  Parun.Codec.LibraryPositionSpec.spec s
  Parun.Codec.LifeChangeSpec.spec s
  Parun.Codec.LifeGainRewriteSpec.spec s
  Parun.Codec.LifeGainRSpec.spec s
  Parun.Codec.LifeIsSpec.spec s
  Parun.Codec.LifeLossCauseSpec.spec s
  Parun.Codec.LifeLossPatternSpec.spec s
  Parun.Codec.LifeLossRewriteSpec.spec s
  Parun.Codec.LifeLossRSpec.spec s
  Parun.Codec.LifeLossSpec.spec s
  Parun.Codec.LimitUnlessSpec.spec s
  Parun.Codec.LoggedEventSpec.spec s
  Parun.Codec.LookAtSpec.spec s
  Parun.Codec.ArrangeInLibrarySpec.spec s
  Parun.Codec.LookedSpec.spec s
  Parun.Codec.PlayerInstructionSpec.spec s
  Parun.Codec.SeatViewSpec.spec s
  Parun.Codec.PlayerViewSpec.spec s
  Parun.Codec.QuestionSpec.spec s
  Parun.Codec.RequestSpec.spec s
  Parun.Codec.ObjectViewSpec.spec s
  Parun.Codec.AbilityViewSpec.spec s
  Parun.Codec.LoopMembersSpec.spec s
  Parun.Codec.LoyaltyKindSpec.spec s
  Parun.Codec.LoyaltySpec.spec s
  Parun.Codec.MadnessCostSpec.spec s
  Parun.Codec.MakeForetoldSpec.spec s
  Parun.Codec.ManaAbilityResolvedSpec.spec s
  Parun.Codec.ManaAddedCauseSpec.spec s
  Parun.Codec.ManaAddedSpec.spec s
  Parun.Codec.ManaAdditionSpec.spec s
  Parun.Codec.ManaCostSpec.spec s
  Parun.Codec.ManaCountSpec.spec s
  Parun.Codec.ManaFilterSpec.spec s
  Parun.Codec.ManaProductionSpec.spec s
  Parun.Codec.ManaRestrictionSpec.spec s
  Parun.Codec.ManaRetentionSpec.spec s
  Parun.Codec.ManaRiderEffectSpec.spec s
  Parun.Codec.ManaRiderSpec.spec s
  Parun.Codec.ManaSpec.spec s
  Parun.Codec.ManaSpecificationSpec.spec s
  Parun.Codec.ManaSpendingSpec.spec s
  Parun.Codec.ManaSymbolSpec.spec s
  Parun.Codec.ManaTypeSpec.spec s
  Parun.Codec.ManaUnitSpec.spec s
  Parun.Codec.ManifestedDreadSpec.spec s
  Parun.Codec.MeasureSpec.spec s
  Parun.Codec.MeasuresSpec.spec s
  Parun.Codec.MeldSourceSpec.spec s
  Parun.Codec.MeldSpec.spec s
  Parun.Codec.MentoredSpec.spec s
  Parun.Codec.MergeComponentSpec.spec s
  Parun.Codec.MilledSpec.spec s
  Parun.Codec.MillSpec.spec s
  Parun.Codec.MillTallySpec.spec s
  Parun.Codec.ModalSpec.spec s
  Parun.Codec.ModeIndexSpec.spec s
  Parun.Codec.ModeSelectionSpec.spec s
  Parun.Codec.ModeSpec.spec s
  Parun.Codec.ModificationSpec.spec s
  Parun.Codec.ModifiedRollSpec.spec s
  Parun.Codec.ModifyPowerToughnessSpec.spec s
  Parun.Codec.ModifyTargetSpec.spec s
  Parun.Codec.MonarchIsSpec.spec s
  Parun.Codec.MonarchTargetSpec.spec s
  Parun.Codec.MonarchWatchSpec.spec s
  Parun.Codec.MorphSpec.spec s
  Parun.Codec.MorphVariantSpec.spec s
  Parun.Codec.MoveCountersSpec.spec s
  Parun.Codec.MovedBetweenSpec.spec s
  Parun.Codec.MovedKindsSpec.spec s
  Parun.Codec.MovedSpec.spec s
  Parun.Codec.MoveDurationSpec.spec s
  Parun.Codec.MoveManaSpec.spec s
  Parun.Codec.MoveSpec.spec s
  Parun.Codec.MoveToZoneSpec.spec s
  Parun.Codec.NameChooserSpec.spec s
  Parun.Codec.NamesAreSpec.spec s
  Parun.Codec.NinjutsuSpec.spec s
  Parun.Codec.NinjutsuVariantSpec.spec s
  Parun.Codec.ObjectIdSpec.spec s
  Parun.Codec.ObjectRefSpec.spec s
  Parun.Codec.ObjectSnapshotSpec.spec s
  Parun.Codec.ObjectSpec.spec s
  Parun.Codec.OfferCastSpec.spec s
  Parun.Codec.OnsetSpec.spec s
  Parun.Codec.OperandSpec.spec s
  Parun.Codec.OptionalDecisionSpec.spec s
  Parun.Codec.CombatDamageOptionSpec.spec s
  Parun.Codec.OptionalitySpec.spec s
  Parun.Codec.OrElseSpec.spec s
  Parun.Codec.OutsideCardSpec.spec s
  Parun.Codec.OutsideDestinationSpec.spec s
  Parun.Codec.OutsideObjectSpec.spec s
  Parun.Codec.OwnedZoneSpec.spec s
  Parun.Codec.PaidExpirySpec.spec s
  Parun.Codec.PairingSpec.spec s
  Parun.Codec.PartnerTextSpec.spec s
  Parun.Codec.PastActivationSpec.spec s
  Parun.Codec.PayBranchSpec.spec s
  Parun.Codec.PayGateSpec.spec s
  Parun.Codec.PayingSpec.spec s
  Parun.Codec.PaymentDecisionSpec.spec s
  Parun.Codec.PayObligationSpec.spec s
  Parun.Codec.PendingEntryEffectSpec.spec s
  Parun.Codec.PendingReplacementEffectSpec.spec s
  Parun.Codec.PermanentActionSpec.spec s
  Parun.Codec.PermanentBecomesDesignatedSpec.spec s
  Parun.Codec.PermanentCandidateSpec.spec s
  Parun.Codec.PermanentDealsCombatDamageToPlayerSpec.spec s
  Parun.Codec.PermanentSacrificedSpec.spec s
  Parun.Codec.PermanentsBecomeTargetedSpec.spec s
  Parun.Codec.PermanentsDealCombatDamageToPlayerSpec.spec s
  Parun.Codec.PermanentTappedForManaSpec.spec s
  Parun.Codec.PermanentWasSacrificedSpec.spec s
  Parun.Codec.PermissionCostSpec.spec s
  Parun.Codec.PermissionLimitSpec.spec s
  Parun.Codec.PermissionPoolSpec.spec s
  Parun.Codec.PermissionVerbSpec.spec s
  Parun.Codec.PhasedOutSpec.spec s
  Parun.Codec.PhasePatternSpec.spec s
  Parun.Codec.PhaseSelectorSpec.spec s
  Parun.Codec.PhaseSpec.spec s
  Parun.Codec.PileDrawSpec.spec s
  Parun.Codec.PileSpec.spec s
  Parun.Codec.PlacementSpec.spec s
  Parun.Codec.PlanarDieFaceSpec.spec s
  Parun.Codec.PlanarDieRolledSpec.spec s
  Parun.Codec.PlayerActionSpec.spec s
  Parun.Codec.PlayerAttacksPlayerSpec.spec s
  Parun.Codec.PlayerAttacksWithSpec.spec s
  Parun.Codec.PlayerChoiceSpec.spec s
  Parun.Codec.PlayerControlSpec.spec s
  Parun.Codec.PlayerCounterKindSpec.spec s
  Parun.Codec.PlayerCountersAreSpec.spec s
  Parun.Codec.PlayerCountersSpec.spec s
  Parun.Codec.PlayerCounterTallySpec.spec s
  Parun.Codec.PlayersDealtDamageSpec.spec s
  Parun.Codec.PlayersWhoSpec.spec s
  Parun.Codec.SuperlativeSpec.spec s
  Parun.Codec.PlayerDesignationSpec.spec s
  Parun.Codec.PlayerDesignationTallySpec.spec s
  Parun.Codec.PlayerDrawsNthCardSpec.spec s
  Parun.Codec.PlayerEffectSpec.spec s
  Parun.Codec.PlayerIdSpec.spec s
  Parun.Codec.PlayerQuantitySpec.spec s
  Parun.Codec.PlayerRefSpec.spec s
  Parun.Codec.PlayerRelationSpec.spec s
  Parun.Codec.PlayerSacrificesSpec.spec s
  Parun.Codec.PlayerScopeSpec.spec s
  Parun.Codec.PlayerSpec.spec s
  Parun.Codec.PlayerStaticAbilitySpec.spec s
  Parun.Codec.PlayBudgetSpec.spec s
  Parun.Codec.PlayPermissionOriginSpec.spec s
  Parun.Codec.PlaysLandSpec.spec s
  Parun.Codec.PlotFromZoneSpec.spec s
  Parun.Codec.PlusSpec.spec s
  Parun.Codec.PoolSpec.spec s
  Parun.Codec.PowerSpec.spec s
  Parun.Codec.PowerToughnessIsSpec.spec s
  Parun.Codec.PreventAllDamageSpec.spec s
  Parun.Codec.PreventionRiderSpec.spec s
  Parun.Codec.PreventionSpec.spec s
  Parun.Codec.PreventNextDamageSpec.spec s
  Parun.Codec.PrintedReplacementSpec.spec s
  Parun.Codec.PrintingIdSpec.spec s
  Parun.Codec.PrintingSpec.spec s
  Parun.Codec.ProductionTagSpec.spec s
  Parun.Codec.ProhibitionSpec.spec s
  Parun.Codec.ProhibitSpec.spec s
  Parun.Codec.ProjectedCharacteristicsSpec.spec s
  Parun.Codec.ProtectionSpec.spec s
  Parun.Codec.PrototypeSpec.spec s
  Parun.Codec.PutCountersFromSpec.spec s
  Parun.Codec.PutCountersSpec.spec s
  Parun.Codec.QuantitySpec.spec s
  Parun.Codec.RangeOfInfluenceSpec.spec s
  Parun.Codec.ReadinessSpec.spec s
  Parun.Codec.RecipientSpec.spec s
  Parun.Codec.RedirectDamageSpec.spec s
  Parun.Codec.ReferenceSpec.spec s
  Parun.Codec.RegenerabilitySpec.spec s
  Parun.Codec.ReinforceSpec.spec s
  Parun.Codec.RemoveCountersSpec.spec s
  Parun.Codec.RemovePlayerCountersSpec.spec s
  Parun.Codec.RepeatIfSpec.spec s
  Parun.Codec.RepeatSpec.spec s
  Parun.Codec.ReplacementEffectSpec.spec s
  Parun.Codec.ReplacementOriginSpec.spec s
  Parun.Codec.ReplacementProvenanceSpec.spec s
  Parun.Codec.ReplaceSpec.spec s
  Parun.Codec.RequireAttackSpec.spec s
  Parun.Codec.RequireBlockSpec.spec s
  Parun.Codec.RequiredDefenderSpec.spec s
  Parun.Codec.RequirementAritySpec.spec s
  Parun.Codec.RestartSignalSpec.spec s
  Parun.Codec.RestrictedCreaturesSpec.spec s
  Parun.Codec.ResultSpec.spec s
  Parun.Codec.ReturnEndingSpec.spec s
  Parun.Codec.ReturnPermanentsSpec.spec s
  Parun.Codec.ReturnWatchSpec.spec s
  Parun.Codec.DrawRevealSpec.spec s
  Parun.Codec.DrawnUnderSpec.spec s
  Parun.Codec.RevealCauseSpec.spec s
  Parun.Codec.RevealTimingSpec.spec s
  Parun.Codec.RevealedThisWaySpec.spec s
  Parun.Codec.RevealObligationSpec.spec s
  Parun.Codec.RevealedSpec.spec s
  Parun.Codec.RevealSpec.spec s
  Parun.Codec.RevealWindowSpec.spec s
  Parun.Codec.RollDieSpec.spec s
  Parun.Codec.RollModifierSpec.spec s
  Parun.Codec.RoomHalfSpec.spec s
  Parun.Codec.RoomIndexSpec.spec s
  Parun.Codec.RoundingSpec.spec s
  Parun.Codec.RuleAbilitiesSpec.spec s
  Parun.Codec.SacrificeAnyNumberSpec.spec s
  Parun.Codec.SacrificeEffectSpec.spec s
  Parun.Codec.SacrificeRestrictionSpec.spec s
  Parun.Codec.SacrificerSpec.spec s
  Parun.Codec.SacrificeSpec.spec s
  Parun.Codec.SacrificeToEnterSpec.spec s
  Parun.Codec.SaddlingSpec.spec s
  Parun.Codec.ScalingSpec.spec s
  Parun.Codec.ScenarioSpec.spec s
  Parun.Codec.TurnedUpOffDeckSpec.spec s
  Parun.Codec.PlaneswalkCauseSpec.spec s
  Parun.Codec.PlaneswalkRSpec.spec s
  Parun.Codec.PlaneswalkRewriteSpec.spec s
  Parun.Codec.ScopeSpec.spec s
  Parun.Codec.SearchDestinationSpec.spec s
  Parun.Codec.SearchSpec.spec s
  Parun.Codec.SeatSpec.spec s
  Parun.Codec.SelfCountersReachedSpec.spec s
  Parun.Codec.SelfCountersRemovedSpec.spec s
  Parun.Codec.SetBasePowerToughnessSpec.spec s
  Parun.Codec.SetClassLevelSpec.spec s
  Parun.Codec.SetHalfLockedSpec.spec s
  Parun.Codec.SetPowerToughnessSpec.spec s
  Parun.Codec.ShownCardsSpec.spec s
  Parun.Codec.ShownComponentSpec.spec s
  Parun.Codec.ShowsSpec.spec s
  Parun.Codec.ShuffleIntoLibrarySpec.spec s
  Parun.Codec.SicknessSpec.spec s
  Parun.Codec.SideDeckSpec.spec s
  Parun.Codec.SkipPhaseSpec.spec s
  Parun.Codec.SlotCountSpec.spec s
  Parun.Codec.SlotNameSpec.spec s
  Parun.Codec.SlotPerPlayerSpec.spec s
  Parun.Codec.SourceChoicesSpec.spec s
  Parun.Codec.SourceSpec.spec s
  Parun.Codec.SpecialActionSpec.spec s
  Parun.Codec.SpeedDecreaseSpec.spec s
  Parun.Codec.SpellCastSpec.spec s
  Parun.Codec.SpellWasCastSpec.spec s
  Parun.Codec.SpellWasCopiedSpec.spec s
  Parun.Codec.SpendManaAsThoughSpec.spec s
  Parun.Codec.SpendTriggerSpec.spec s
  Parun.Codec.SpliceSpec.spec s
  Parun.Codec.StackObjectKindSpec.spec s
  Parun.Codec.StatedFlipSpec.spec s
  Parun.Codec.StaticAbilitySpec.spec s
  Parun.Codec.StatusSpec.spec s
  Parun.Codec.StepBeganSpec.spec s
  Parun.Codec.StepBeginsSpec.spec s
  Parun.Codec.StickerKindSpec.spec s
  Parun.Codec.StickerSheetSpec.spec s
  Parun.Codec.StoredResultSpec.spec s
  Parun.Codec.TextWordSpec.spec s
  Parun.Codec.WordFamilySpec.spec s
  Parun.Codec.SubtypesAreSpec.spec s
  Parun.Codec.SubtypeSpec.spec s
  Parun.Codec.SupertypeSpec.spec s
  Parun.Codec.SuspendCountersSpec.spec s
  Parun.Codec.SuspendSpec.spec s
  Parun.Codec.TakeExtraTurnSpec.spec s
  Parun.Codec.TakingSpec.spec s
  Parun.Codec.TapSpec.spec s
  Parun.Codec.TapForManaSpec.spec s
  Parun.Codec.TapForTotalPowerSpec.spec s
  Parun.Codec.TappedForManaSpec.spec s
  Parun.Codec.TappedIsSpec.spec s
  Parun.Codec.TapPermanentsSpec.spec s
  Parun.Codec.TapStateSpec.spec s
  Parun.Codec.TargetChooserSpec.spec s
  Parun.Codec.TargetCountSpec.spec s
  Parun.Codec.TargetRestrictionSpec.spec s
  Parun.Codec.TargetSlotSpec.spec s
  Parun.Codec.TeamIdSpec.spec s
  Parun.Codec.TeamsSpec.spec s
  Parun.Codec.TheseDiscardSpec.spec s
  Parun.Codec.TimedSpec.spec s
  Parun.Codec.TimesSpec.spec s
  Parun.Codec.TimestampSpec.spec s
  Parun.Codec.TogetherSpec.spec s
  Parun.Codec.TokenPatternSpec.spec s
  Parun.Codec.TokenRSpec.spec s
  Parun.Codec.TopOfLibrarySpec.spec s
  Parun.Codec.TopOfLibraryUntilSpec.spec s
  Parun.Codec.ToughnessSpec.spec s
  Parun.Codec.TraitSpec.spec s
  Parun.Codec.TransformedSpec.spec s
  Parun.Codec.TriggerConditionSpec.spec s
  Parun.Codec.TriggeredAbilitySourceSpec.spec s
  Parun.Codec.TriggeredAbilitySpec.spec s
  Parun.Codec.TriggerFrequencySpec.spec s
  Parun.Codec.TriggerLimitSpec.spec s
  Parun.Codec.TriggerSourceSpec.spec s
  Parun.Codec.TurnedFaceUpSpec.spec s
  Parun.Codec.TurnFaceDownSpec.spec s
  Parun.Codec.TurnRoleSpec.spec s
  Parun.Codec.TurnScopeSpec.spec s
  Parun.Codec.TurnUpEventSpec.spec s
  Parun.Codec.TurnUpProcedureSpec.spec s
  Parun.Codec.TurnUpRewriteSpec.spec s
  Parun.Codec.TurnUpRSpec.spec s
  Parun.Codec.TurnWindowSpec.spec s
  Parun.Codec.TypeLineSpec.spec s
  Parun.Codec.TypesAreSpec.spec s
  Parun.Codec.UntapHoldSpec.spec s
  Parun.Codec.UntapRestrictionSpec.spec s
  Parun.Codec.UntapRewriteSpec.spec s
  Parun.Codec.UntapRSpec.spec s
  Parun.Codec.UsesSpec.spec s
  Parun.Codec.VanguardSpec.spec s
  Parun.Codec.VentureMarkerEnteredSpec.spec s
  Parun.Codec.ViewIsSpec.spec s
  Parun.Codec.VotedSpec.spec s
  Parun.Codec.VoteSpec.spec s
  Parun.Codec.WardSpec.spec s
  Parun.Codec.WhenSpec.spec s
  Parun.Codec.WhenSpentSpec.spec s
  Parun.Codec.WhichCountersSpec.spec s
  Parun.Codec.WhileSpec.spec s
  Parun.Codec.WithCountersSpec.spec s
  Parun.Codec.ZoneChangePatternSpec.spec s
  Parun.Codec.ZoneChangeRSpec.spec s
  Parun.Codec.ZoneChangeSpec.spec s
  Parun.Codec.ZonePairSpec.spec s
  Parun.Codec.ZoneScopeSpec.spec s
  Parun.Codec.ZoneSpec.spec s
  Parun.CodecIntegrationSpec.spec s registry
  Parun.CoinSpec.spec s registry
  Parun.ColorSpec.spec s registry
  Parun.CombatCostSpec.spec s registry
  Parun.CombatEffectSpec.spec s registry
  Parun.CombatSpec.spec s registry
  Parun.CommanderSpec.spec s registry
  Parun.CompanionSpec.spec s registry
  Parun.ConditionSpec.spec s registry
  Parun.ConjureSpec.spec s registry
  Parun.ConspiracySpec.spec s registry
  Parun.ContraptionSpec.spec s registry
  Parun.CopySpec.copiedAbilitySpec s registry
  Parun.CopySpec.copyAbilityOnStackSpec s registry
  Parun.CopySpec.copySpellSpec s registry
  Parun.CopySpec.faceDownCopySpec s registry
  Parun.CopySpec.flamerushRiderSpec s registry
  Parun.CopySpec.garthSpec s registry
  Parun.CopySpec.graveyardTokenCopySpec s registry
  Parun.CopySpec.ivySpec s registry
  Parun.CopySpec.leylineOfResonanceSpec s registry
  Parun.CopySpec.magarSpec s registry
  Parun.CopySpec.metamorphicAlterationSpec s registry
  Parun.CopySpec.permanentCopySpec s registry
  Parun.CopySpec.spec s registry
  Parun.CopySpec.stirCopySpec s registry
  Parun.CopySpec.zadaSpec s registry
  Parun.CoreSpec.spec s registry
  Parun.CostSpec.spec s registry
  Parun.CounterKeywordTriggerSpec.spec s registry
  Parun.CounterRestrictionSpec.spec s registry
  Parun.CounterspellSpec.spec s registry
  Parun.CountSpec.spec s registry
  Parun.CrewSpec.spec s registry
  Parun.DamageReplacementSpec.spec s registry
  Parun.DamageSpec.spec s registry
  Parun.DaytimeSpec.spec s registry
  Parun.DecideSpec.spec s
  Parun.DecimalSpec.spec s
  Parun.DeckListSpec.spec s
  Parun.DepartureSpec.spec s registry
  Parun.DetainSpec.spec s registry
  Parun.DevotionSpec.spec s registry
  Parun.DiceSpec.spec s registry
  Parun.DriverSpec.spec s registry
  Parun.DungeonSpec.spec s registry
  Parun.EarthbendSpec.spec s registry
  Parun.EffectLintSpec.spec s registry
  Parun.EmperorSpec.spec s registry
  Parun.EntryReplacementSpec.spec s registry
  Parun.EntryRestrictionSpec.spec s registry
  Parun.EventSpec.spec s registry
  Parun.EventTriggerSpec.spec s registry
  Parun.ExileSpec.spec s registry
  Parun.ExpirySpec.spec s registry
  Parun.Extra.BuilderSpec.spec s
  Parun.Extra.EitherSpec.spec s
  Parun.Extra.IntegerSpec.spec s
  Parun.Extra.IntSpec.spec s
  Parun.Extra.MonoidSpec.spec s
  Parun.Extra.NaturalSpec.spec s
  Parun.Extra.Word64Spec.spec s
  Parun.Play.SplitMixSpec.spec s
  Parun.Extra.OrdSpec.spec s
  Parun.Extra.ParsecSpec.spec s
  Parun.Extra.SemigroupSpec.spec s
  Parun.Extra.Word8Spec.spec s
  Parun.FaceDownSpec.spec s registry
  Parun.FilterPositionLintSpec.spec s registry
  Parun.FilterSpec.spec s
  Parun.FlipSpec.spec s registry
  Parun.ForageSpec.spec s registry
  Parun.FragmentedSpec.spec s registry
  Parun.GameSpec.spec s registry
  Parun.GoadSpec.spec s registry
  Parun.HarnessSpec.spec s registry
  Parun.HealSpec.spec s registry
  Parun.IngestSpec.spec s
  Parun.InitiativeSpec.spec s registry
  Parun.InvestigateSpec.spec s registry
  Parun.Json.ArraySpec.spec s
  Parun.Json.BooleanSpec.spec s
  Parun.Json.NullSpec.spec s
  Parun.Json.NumberSpec.spec s
  Parun.Json.ObjectSpec.spec s
  Parun.Json.PairSpec.spec s
  Parun.Json.StringSpec.spec s
  Parun.Json.ValueSpec.spec s
  Parun.JsonCodec.ArmSpec.spec s
  Parun.JsonCodec.CommonSpec.spec s
  Parun.JsonCodec.FieldsSpec.spec s
  Parun.JsonPointer.EvaluateSpec.spec s
  Parun.JsonPointer.PointerSpec.spec s
  Parun.JsonPointer.TokenSpec.spec s
  Parun.JsonSchema.DefineSpec.spec s
  Parun.JsonSchema.NameSpec.spec s
  Parun.JsonSchema.PatternSpec.spec s
  Parun.JsonSchema.SchemaSpec.spec s
  Parun.JsonSchema.ValidateSpec.spec s
  Parun.KeywordTriggerSpec.spec s registry
  Parun.LearnSpec.spec s registry
  Parun.LeavesTriggerSpec.spec s registry
  Parun.LibraryOrderSpec.spec s registry
  Parun.LifeReplacementSpec.spec s registry
  Parun.LifeTriggerSpec.spec s registry
  Parun.ManaSourceSpec.spec s registry
  Parun.ManaSpec.spec s registry
  Parun.ManaSymbolSpec.spec s registry
  Parun.MassEffectSpec.spec s registry
  Parun.MeldSpec.spec s registry
  Parun.ModalDoubleFacedSpec.spec s registry
  Parun.ModalSpec.spec s registry
  Parun.MoveCounterSpec.spec s registry
  Parun.MulliganSpec.spec s registry
  Parun.MutateSpec.spec s registry
  Parun.OmenSpec.spec s registry
  Parun.MtgishSpec.spec s
  Parun.OracleSpec.spec s
  Parun.OutsideTheGameSpec.spec s registry
  Parun.PhasingSpec.spec s registry
  Parun.PlanechaseSpec.spec s registry
  Parun.PlaneswalkerCombatSpec.spec s registry
  Parun.PlaneswalkerSpec.ashiokLoyaltySpec s registry
  Parun.PlaneswalkerSpec.combinedLoyaltyCostSpec s registry
  Parun.PlaneswalkerSpec.countersRemovedSpec s registry
  Parun.PlaneswalkerSpec.gristLoyaltySpec s registry
  Parun.PlaneswalkerSpec.spec s registry
  Parun.PlaneswalkerSpec.tamiyoMinusXSpec s registry
  Parun.PlaneswalkerSpec.tamiyoNotebookSpec s registry
  Parun.PlaneswalkerSpec.variableLoyaltySpec s registry
  Parun.PlayerDesignationSpec.spec s registry
  Parun.PlayerViewSpec.spec s registry
  Parun.PlayerEffectSpec.spec s registry
  Parun.PopulateSpec.spec s registry
  Parun.PowerToughnessSpec.spec s registry
  Parun.PreparationSpec.spec s registry
  Parun.PreventionSpec.spec s registry
  Parun.ProjectionSpec.spec s registry
  Parun.PrototypeSpec.spec s registry
  Parun.PutCounterSpec.spec s registry
  Parun.RadSpec.spec s registry
  Parun.RangeOfInfluenceSpec.spec s registry
  Parun.RecruitSpec.spec s registry
  Parun.RegistrySpec.spec s
  Parun.RemoveCounterSpec.spec s registry
  Parun.ReplacementSpec.spec s registry
  Parun.ReplaySpec.spec s registry
  Parun.ResolveSpec.spec s registry
  Parun.RestampSpec.spec s registry
  Parun.ReversalSpec.spec s registry
  Parun.RingSpec.spec s registry
  Parun.RoomSpec.spec s registry
  Parun.SacrificeRestrictionSpec.spec s registry
  Parun.SaddleSpec.spec s registry
  Parun.SagaSpec.spec s registry
  Parun.ProtocolSpec.spec s registry
  Parun.BotSpec.spec s registry
  Parun.ClientSpec.spec s registry
  Parun.RecordSpec.spec s registry
  Parun.DecksSpec.spec s registry
  Parun.ReplySpec.spec s registry
  Parun.ScenarioSpec.corpusSpec s registry
  Parun.ScenarioSpec.loadSpec s
  Parun.ScenarioSpec.referenceSpec s
  Parun.ScenarioSpec.spec s registry
  Parun.SetupSpec.spec s registry
  Parun.ShieldCounterSpec.spec s registry
  Parun.SlugSpec.spec s
  Parun.SpaceSculptorSpec.spec s registry
  Parun.SpecialActionSpec.spec s registry
  Parun.SpeedSpec.spec s registry
  Parun.SplitSecondSpec.spec s registry
  Parun.StationSpec.spec s registry
  Parun.StickerSpec.spec s registry
  Parun.TargetPerPlayerSpec.spec s registry
  Parun.TargetSpec.spec s registry
  Parun.TeamSpec.spec s registry
  Parun.TransformSpec.spec s registry
  Parun.TriggerSpec.spec s registry
  Parun.TurnSpec.spec s registry
  Parun.UntapRestrictionSpec.spec s registry
  Parun.Uri.FragmentSpec.spec s
  Parun.VanguardSpec.spec s registry
  Parun.VariableEffectSpec.spec s registry
  Parun.VisibilitySpec.spec s registry
  Parun.VoteSpec.spec s registry
  Parun.ZoneChangeSpec.spec s registry
  Parun.ZoneReplacementSpec.spec s registry
  Parun.ZoneTriggerSpec.spec s registry
