module Parun.Codec.FilterSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.Anchor as Anchor
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlockStatus as BlockStatus
import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.ControlMargin as ControlMargin
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.DamagedParty as DamagedParty
import qualified Parun.Types.DealtDamageTo as DealtDamageTo
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.EnteredZone as EnteredZone
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Expansion as Expansion
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.Lookback as Lookback
import qualified Parun.Types.LoyaltyKind as LoyaltyKind
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.NameChooser as NameChooser
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.ProductionTag as ProductionTag
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StickerKind as StickerKind
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.Trait as Trait
import qualified Parun.Types.TurnRole as TurnRole
import qualified Parun.Types.Zone as Zone

-- | The `keyword` parameter is instantiated at 'Keyword.Keyword', the only
-- concrete instantiation anywhere in the pool, so HasKeyword's case pins a real
-- keyword's wire shape rather than a stand-in's.
codec :: Codec.Codec (Filter.Filter Keyword.Keyword)
codec = Filter.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Filter" $ do
  Spec.it s "HasCardType" $
    Common.assertCodec
      s
      codec
      (Filter.HasCardType CardType.Creature)
      " {\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}} "
  Spec.it s "HasSupertype" $
    Common.assertCodec
      s
      codec
      (Filter.HasSupertype Supertype.Basic)
      " {\"type\":\"HasSupertype\",\"value\":{\"type\":\"Basic\"}} "
  Spec.it s "HasColor" $
    Common.assertCodec
      s
      codec
      (Filter.HasColor Color.Black)
      " {\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}} "
  Spec.it s "HasSubtype" $
    Common.assertCodec
      s
      codec
      (Filter.HasSubtype Subtype.Mountain)
      " {\"type\":\"HasSubtype\",\"value\":{\"type\":\"Mountain\"}} "
  Spec.it s "HasName" $
    Common.assertCodec
      s
      codec
      (Filter.HasName (CardName.MkCardName (Text.pack "The Underworld Cookbook")))
      " {\"type\":\"HasName\",\"value\":\"The Underworld Cookbook\"} "
  Spec.it s "NameWordsAtLeast" $ Common.assertCodec s codec (Filter.NameWordsAtLeast 3) " {\"type\":\"NameWordsAtLeast\",\"value\":3} "
  Spec.it s "HasNameOriginallyPrintedIn" $
    Common.assertCodec
      s
      codec
      (Filter.HasNameOriginallyPrintedIn (Expansion.UnsafeMkExpansion (Text.pack "ARN")))
      " {\"type\":\"HasNameOriginallyPrintedIn\",\"value\":\"ARN\"} "
  Spec.it s "HasKeyword" $
    Common.assertCodec
      s
      codec
      (Filter.HasKeyword Keyword.Flying)
      " {\"type\":\"HasKeyword\",\"value\":{\"type\":\"Flying\"}} "
  Spec.it s "HasKeywordFamily" $ do
    Common.assertCodec
      s
      codec
      (Filter.HasKeywordFamily KeywordFamily.Toxic)
      " {\"type\":\"HasKeywordFamily\",\"value\":{\"type\":\"Toxic\"}} "
    -- The two atoms must not share a wire shape: a card asking for the family
    -- and one asking for toxic 2 have to round-trip back to different filters.
    Spec.assertBool
      s
      (Codec.encode codec (Filter.HasKeywordFamily KeywordFamily.Toxic) /= Codec.encode codec (Filter.HasKeyword (Keyword.Toxic 2)))
      "the toxic family filter is not the toxic 2 filter"
  Spec.it s "Shares Sector Source" $
    Common.assertCodec
      s
      codec
      (Filter.Shares Trait.Sector Anchor.Source)
      " {\"type\":\"Shares\",\"value\":{\"trait\":{\"type\":\"Sector\"},\"anchor\":{\"type\":\"Source\"}}} "
  Spec.it s "ControlledByRole Defending" $
    Common.assertCodec
      s
      codec
      (Filter.ControlledByRole TurnRole.Defending)
      " {\"type\":\"ControlledByRole\",\"value\":{\"type\":\"Defending\"}} "
  Spec.it s "ControlledByRole Active" $
    Common.assertCodec
      s
      codec
      (Filter.ControlledByRole TurnRole.Active)
      " {\"type\":\"ControlledByRole\",\"value\":{\"type\":\"Active\"}} "
  Spec.it s "HeldByBound" $
    Common.assertCodec
      s
      codec
      (Filter.HeldByBound Holder.Controller (SlotName.MkSlotName (Text.pack "thatPlayer")))
      " {\"type\":\"HeldByBound\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"slot\":\"thatPlayer\"}} "
  -- Runtime-only (Parun.CardSpec lints it out of the pool), but round-tripped
  -- here for the reason its codec arm exists at all: the codec is total.
  Spec.it s "HeldByPlayer" $
    Common.assertCodec
      s
      codec
      (Filter.HeldByPlayer Holder.Owner (PlayerId.MkPlayerId 1))
      " {\"type\":\"HeldByPlayer\",\"value\":{\"holder\":{\"type\":\"Owner\"},\"player\":1}} "
  -- Runtime-only for HeldByPlayer's reason, and round-tripped here for
  -- its reason.
  Spec.it s "IsObject" $
    Common.assertCodec
      s
      codec
      (Filter.IsObject (ObjectId.MkObjectId 7))
      " {\"type\":\"IsObject\",\"value\":7} "
  Spec.it s "HeldByRecipient" $
    Common.assertCodec
      s
      codec
      (Filter.HeldByRecipient Holder.Controller)
      " {\"type\":\"HeldByRecipient\",\"value\":{\"type\":\"Controller\"}} "
  Spec.it s "ControllerIsOwner" $
    Common.assertCodec
      s
      codec
      Filter.ControllerIsOwner
      " {\"type\":\"ControllerIsOwner\"} "
  Spec.it s "ManaValueIsEven" $
    Common.assertCodec
      s
      codec
      Filter.ManaValueIsEven
      " {\"type\":\"ManaValueIsEven\"} "
  Spec.it s "HeldBy" $
    Common.assertCodec
      s
      codec
      (Filter.HeldBy Holder.Owner PlayerRelation.Opponent)
      " {\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Owner\"},\"relation\":{\"type\":\"Opponent\"}}} "
  Spec.it s "IsPlayer" $
    Common.assertCodec
      s
      codec
      (Filter.IsPlayer PlayerRelation.Opponent)
      " {\"type\":\"IsPlayer\",\"value\":{\"type\":\"Opponent\"}} "
  Spec.it s "IsControllerOfBound" $
    Common.assertCodec
      s
      codec
      (Filter.IsControllerOfBound (SlotName.MkSlotName (Text.pack "permanent")))
      " {\"type\":\"IsControllerOfBound\",\"value\":\"permanent\"} "
  -- Nested, unlike every atom above: the payload carries a whole Filter beside
  -- the margin, so this pins the recursion and both keys as well as the tag.
  Spec.it s "Controls" $
    Common.assertCodec
      s
      codec
      (Filter.Controls (ControlMargin.MoreThanYou 2) (Filter.HasCardType CardType.Land))
      " {\"type\":\"Controls\",\"value\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"margin\":{\"type\":\"MoreThanYou\",\"value\":2}}} "
  Spec.it s "CardsInGraveyardAtLeast" $
    Common.assertCodec
      s
      codec
      (Filter.CardsInGraveyardAtLeast 7)
      " {\"type\":\"CardsInGraveyardAtLeast\",\"value\":7} "
  Spec.it s "IsSource" $
    Common.assertCodec
      s
      codec
      Filter.IsSource
      " {\"type\":\"IsSource\"} "
  Spec.it s "TargetsSource" $
    Common.assertCodec
      s
      codec
      Filter.TargetsSource
      " {\"type\":\"TargetsSource\"} "
  Spec.it s "HasSingleTarget" $
    Common.assertCodec
      s
      codec
      Filter.HasSingleTarget
      " {\"type\":\"HasSingleTarget\"} "
  Spec.it s "TargetsOnlyOne" $
    Common.assertCodec
      s
      codec
      (Filter.TargetsOnlyOne (Filter.HasCardType CardType.Creature))
      " {\"type\":\"TargetsOnlyOne\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "TargetsMatching" $
    Common.assertCodec
      s
      codec
      (Filter.TargetsMatching (Filter.HeldBy Holder.Controller PlayerRelation.You))
      " {\"type\":\"TargetsMatching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}} "
  Spec.it s "TargetsPlayer You" $
    Common.assertCodec
      s
      codec
      (Filter.TargetsPlayer PlayerRelation.You)
      " {\"type\":\"TargetsPlayer\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "IsBound" $
    Common.assertCodec
      s
      codec
      (Filter.IsBound (SlotName.MkSlotName (Text.pack "looked")))
      " {\"type\":\"IsBound\",\"value\":\"looked\"} "
  Spec.it s "IsTarget" $
    Common.assertCodec
      s
      codec
      Filter.IsTarget
      " {\"type\":\"IsTarget\"} "
  Spec.it s "Shares Name Bound" $
    Common.assertCodec
      s
      codec
      (Filter.Shares Trait.Name (Anchor.Bound (SlotName.MkSlotName (Text.pack "castSpell"))))
      " {\"type\":\"Shares\",\"value\":{\"trait\":{\"type\":\"Name\"},\"anchor\":{\"type\":\"Bound\",\"value\":\"castSpell\"}}} "
  Spec.it s "ControllerRelatesToBound" $
    Common.assertCodec
      s
      codec
      (Filter.ControllerRelatesToBound PlayerRelation.You (SlotName.MkSlotName (Text.pack "from")))
      " {\"type\":\"ControllerRelatesToBound\",\"value\":{\"relation\":{\"type\":\"You\"},\"slot\":\"from\"}} "
  Spec.it s "SameControllerAsHostOfBound" $ do
    Common.assertCodec
      s
      codec
      (Filter.SameControllerAsHostOfBound (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"SameControllerAsHostOfBound\",\"value\":\"target\"} "
    Spec.assertNeWith s "CR 303.4b's host is not the bound object itself" (Codec.encode codec (Filter.SameControllerAsHostOfBound (SlotName.MkSlotName (Text.pack "target")))) (Codec.encode codec (Filter.ControllerRelatesToBound PlayerRelation.You (SlotName.MkSlotName (Text.pack "target"))))
  Spec.it s "Shares CreatureType Bound" $
    Common.assertCodec
      s
      codec
      (Filter.Shares Trait.CreatureType (Anchor.Bound (SlotName.MkSlotName (Text.pack "thatDepartedPermanent"))))
      " {\"type\":\"Shares\",\"value\":{\"trait\":{\"type\":\"CreatureType\"},\"anchor\":{\"type\":\"Bound\",\"value\":\"thatDepartedPermanent\"}}} "
  Spec.it s "Measures" $
    Common.assertCodec
      s
      codec
      (Filter.Measures (Measures.MkMeasures Measure.Toughness Comparison.LessThan (Operand.OfBound (BoundMeasure.MkBoundMeasure (SlotName.MkSlotName (Text.pack "thatExploitedCreature")) Measure.Toughness))))
      " {\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Toughness\"},\"comparison\":{\"type\":\"LessThan\"},\"operand\":{\"type\":\"OfBound\",\"value\":{\"slot\":\"thatExploitedCreature\",\"measure\":{\"type\":\"Toughness\"}}}}} "
  Spec.it s "HasChosenName" $
    Common.assertCodec
      s
      codec
      (Filter.HasChosenName NameChooser.CandidateOwner)
      " {\"type\":\"HasChosenName\",\"value\":{\"type\":\"CandidateOwner\"}} "
  Spec.it s "HasChosenColor" $
    Common.assertCodec
      s
      codec
      Filter.HasChosenColor
      " {\"type\":\"HasChosenColor\"} "
  Spec.it s "HasChosenSubtype" $
    Common.assertCodec
      s
      codec
      Filter.HasChosenSubtype
      " {\"type\":\"HasChosenSubtype\"} "
  Spec.it s "IsExiledWithSource" $
    Common.assertCodec
      s
      codec
      (Filter.IsExiledWithSource ExiledPile.AsItEntered)
      " {\"type\":\"IsExiledWithSource\",\"value\":{\"type\":\"AsItEntered\"}} "
  Spec.it s "IsLastExiledWithSource" $
    Common.assertCodec
      s
      codec
      Filter.IsLastExiledWithSource
      " {\"type\":\"IsLastExiledWithSource\"} "
  Spec.it s "OfChosenPlayer" $
    Common.assertCodec
      s
      codec
      Filter.OfChosenPlayer
      " {\"type\":\"OfChosenPlayer\"} "
  Spec.it s "OfRelatedPlayer" $
    Common.assertCodec
      s
      codec
      (Filter.OfRelatedPlayer PlayerRelation.Opponent)
      " {\"type\":\"OfRelatedPlayer\",\"value\":{\"type\":\"Opponent\"}} "
  Spec.it s "IsAttacking" $
    Common.assertCodec
      s
      codec
      Filter.IsAttacking
      " {\"type\":\"IsAttacking\"} "
  Spec.it s "IsAttackingPlayer" $
    Common.assertCodec
      s
      codec
      (Filter.IsAttackingPlayer PlayerRelation.You)
      " {\"type\":\"IsAttackingPlayer\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "IsAttackingPlaneswalker" $
    Common.assertCodec
      s
      codec
      (Filter.IsAttackingPlaneswalker PlayerRelation.You)
      " {\"type\":\"IsAttackingPlaneswalker\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "IsAttackingBattle" $
    Common.assertCodec
      s
      codec
      (Filter.IsAttackingBattle PlayerRelation.You)
      " {\"type\":\"IsAttackingBattle\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "IsBlocking" $
    Common.assertCodec
      s
      codec
      Filter.IsBlocking
      " {\"type\":\"IsBlocking\"} "
  Spec.it s "HasBlockStatus" $
    Common.assertCodec
      s
      codec
      (Filter.HasBlockStatus BlockStatus.Unblocked)
      " {\"type\":\"HasBlockStatus\",\"value\":{\"type\":\"Unblocked\"}} "
  Spec.it s "DeclaredThisTurn" $
    Common.assertCodec
      s
      codec
      (Filter.DeclaredThisTurn BlockRole.Blocker)
      " {\"type\":\"DeclaredThisTurn\",\"value\":{\"type\":\"Blocker\"}} "
  Spec.it s "CouldAttackThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.CouldAttackThisTurn
      " {\"type\":\"CouldAttackThisTurn\"} "
  Spec.it s "CrewedSourceThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.CrewedSourceThisTurn
      " {\"type\":\"CrewedSourceThisTurn\"} "
  Spec.it s "ConvokedSourceThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.ConvokedSourceThisTurn
      " {\"type\":\"ConvokedSourceThisTurn\"} "
  Spec.it s "SaddledSourceThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.SaddledSourceThisTurn
      " {\"type\":\"SaddledSourceThisTurn\"} "
  Spec.it s "DeclaredAttackerThisCombat" $
    Common.assertCodec
      s
      codec
      Filter.DeclaredAttackerThisCombat
      " {\"type\":\"DeclaredAttackerThisCombat\"} "
  Spec.it s "DeclaredAttackedThisCombat" $
    Common.assertCodec
      s
      codec
      Filter.DeclaredAttackedThisCombat
      " {\"type\":\"DeclaredAttackedThisCombat\"} "
  Spec.it s "DeclaredBlockerThisCombat" $
    Common.assertCodec
      s
      codec
      Filter.DeclaredBlockerThisCombat
      " {\"type\":\"DeclaredBlockerThisCombat\"} "
  Spec.it s "MilledThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.MilledThisTurn
      " {\"type\":\"MilledThisTurn\"} "
  Spec.it s "CantCrewVehicles" $
    Common.assertCodec
      s
      codec
      Filter.CantCrewVehicles
      " {\"type\":\"CantCrewVehicles\"} "
  Spec.it s "DealtDamageThisTurn" $
    Common.assertCodec
      s
      codec
      Filter.DealtDamageThisTurn
      " {\"type\":\"DealtDamageThisTurn\"} "
  Spec.it s "DealtDamageTo" $
    Common.assertCodec
      s
      codec
      (Filter.DealtDamageTo DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.Source, DealtDamageTo.kind = Nothing, DealtDamageTo.window = Lookback.ThisTurn})
      " {\"type\":\"DealtDamageTo\",\"value\":{\"party\":{\"type\":\"Source\"}}} "
  Spec.it s "EnteredThisTurn" $
    Common.assertCodec
      s
      codec
      (Filter.EnteredThisTurn EnteredZone.MkEnteredZone {EnteredZone.to = Zone.Graveyard, EnteredZone.from = Set.singleton Zone.Battlefield})
      " {\"type\":\"EnteredThisTurn\",\"value\":{\"from\":[{\"type\":\"Battlefield\"}],\"to\":{\"type\":\"Graveyard\"}}} "
  Spec.it s "ControlledSinceTurnBegan" $
    Common.assertCodec
      s
      codec
      Filter.ControlledSinceTurnBegan
      " {\"type\":\"ControlledSinceTurnBegan\"} "
  Spec.it s "AttachedTo" $
    Common.assertCodec
      s
      codec
      (Filter.AttachedTo (Filter.HasCardType CardType.Creature))
      " {\"type\":\"AttachedTo\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Aura Graft's "attached to a permanent", which the general atom spells as the
  -- trivial nest -- and the shape that would break a codec whose payload were
  -- optional rather than required.
  Spec.it s "AttachedTo with the trivial nest" $
    Common.assertCodec
      s
      codec
      (Filter.AttachedTo (Filter.And []))
      " {\"type\":\"AttachedTo\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  Spec.it s "HasAttached" $
    Common.assertCodec
      s
      codec
      (Filter.HasAttached (Filter.HasSubtype Subtype.Aura))
      " {\"type\":\"HasAttached\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Aura\"}}} "
  -- CR 303.4b's atom is not CR 701.3a's, and the two tags are what says so: a
  -- codec that spelled both "AttachedTo" would read an enchanted creature as an
  -- Aura.
  Spec.it s "HasAttached with the trivial nest" $
    Common.assertCodec
      s
      codec
      (Filter.HasAttached (Filter.And []))
      " {\"type\":\"HasAttached\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  Spec.it s "IsAttachedTo Source" $
    Common.assertCodec
      s
      codec
      (Filter.IsAttachedTo Anchor.Source)
      " {\"type\":\"IsAttachedTo\",\"value\":{\"type\":\"Source\"}} "
  Spec.it s "IsAttachedTo Evaluated" $
    Common.assertCodec
      s
      codec
      (Filter.IsAttachedTo Anchor.Evaluated)
      " {\"type\":\"IsAttachedTo\",\"value\":{\"type\":\"Evaluated\"}} "
  Spec.it s "IsEvaluated" $
    Common.assertCodec
      s
      codec
      Filter.IsEvaluated
      " {\"type\":\"IsEvaluated\"} "
  Spec.it s "Shares CreatureType Evaluated" $
    Common.assertCodec
      s
      codec
      (Filter.Shares Trait.CreatureType Anchor.Evaluated)
      " {\"type\":\"Shares\",\"value\":{\"trait\":{\"type\":\"CreatureType\"},\"anchor\":{\"type\":\"Evaluated\"}}} "
  Spec.it s "EnteredWithSource" $
    Common.assertCodec
      s
      codec
      Filter.EnteredWithSource
      " {\"type\":\"EnteredWithSource\"} "
  Spec.it s "AttachedNoLaterThanSource" $
    Common.assertCodec
      s
      codec
      Filter.AttachedNoLaterThanSource
      " {\"type\":\"AttachedNoLaterThanSource\"} "
  Spec.it s "IsHostOfSource" $
    Common.assertCodec
      s
      codec
      Filter.IsHostOfSource
      " {\"type\":\"IsHostOfSource\"} "
  Spec.it s "CanHostSubject" $
    Common.assertCodec
      s
      codec
      Filter.CanHostSubject
      " {\"type\":\"CanHostSubject\"} "
  Spec.it s "CanAttachToSubject" $
    Common.assertCodec
      s
      codec
      Filter.CanAttachToSubject
      " {\"type\":\"CanAttachToSubject\"} "
  Spec.it s "HostOfSubjectHasCardType" $ do
    Common.assertCodec
      s
      codec
      (Filter.HostOfSubjectHasCardType CardType.Creature)
      " {\"type\":\"HostOfSubjectHasCardType\",\"value\":{\"type\":\"Creature\"}} "
    Spec.assertNeWith s "CR 205.2a's read is of the host, not of the candidate" (Codec.encode codec (Filter.HostOfSubjectHasCardType CardType.Creature)) (Codec.encode codec (Filter.HasCardType CardType.Creature))
  Spec.it s "IsCommander" $
    Common.assertCodec
      s
      codec
      Filter.IsCommander
      " {\"type\":\"IsCommander\"} "
  Spec.it s "IsToken" $
    Common.assertCodec
      s
      codec
      Filter.IsToken
      " {\"type\":\"IsToken\"} "
  Spec.it s "IsActivatedAbility" $
    Common.assertCodec
      s
      codec
      (Filter.IsActivatedAbility Nothing)
      " {\"type\":\"IsActivatedAbility\"} "
  Spec.it s "IsActivatedAbility with a loyalty kind" $
    Common.assertCodec
      s
      codec
      (Filter.IsActivatedAbility (Just LoyaltyKind.LoyaltyAbility))
      " {\"type\":\"IsActivatedAbility\",\"value\":{\"type\":\"LoyaltyAbility\"}} "
  Spec.it s "IsAbility" $
    Common.assertCodec
      s
      codec
      Filter.IsAbility
      " {\"type\":\"IsAbility\"} "
  Spec.it s "IsEmblem" $
    Common.assertCodec
      s
      codec
      Filter.IsEmblem
      " {\"type\":\"IsEmblem\"} "
  Spec.it s "FromSource" $
    Common.assertCodec
      s
      codec
      (Filter.FromSource (Filter.HasCardType CardType.Artifact))
      " {\"type\":\"FromSource\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}} "
  Spec.it s "IsTapped" $
    Common.assertCodec
      s
      codec
      Filter.IsTapped
      " {\"type\":\"IsTapped\"} "
  Spec.it s "IsFaceDown" $
    Common.assertCodec
      s
      codec
      Filter.IsFaceDown
      " {\"type\":\"IsFaceDown\"} "
  Spec.it s "RepresentedByCard" $
    Common.assertCodec
      s
      codec
      (Filter.RepresentedByCard (Filter.HasCardType CardType.Creature))
      " {\"type\":\"RepresentedByCard\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "IsExiledFaceDown" $
    Common.assertCodec
      s
      codec
      Filter.IsExiledFaceDown
      " {\"type\":\"IsExiledFaceDown\"} "
  Spec.it s "Transformed" $
    Common.assertCodec
      s
      codec
      Filter.Transformed
      " {\"type\":\"Transformed\"} "
  Spec.it s "IsRingBearer" $
    Common.assertCodec
      s
      codec
      Filter.IsRingBearer
      " {\"type\":\"IsRingBearer\"} "
  Spec.it s "IsPaired" $
    Common.assertCodec
      s
      codec
      Filter.IsPaired
      " {\"type\":\"IsPaired\"} "
  -- CR 702.95b's two questions differ by the tag alone, both being nullary, so
  -- the pair is asserted together: a codec that confused them would read Wolfir
  -- Silverheart's "each of those creatures" as "every paired creature".
  Spec.it s "IsPairedWithSource, which is not IsPaired" $ do
    Common.assertCodec
      s
      codec
      Filter.IsPairedWithSource
      " {\"type\":\"IsPairedWithSource\"} "
    Spec.assertBool s (Codec.encode codec Filter.IsPairedWithSource /= Codec.encode codec Filter.IsPaired) "IsPairedWithSource and IsPaired encode differently"
  Spec.it s "BlockPartnerOfSource" $
    Common.assertCodec
      s
      codec
      (Filter.BlockPartnerOfSource BlockRole.Blocker)
      " {\"type\":\"BlockPartnerOfSource\",\"value\":{\"type\":\"Blocker\"}} "
  Spec.it s "HasActivatedAbility" $
    Common.assertCodec
      s
      codec
      (Filter.HasActivatedAbility Nothing)
      " {\"type\":\"HasActivatedAbility\"} "
  Spec.it s "HasActivatedAbility NonManaAbility" $
    Common.assertCodec
      s
      codec
      (Filter.HasActivatedAbility (Just AbilityKind.NonManaAbility))
      " {\"type\":\"HasActivatedAbility\",\"value\":{\"type\":\"NonManaAbility\"}} "
  Spec.it s "IsInZone Graveyard" $
    Common.assertCodec
      s
      codec
      (Filter.IsInZone Zone.Graveyard)
      " {\"type\":\"IsInZone\",\"value\":{\"type\":\"Graveyard\"}} "
  -- The spelling Drannith Magistrate's "from anywhere other than their hands"
  -- takes: nested under Not, where Grafdigger's Cage nests two of them under Or.
  Spec.it s "Not (IsInZone Hand)" $
    Common.assertCodec
      s
      codec
      (Filter.Not (Filter.IsInZone Zone.Hand))
      " {\"type\":\"Not\",\"value\":{\"type\":\"IsInZone\",\"value\":{\"type\":\"Hand\"}}} "
  Spec.it s "WasCastFrom Graveyard" $
    Common.assertCodec
      s
      codec
      (Filter.WasCastFrom Zone.Graveyard)
      " {\"type\":\"WasCastFrom\",\"value\":{\"type\":\"Graveyard\"}} "
  -- Aven Interrupter's own spelling: "from graveyards or from exile" is two of
  -- these under an Or, where the atom above stands alone on Patrician Geist.
  Spec.it s "Or [WasCastFrom Graveyard, WasCastFrom Exile]" $
    Common.assertCodec
      s
      codec
      (Filter.Or [Filter.WasCastFrom Zone.Graveyard, Filter.WasCastFrom Zone.Exile])
      " {\"type\":\"Or\",\"value\":[{\"type\":\"WasCastFrom\",\"value\":{\"type\":\"Graveyard\"}},{\"type\":\"WasCastFrom\",\"value\":{\"type\":\"Exile\"}}]} "
  -- Shadow the Hedgehog's "if mana from an artifact was spent to cast it". No
  -- Arm.tagged codec forces a constructor's ARM, only its tag, so a constructor
  -- with no arm here round trips nowhere and a card naming it fails to parse.
  Spec.it s "TagWasSpent Artifact" $
    Common.assertCodec
      s
      codec
      (Filter.TagWasSpent ProductionTag.Artifact)
      " {\"type\":\"TagWasSpent\",\"value\":{\"type\":\"Artifact\"}} "
  -- Hallar, the Firefletcher's "if that spell was kicked".
  Spec.it s "Paid" $
    Common.assertCodec
      s
      codec
      (Filter.Paid (KeywordDesignator.OfFamily KeywordFamily.Kicker))
      " {\"type\":\"Paid\",\"value\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Kicker\"}}} "
  -- Synthetic Prototype Audit's "target prototyped spell".
  Spec.it s "IsPrototyped" $
    Common.assertCodec
      s
      codec
      Filter.IsPrototyped
      " {\"type\":\"IsPrototyped\"} "
  Spec.it s "HasDesignation Renowned" $
    Common.assertCodec
      s
      codec
      (Filter.HasDesignation Designation.Renowned)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Renowned\"}} "
  Spec.it s "HasDesignation Monstrous" $
    Common.assertCodec
      s
      codec
      (Filter.HasDesignation Designation.Monstrous)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Monstrous\"}} "
  Spec.it s "HasDesignation Suspected" $
    Common.assertCodec
      s
      codec
      (Filter.HasDesignation Designation.Suspected)
      " {\"type\":\"HasDesignation\",\"value\":{\"type\":\"Suspected\"}} "
  -- CR 122.1's presence read, the one Filter atom with a CounterKind payload.
  Spec.it s "HasCounters" $
    Common.assertCodec
      s
      codec
      (Filter.HasCounters CounterKind.PlusOnePlusOne)
      " {\"type\":\"HasCounters\",\"value\":{\"type\":\"PlusOnePlusOne\"}} "
  -- CR 122.1's kind-agnostic presence read. Razorfin Abolisher's whole target
  -- filter is this atom BARE, so this case is also the card's own round trip and
  -- there is nothing for it to add to the nested-composite list below.
  Spec.it s "HasCountersOfAnyKind" $
    Common.assertCodec
      s
      codec
      Filter.HasCountersOfAnyKind
      " {\"type\":\"HasCountersOfAnyKind\"} "
  Spec.it s "HasSticker" $ Common.assertCodec s codec (Filter.HasSticker StickerKind.Art) " {\"type\":\"HasSticker\",\"value\":{\"type\":\"Art\"}} "
  Spec.it s "Stickered" $ Common.assertCodec s codec Filter.Stickered " {\"type\":\"Stickered\"} "
  Spec.it s "And" $
    Common.assertCodec
      s
      codec
      (Filter.And [Filter.HasCardType CardType.Land, Filter.HasSupertype Supertype.Basic])
      " {\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},{\"type\":\"HasSupertype\",\"value\":{\"type\":\"Basic\"}}]} "
  Spec.it s "Or" $
    Common.assertCodec
      s
      codec
      (Filter.Or [Filter.HasCardType CardType.Creature, Filter.HasCardType CardType.Enchantment])
      " {\"type\":\"Or\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Enchantment\"}}]} "
  Spec.it s "Not" $
    Common.assertCodec
      s
      codec
      (Filter.Not (Filter.HasColor Color.Black))
      " {\"type\":\"Not\",\"value\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}} "
  Spec.it s "Unwritten" $
    Common.assertCodec
      s
      codec
      (Filter.Unwritten (Filter.HasColor Color.White))
      " {\"type\":\"Unwritten\",\"value\":{\"type\":\"HasColor\",\"value\":{\"type\":\"White\"}}} "
  -- Nested And/Or/Not, exercising the recursion the per-constructor cases above
  -- do not.
  Spec.it s "nested And/Or/Not round-trips" $
    let doomBlade = Filter.Not (Filter.HasColor Color.Black)
        terror = Filter.And [Filter.Not (Filter.HasColor Color.Black), Filter.Not (Filter.HasCardType CardType.Artifact)]
        reprisal = Filter.Measures (Measures.MkMeasures Measure.Power Comparison.AtLeast (Operand.Literal 4))
        basicLand = Filter.And [Filter.HasCardType CardType.Land, Filter.HasSupertype Supertype.Basic]
        angelicEdict = Filter.Or [Filter.HasCardType CardType.Creature, Filter.HasCardType CardType.Enchantment]
        controlled = Filter.HeldBy Holder.Controller PlayerRelation.Opponent
        bySubtype = Filter.HasSubtype Subtype.Wall
        isSource = Filter.IsSource
        ravenousRats = Filter.IsPlayer PlayerRelation.Opponent
        killShot = Filter.IsAttacking
        flashFoliage = Filter.IsAttackingPlayer PlayerRelation.You
        -- Soul Snare's whole target filter, the composite the new atom ships in.
        soulSnare = Filter.Or [Filter.IsAttackingPlayer PlayerRelation.You, Filter.IsAttackingPlaneswalker PlayerRelation.You]
        -- Synthetic Bulwark Snare's whole target filter, the composite this atom
        -- ships in.
        bulwarkSnare = Filter.Or [Filter.IsAttackingPlayer PlayerRelation.You, Filter.IsAttackingBattle PlayerRelation.You]
        relentlessAssault = Filter.DeclaredThisTurn BlockRole.Attacker
        -- Break Open's whole target filter, the composite the new atom actually
        -- ships in.
        breakOpen = Filter.And [Filter.IsFaceDown, Filter.HeldBy Holder.Controller PlayerRelation.Opponent]
        crownOfTheAges = Filter.And [Filter.HasSubtype Subtype.Aura, Filter.AttachedTo (Filter.HasCardType CardType.Creature)]
        labyrinthOfSkophos = Filter.Or [Filter.IsAttacking, Filter.IsBlocking]
        -- Hollow Warrior's toll criterion, the deepest nest of the two new
        -- combat-phase atoms a card actually writes.
        hollowWarrior =
          Filter.And
            [ Filter.HasCardType CardType.Creature,
              Filter.Not Filter.IsTapped,
              Filter.Not Filter.DeclaredAttackerThisCombat,
              Filter.Not Filter.DeclaredBlockerThisCombat
            ]
        auraGraftTarget = Filter.And [Filter.HasSubtype Subtype.Aura, Filter.AttachedTo (Filter.And [])]
        -- Miracle Worker: two levels of nesting under the attachment, which no
        -- other entry here reaches.
        miracleWorker =
          Filter.And
            [ Filter.HasSubtype Subtype.Aura,
              Filter.AttachedTo (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You])
            ]
        auraGraftDestination = Filter.CanHostSubject
        oreskosExplorer = Filter.Controls (ControlMargin.MoreThanYou 1) (Filter.HasCardType CardType.Land)
        roundTrip f v = Spec.assertEqWith s "preserved" (Codec.decode codec (Codec.encode codec f)) (Right v)
     in mapM_
          (\f -> roundTrip f f)
          [ doomBlade,
            terror,
            reprisal,
            basicLand,
            angelicEdict,
            controlled,
            bySubtype,
            isSource,
            ravenousRats,
            killShot,
            flashFoliage,
            soulSnare,
            bulwarkSnare,
            relentlessAssault,
            breakOpen,
            crownOfTheAges,
            labyrinthOfSkophos,
            hollowWarrior,
            auraGraftTarget,
            miracleWorker,
            auraGraftDestination,
            oreskosExplorer
          ]
  Spec.describe s "Common.maybe codec" $ do
    Spec.it s "CR 702.29e's typecycling filter, present" $
      Common.assertFromJson s (Codec.decode (Common.maybe codec)) "{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}" (Just (Filter.HasCardType CardType.Creature))
    Spec.it s "absent (JSON null)" $
      Common.assertFromJson s (Codec.decode (Common.maybe codec)) "null" Nothing
  Spec.it s "has a schema" $
    Common.assertHasSchema s codec
