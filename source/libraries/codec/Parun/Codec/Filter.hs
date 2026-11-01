module Parun.Codec.Filter where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AbilityKind as AbilityKind
import qualified Parun.Codec.Anchor as Anchor
import qualified Parun.Codec.BlockRole as BlockRole
import qualified Parun.Codec.BlockStatus as BlockStatus
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.ControlMargin as ControlMargin
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.DealtDamageTo as DealtDamageTo
import qualified Parun.Codec.Designation as Designation
import qualified Parun.Codec.EnteredZone as EnteredZone
import qualified Parun.Codec.ExiledPile as ExiledPile
import qualified Parun.Codec.Expansion as Expansion
import qualified Parun.Codec.Holder as Holder
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator
import qualified Parun.Codec.KeywordFamily as KeywordFamily
import qualified Parun.Codec.LoyaltyKind as LoyaltyKind
import qualified Parun.Codec.Measures as Measures
import qualified Parun.Codec.NameChooser as NameChooser
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.ProductionTag as ProductionTag
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.StickerKind as StickerKind
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.Codec.Supertype as Supertype
import qualified Parun.Codec.Trait as Trait
import qualified Parun.Codec.TurnRole as TurnRole
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.ControlMargin as ControlMargin
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Trait as Trait

-- | Recursive, mirroring Quantity's toJson/fromJson: And/Or carry their
-- operands as a JSON Array, Not as a single nested object, and each atom
-- delegates to the leaf-enum codec for the characteristic it cases on.
--
-- The keyword codec is a PARAMETER: Parun.Codec.Keyword imports this module for
-- CR 702.29e's typecycling filter, so a direct reference to Parun.Codec.Keyword
-- here would close a module cycle. Every caller at 'Filter Keyword.Keyword'
-- passes 'Parun.Codec.Keyword.codec' -- which is itself defined partly as
-- 'codec Keyword.codec', tying the knot at the value level; 'Codec.schema'
-- breaks it at the schema level (Parun.JsonSchema.Define.define registers the
-- name before running the body). And/Or/Not recurse on 'codec keywordCodec'
-- itself for the same reason. Parun.Codec.KeywordFamily is called DIRECTLY
-- below and needs no parameter, mirroring the types it encodes: a family
-- carries no filter, so that module imports neither this one nor
-- Parun.Codec.Keyword.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Filter.Filter keyword)
codec keywordCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "HasCardType" CardType.codec Filter.HasCardType (\x -> case x of Filter.HasCardType y -> Just y; _ -> Nothing),
      Arm.payload "HasSupertype" Supertype.codec Filter.HasSupertype (\x -> case x of Filter.HasSupertype y -> Just y; _ -> Nothing),
      Arm.payload "HasColor" Color.codec Filter.HasColor (\x -> case x of Filter.HasColor y -> Just y; _ -> Nothing),
      Arm.payload "HasSubtype" Subtype.codec Filter.HasSubtype (\x -> case x of Filter.HasSubtype y -> Just y; _ -> Nothing),
      Arm.payload "HasName" CardName.codec Filter.HasName (\x -> case x of Filter.HasName y -> Just y; _ -> Nothing),
      Arm.payload "HasNameOriginallyPrintedIn" Expansion.codec Filter.HasNameOriginallyPrintedIn (\x -> case x of Filter.HasNameOriginallyPrintedIn y -> Just y; _ -> Nothing),
      Arm.payload "NameWordsAtLeast" Common.natural Filter.NameWordsAtLeast (\x -> case x of Filter.NameWordsAtLeast y -> Just y; _ -> Nothing),
      Arm.payload "HasKeyword" keywordCodec Filter.HasKeyword (\x -> case x of Filter.HasKeyword y -> Just y; _ -> Nothing),
      Arm.payload "HasKeywordFamily" KeywordFamily.codec Filter.HasKeywordFamily (\x -> case x of Filter.HasKeywordFamily y -> Just y; _ -> Nothing),
      Arm.payload "Measures" Measures.codec Filter.Measures (\x -> case x of Filter.Measures y -> Just y; _ -> Nothing),
      Arm.payload "ControlledByRole" TurnRole.codec Filter.ControlledByRole (\x -> case x of Filter.ControlledByRole y -> Just y; _ -> Nothing),
      Arm.payload "HeldByBound" heldByBound (uncurry Filter.HeldByBound) (\x -> case x of Filter.HeldByBound h y -> Just (h, y); _ -> Nothing),
      -- Runtime-only, and accepted here anyway: the codec must stay total, so a
      -- corpus lint keeps the pool honest instead (#199) -- the treatment
      -- Modification.SetController's baked PlayerId gets.
      Arm.payload "HeldByPlayer" heldByPlayer (uncurry Filter.HeldByPlayer) (\x -> case x of Filter.HeldByPlayer h y -> Just (h, y); _ -> Nothing),
      Arm.payload "HeldByRecipient" Holder.codec Filter.HeldByRecipient (\x -> case x of Filter.HeldByRecipient y -> Just y; _ -> Nothing),
      Arm.payload "Shares" shares (uncurry Filter.Shares) (\x -> case x of Filter.Shares t a -> Just (t, a); _ -> Nothing),
      Arm.nullary "ManaValueIsEven" Filter.ManaValueIsEven,
      Arm.payload "HeldBy" heldBy (uncurry Filter.HeldBy) (\x -> case x of Filter.HeldBy h r -> Just (h, r); _ -> Nothing),
      Arm.payload "IsPlayer" PlayerRelation.codec Filter.IsPlayer (\x -> case x of Filter.IsPlayer y -> Just y; _ -> Nothing),
      Arm.payload "IsControllerOfBound" SlotName.codec Filter.IsControllerOfBound (\x -> case x of Filter.IsControllerOfBound y -> Just y; _ -> Nothing),
      Arm.payload "Controls" (controls keywordCodec) (uncurry Filter.Controls) (\x -> case x of Filter.Controls n y -> Just (n, y); _ -> Nothing),
      -- Natural rather than Common.integer above, so a negative literal is
      -- rejected at decode instead of decoding into a vacuously true filter: a
      -- zone holds no negative number of cards.
      Arm.payload "CardsInGraveyardAtLeast" Common.natural Filter.CardsInGraveyardAtLeast (\x -> case x of Filter.CardsInGraveyardAtLeast y -> Just y; _ -> Nothing),
      Arm.nullary "IsSource" Filter.IsSource,
      Arm.payload "IsObject" ObjectId.codec Filter.IsObject (\x -> case x of Filter.IsObject y -> Just y; _ -> Nothing),
      Arm.nullary "TargetsSource" Filter.TargetsSource,
      Arm.nullary "HasSingleTarget" Filter.HasSingleTarget,
      -- Recursive for Controls' reason: the payload describes the one
      -- TARGET, and a card author writes it exactly as they write any other filter.
      Arm.payload "TargetsOnlyOne" (codec keywordCodec) Filter.TargetsOnlyOne (\x -> case x of Filter.TargetsOnlyOne y -> Just y; _ -> Nothing),
      Arm.payload "TargetsMatching" (codec keywordCodec) Filter.TargetsMatching (\x -> case x of Filter.TargetsMatching y -> Just y; _ -> Nothing),
      Arm.payload "TargetsPlayer" PlayerRelation.codec Filter.TargetsPlayer (\x -> case x of Filter.TargetsPlayer y -> Just y; _ -> Nothing),
      Arm.payload "IsBound" SlotName.codec Filter.IsBound (\x -> case x of Filter.IsBound y -> Just y; _ -> Nothing),
      Arm.nullary "IsTarget" Filter.IsTarget,
      Arm.payload "ControllerRelatesToBound" relatesToBound (uncurry Filter.ControllerRelatesToBound) (\x -> case x of Filter.ControllerRelatesToBound r y -> Just (r, y); _ -> Nothing),
      Arm.payload "SameControllerAsHostOfBound" SlotName.codec Filter.SameControllerAsHostOfBound (\x -> case x of Filter.SameControllerAsHostOfBound y -> Just y; _ -> Nothing),
      Arm.payload "HasChosenName" NameChooser.codec Filter.HasChosenName (\x -> case x of Filter.HasChosenName y -> Just y; _ -> Nothing),
      Arm.nullary "HasChosenColor" Filter.HasChosenColor,
      Arm.nullary "HasChosenSubtype" Filter.HasChosenSubtype,
      Arm.payload "IsExiledWithSource" ExiledPile.codec Filter.IsExiledWithSource (\x -> case x of Filter.IsExiledWithSource y -> Just y; _ -> Nothing),
      Arm.nullary "IsLastExiledWithSource" Filter.IsLastExiledWithSource,
      Arm.nullary "OfChosenPlayer" Filter.OfChosenPlayer,
      Arm.payload "OfRelatedPlayer" PlayerRelation.codec Filter.OfRelatedPlayer (\x -> case x of Filter.OfRelatedPlayer y -> Just y; _ -> Nothing),
      Arm.nullary "IsAttacking" Filter.IsAttacking,
      Arm.payload "IsAttackingPlayer" PlayerRelation.codec Filter.IsAttackingPlayer (\x -> case x of Filter.IsAttackingPlayer y -> Just y; _ -> Nothing),
      Arm.payload "IsAttackingPlaneswalker" PlayerRelation.codec Filter.IsAttackingPlaneswalker (\x -> case x of Filter.IsAttackingPlaneswalker y -> Just y; _ -> Nothing),
      Arm.payload "IsAttackingBattle" PlayerRelation.codec Filter.IsAttackingBattle (\x -> case x of Filter.IsAttackingBattle y -> Just y; _ -> Nothing),
      Arm.nullary "DeclaredAttackedThisCombat" Filter.DeclaredAttackedThisCombat,
      Arm.nullary "IsBlocking" Filter.IsBlocking,
      Arm.payload "HasBlockStatus" BlockStatus.codec Filter.HasBlockStatus (\x -> case x of Filter.HasBlockStatus y -> Just y; _ -> Nothing),
      Arm.payload "DeclaredThisTurn" BlockRole.codec Filter.DeclaredThisTurn (\x -> case x of Filter.DeclaredThisTurn y -> Just y; _ -> Nothing),
      Arm.nullary "CouldAttackThisTurn" Filter.CouldAttackThisTurn,
      Arm.nullary "DeclaredAttackerThisCombat" Filter.DeclaredAttackerThisCombat,
      Arm.nullary "DeclaredBlockerThisCombat" Filter.DeclaredBlockerThisCombat,
      Arm.nullary "MilledThisTurn" Filter.MilledThisTurn,
      Arm.nullary "CrewedSourceThisTurn" Filter.CrewedSourceThisTurn,
      Arm.nullary "ConvokedSourceThisTurn" Filter.ConvokedSourceThisTurn,
      Arm.nullary "SaddledSourceThisTurn" Filter.SaddledSourceThisTurn,
      Arm.nullary "CantCrewVehicles" Filter.CantCrewVehicles,
      Arm.nullary "DealtDamageThisTurn" Filter.DealtDamageThisTurn,
      Arm.payload "DealtDamageTo" DealtDamageTo.codec Filter.DealtDamageTo (\x -> case x of Filter.DealtDamageTo y -> Just y; _ -> Nothing),
      Arm.payload "EnteredThisTurn" EnteredZone.codec Filter.EnteredThisTurn (\x -> case x of Filter.EnteredThisTurn y -> Just y; _ -> Nothing),
      Arm.nullary "ControlledSinceTurnBegan" Filter.ControlledSinceTurnBegan,
      -- Recursive for Controls' reason: the payload describes the
      -- HOST, and a card author writes it exactly as they write any other filter.
      Arm.payload "AttachedTo" (codec keywordCodec) Filter.AttachedTo (\x -> case x of Filter.AttachedTo y -> Just y; _ -> Nothing),
      -- Recursive for the arm above's reason, the payload describing the ATTACHER
      -- rather than the host.
      Arm.payload "HasAttached" (codec keywordCodec) Filter.HasAttached (\x -> case x of Filter.HasAttached y -> Just y; _ -> Nothing),
      Arm.payload "IsAttachedTo" Anchor.codec Filter.IsAttachedTo (\x -> case x of Filter.IsAttachedTo y -> Just y; _ -> Nothing),
      Arm.nullary "IsEvaluated" Filter.IsEvaluated,
      Arm.nullary "IsHostOfSource" Filter.IsHostOfSource,
      Arm.nullary "EnteredWithSource" Filter.EnteredWithSource,
      Arm.nullary "AttachedNoLaterThanSource" Filter.AttachedNoLaterThanSource,
      Arm.nullary "CanHostSubject" Filter.CanHostSubject,
      Arm.nullary "CanAttachToSubject" Filter.CanAttachToSubject,
      Arm.payload "HostOfSubjectHasCardType" CardType.codec Filter.HostOfSubjectHasCardType (\x -> case x of Filter.HostOfSubjectHasCardType y -> Just y; _ -> Nothing),
      Arm.nullary "IsCommander" Filter.IsCommander,
      Arm.nullary "IsToken" Filter.IsToken,
      Arm.optionalPayload "IsActivatedAbility" LoyaltyKind.codec Filter.IsActivatedAbility (\x -> case x of Filter.IsActivatedAbility y -> Just y; _ -> Nothing),
      Arm.nullary "IsAbility" Filter.IsAbility,
      Arm.nullary "IsEmblem" Filter.IsEmblem,
      -- Recursive for AttachedTo's reason, the payload describing the ability's
      -- SOURCE rather than the ability.
      Arm.payload "FromSource" (codec keywordCodec) Filter.FromSource (\x -> case x of Filter.FromSource y -> Just y; _ -> Nothing),
      Arm.nullary "IsTapped" Filter.IsTapped,
      Arm.nullary "IsFaceDown" Filter.IsFaceDown,
      -- Recursive for AttachedTo's reason, the payload describing the CARD
      -- representing the candidate rather than the candidate.
      Arm.payload "RepresentedByCard" (codec keywordCodec) Filter.RepresentedByCard (\x -> case x of Filter.RepresentedByCard y -> Just y; _ -> Nothing),
      Arm.nullary "IsExiledFaceDown" Filter.IsExiledFaceDown,
      Arm.nullary "Transformed" Filter.Transformed,
      Arm.nullary "IsRingBearer" Filter.IsRingBearer,
      Arm.nullary "IsPaired" Filter.IsPaired,
      Arm.nullary "IsPairedWithSource" Filter.IsPairedWithSource,
      Arm.payload "BlockPartnerOfSource" BlockRole.codec Filter.BlockPartnerOfSource (\x -> case x of Filter.BlockPartnerOfSource y -> Just y; _ -> Nothing),
      Arm.payload "HasDesignation" Designation.codec Filter.HasDesignation (\x -> case x of Filter.HasDesignation y -> Just y; _ -> Nothing),
      Arm.payload "HasCounters" (CounterKind.codec keywordCodec) Filter.HasCounters (\x -> case x of Filter.HasCounters y -> Just y; _ -> Nothing),
      Arm.nullary "HasCountersOfAnyKind" Filter.HasCountersOfAnyKind,
      Arm.payload "HasSticker" StickerKind.codec Filter.HasSticker (\x -> case x of Filter.HasSticker y -> Just y; _ -> Nothing),
      Arm.nullary "Stickered" Filter.Stickered,
      Arm.optionalPayload "HasActivatedAbility" AbilityKind.codec Filter.HasActivatedAbility (\x -> case x of Filter.HasActivatedAbility y -> Just y; _ -> Nothing),
      Arm.payload "IsInZone" Zone.codec Filter.IsInZone (\x -> case x of Filter.IsInZone y -> Just y; _ -> Nothing),
      Arm.payload "WasCastFrom" Zone.codec Filter.WasCastFrom (\x -> case x of Filter.WasCastFrom y -> Just y; _ -> Nothing),
      Arm.payload "TagWasSpent" ProductionTag.codec Filter.TagWasSpent (\x -> case x of Filter.TagWasSpent y -> Just y; _ -> Nothing),
      Arm.payload "Paid" (KeywordDesignator.codec keywordCodec) Filter.Paid (\x -> case x of Filter.Paid y -> Just y; _ -> Nothing),
      Arm.nullary "IsPrototyped" Filter.IsPrototyped,
      Arm.payload "And" (Common.list (codec keywordCodec)) Filter.And (\x -> case x of Filter.And y -> Just y; _ -> Nothing),
      Arm.payload "Or" (Common.list (codec keywordCodec)) Filter.Or (\x -> case x of Filter.Or y -> Just y; _ -> Nothing),
      Arm.payload "Not" (codec keywordCodec) Filter.Not (\x -> case x of Filter.Not y -> Just y; _ -> Nothing),
      Arm.payload "Unwritten" (codec keywordCodec) Filter.Unwritten (\x -> case x of Filter.Unwritten y -> Just y; _ -> Nothing)
    ]

-- | CR 110.2's comparison keyed by name: the margin, and the filter
-- describing the permanents being counted -- recursive like Not, and for the
-- atom's own reason rather than the combinator's.
controls :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ControlMargin.ControlMargin, Filter.Filter keyword)
controls keywordCodec =
  Fields.object $
    (,)
      <$> Fields.required "margin" ControlMargin.codec fst
      <*> Fields.required "filter" (codec keywordCodec) snd

-- | Which of the candidate's players, and how it relates to the perspective.
heldBy :: Codec.Codec (Holder.Holder, PlayerRelation.PlayerRelation)
heldBy =
  Fields.object $
    (,)
      <$> Fields.required "holder" Holder.codec fst
      <*> Fields.required "relation" PlayerRelation.codec snd

-- | CR 603.2's bound holder keyed by name: which of the candidate's players,
-- and the slot binding the player it must be.
heldByBound :: Codec.Codec (Holder.Holder, SlotName.SlotName)
heldByBound =
  Fields.object $
    (,)
      <$> Fields.required "holder" Holder.codec fst
      <*> Fields.required "slot" SlotName.codec snd

-- | The bound holder baked: which of the candidate's players, and the player it
-- must be.
heldByPlayer :: Codec.Codec (Holder.Holder, PlayerId.PlayerId)
heldByPlayer =
  Fields.object $
    (,)
      <$> Fields.required "holder" Holder.codec fst
      <*> Fields.required "player" PlayerId.codec snd

-- | CR 110.2's comparison across two objects keyed by name: the relation, and
-- the slot holding the object whose controller it is relative to.
-- | What is shared, and with which object.
shares :: Codec.Codec (Trait.Trait, Anchor.Anchor)
shares =
  Fields.object $
    (,)
      <$> Fields.required "trait" Trait.codec fst
      <*> Fields.required "anchor" Anchor.codec snd

relatesToBound :: Codec.Codec (PlayerRelation.PlayerRelation, SlotName.SlotName)
relatesToBound =
  Fields.object $
    (,)
      <$> Fields.required "relation" PlayerRelation.codec fst
      <*> Fields.required "slot" SlotName.codec snd

tagOf :: Filter.Filter keyword -> String
tagOf x = case x of
  Filter.HasCardType {} -> "HasCardType"
  Filter.HasSupertype {} -> "HasSupertype"
  Filter.HasColor {} -> "HasColor"
  Filter.HasSubtype {} -> "HasSubtype"
  Filter.HasName {} -> "HasName"
  Filter.HasNameOriginallyPrintedIn {} -> "HasNameOriginallyPrintedIn"
  Filter.NameWordsAtLeast {} -> "NameWordsAtLeast"
  Filter.HasKeyword {} -> "HasKeyword"
  Filter.HasKeywordFamily {} -> "HasKeywordFamily"
  Filter.Measures {} -> "Measures"
  Filter.ControlledByRole {} -> "ControlledByRole"
  Filter.HeldByBound {} -> "HeldByBound"
  Filter.HeldByPlayer {} -> "HeldByPlayer"
  Filter.HeldByRecipient {} -> "HeldByRecipient"
  Filter.Shares {} -> "Shares"
  Filter.ManaValueIsEven {} -> "ManaValueIsEven"
  Filter.HeldBy {} -> "HeldBy"
  Filter.IsPlayer {} -> "IsPlayer"
  Filter.IsControllerOfBound {} -> "IsControllerOfBound"
  Filter.Controls {} -> "Controls"
  Filter.CardsInGraveyardAtLeast {} -> "CardsInGraveyardAtLeast"
  Filter.IsSource {} -> "IsSource"
  Filter.IsObject {} -> "IsObject"
  Filter.TargetsSource {} -> "TargetsSource"
  Filter.HasSingleTarget {} -> "HasSingleTarget"
  Filter.TargetsOnlyOne {} -> "TargetsOnlyOne"
  Filter.TargetsMatching {} -> "TargetsMatching"
  Filter.TargetsPlayer {} -> "TargetsPlayer"
  Filter.IsBound {} -> "IsBound"
  Filter.IsTarget {} -> "IsTarget"
  Filter.ControllerRelatesToBound {} -> "ControllerRelatesToBound"
  Filter.SameControllerAsHostOfBound {} -> "SameControllerAsHostOfBound"
  Filter.HasChosenName {} -> "HasChosenName"
  Filter.HasChosenColor {} -> "HasChosenColor"
  Filter.HasChosenSubtype {} -> "HasChosenSubtype"
  Filter.IsExiledWithSource {} -> "IsExiledWithSource"
  Filter.IsLastExiledWithSource -> "IsLastExiledWithSource"
  Filter.OfChosenPlayer {} -> "OfChosenPlayer"
  Filter.OfRelatedPlayer {} -> "OfRelatedPlayer"
  Filter.IsAttacking {} -> "IsAttacking"
  Filter.IsAttackingPlayer {} -> "IsAttackingPlayer"
  Filter.IsAttackingPlaneswalker {} -> "IsAttackingPlaneswalker"
  Filter.IsAttackingBattle {} -> "IsAttackingBattle"
  Filter.DeclaredAttackedThisCombat {} -> "DeclaredAttackedThisCombat"
  Filter.IsBlocking {} -> "IsBlocking"
  Filter.HasBlockStatus {} -> "HasBlockStatus"
  Filter.DeclaredThisTurn {} -> "DeclaredThisTurn"
  Filter.CouldAttackThisTurn {} -> "CouldAttackThisTurn"
  Filter.DeclaredAttackerThisCombat {} -> "DeclaredAttackerThisCombat"
  Filter.DeclaredBlockerThisCombat {} -> "DeclaredBlockerThisCombat"
  Filter.MilledThisTurn {} -> "MilledThisTurn"
  Filter.CrewedSourceThisTurn {} -> "CrewedSourceThisTurn"
  Filter.ConvokedSourceThisTurn {} -> "ConvokedSourceThisTurn"
  Filter.SaddledSourceThisTurn {} -> "SaddledSourceThisTurn"
  Filter.CantCrewVehicles {} -> "CantCrewVehicles"
  Filter.DealtDamageThisTurn {} -> "DealtDamageThisTurn"
  Filter.DealtDamageTo {} -> "DealtDamageTo"
  Filter.EnteredThisTurn {} -> "EnteredThisTurn"
  Filter.ControlledSinceTurnBegan {} -> "ControlledSinceTurnBegan"
  Filter.AttachedTo {} -> "AttachedTo"
  Filter.HasAttached {} -> "HasAttached"
  Filter.IsAttachedTo {} -> "IsAttachedTo"
  Filter.IsEvaluated {} -> "IsEvaluated"
  Filter.IsHostOfSource {} -> "IsHostOfSource"
  Filter.EnteredWithSource {} -> "EnteredWithSource"
  Filter.AttachedNoLaterThanSource {} -> "AttachedNoLaterThanSource"
  Filter.CanHostSubject {} -> "CanHostSubject"
  Filter.CanAttachToSubject {} -> "CanAttachToSubject"
  Filter.HostOfSubjectHasCardType {} -> "HostOfSubjectHasCardType"
  Filter.IsCommander {} -> "IsCommander"
  Filter.IsToken {} -> "IsToken"
  Filter.IsActivatedAbility {} -> "IsActivatedAbility"
  Filter.IsAbility {} -> "IsAbility"
  Filter.IsEmblem {} -> "IsEmblem"
  Filter.FromSource {} -> "FromSource"
  Filter.IsTapped {} -> "IsTapped"
  Filter.IsFaceDown {} -> "IsFaceDown"
  Filter.RepresentedByCard {} -> "RepresentedByCard"
  Filter.IsExiledFaceDown {} -> "IsExiledFaceDown"
  Filter.Transformed {} -> "Transformed"
  Filter.IsRingBearer {} -> "IsRingBearer"
  Filter.IsPaired {} -> "IsPaired"
  Filter.IsPairedWithSource {} -> "IsPairedWithSource"
  Filter.BlockPartnerOfSource {} -> "BlockPartnerOfSource"
  Filter.HasDesignation {} -> "HasDesignation"
  Filter.HasCounters {} -> "HasCounters"
  Filter.HasCountersOfAnyKind {} -> "HasCountersOfAnyKind"
  Filter.HasSticker {} -> "HasSticker"
  Filter.Stickered {} -> "Stickered"
  Filter.HasActivatedAbility {} -> "HasActivatedAbility"
  Filter.IsInZone {} -> "IsInZone"
  Filter.WasCastFrom {} -> "WasCastFrom"
  Filter.TagWasSpent {} -> "TagWasSpent"
  Filter.Paid {} -> "Paid"
  Filter.IsPrototyped {} -> "IsPrototyped"
  Filter.And {} -> "And"
  Filter.Or {} -> "Or"
  Filter.Not {} -> "Not"
  Filter.Unwritten {} -> "Unwritten"
