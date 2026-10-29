-- CR 606.2's classification of an activated ability's cost: is it a loyalty
-- ability, and how much loyalty does each component move. Out of
-- Parun.Engine.Cost, the casing home for Parun.Types.CostComponent, because
-- Parun.Engine.Count and Parun.Engine.Quantity ask it of the turn's past
-- activations (Parun.Types.Quantity's ActivationsThisTurn) and sit below Cost.
module Parun.Engine.Loyalty where

import qualified Data.Maybe as Maybe
import qualified Parun.Engine.Binding as Binding
import Parun.Types.Cost (Cost)
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.LoyaltyKind as LoyaltyKind

-- CR 606.2: an activated ability with a loyalty symbol in its cost is a loyalty
-- ability. The CLASSIFICATION Parun.Engine.Activate reads for CR 606.3's window
-- and once-per-turn limit. Derived from the cost rather than stored on the
-- ability -- CR 606.2 is a rule about what a cost CONTAINS and not a rider a
-- card prints, which is why Jace Beleren's abilities carry no
-- ActivationRestriction.SorcerySpeed.
isLoyaltyCost :: Cost Keyword.Type.Keyword -> Bool
isLoyaltyCost cost = any isLoyaltyComponent (Cost.components cost)

-- The same question in the shape a cost adjustment asks it
-- (Parun.Types.ActivationCriteria.whichLoyalty, Parun.Types.LoyaltyKind).
--
-- Asked of the PRINTED cost, never of the total: Carth the Lion's own addition
-- is a loyalty component, so a reading taken after CR 601.2f folded the
-- adjustments in would make every ability it touched a loyalty ability and tax
-- itself into applying. Parun.Engine.Activatable.loyaltyOk reads CR 606.3 off the
-- printed cost for that reason too.
loyaltyKindOf :: Cost Keyword.Type.Keyword -> LoyaltyKind.LoyaltyKind
loyaltyKindOf cost = if isLoyaltyCost cost then LoyaltyKind.LoyaltyAbility else LoyaltyKind.NonLoyaltyAbility

-- CR 606.2 reads the symbol, not its number, so an unannounced [-X] is one too.
isLoyaltyComponent :: CostComponent.CostComponent Keyword.Type.Keyword -> Bool
isLoyaltyComponent component = component == CostComponent.RemoveLoyaltyFromThis (CostAmount.Announced Binding.variableX) || Maybe.isJust (loyaltyAmountOf component)

-- The SIGNED amount of loyalty a component moves, positive for CR 606.4's adding
-- half and negative for the removing one. `isLoyaltyComponent` above is this
-- without the number, plus the unannounced [-X], so the two cannot drift
-- apart. An Integer and not a Natural: CR 606.5's combining sums the two halves
-- against each other.
--
-- EXHAUSTIVE with no wildcard, `orderSensitive`'s posture and for its reason.
loyaltyAmountOf :: CostComponent.CostComponent Keyword.Type.Keyword -> Maybe Integer
loyaltyAmountOf component = case component of
  CostComponent.AddLoyaltyToThis n -> Just (toInteger n)
  CostComponent.RemoveLoyaltyFromThis (CostAmount.Fixed n) -> Just (negate (toInteger n))
  -- Nothing until CR 601.2b substitutes it; `isLoyaltyComponent` classifies it
  -- all the same.
  CostComponent.RemoveLoyaltyFromThis (CostAmount.Announced _) -> Nothing
  CostComponent.TapThis -> Nothing
  CostComponent.UntapThis -> Nothing
  CostComponent.SacrificeThis -> Nothing
  CostComponent.ReturnThis -> Nothing
  CostComponent.PayLife _ -> Nothing
  CostComponent.PayHalfLife _ -> Nothing
  CostComponent.Sacrifice {} -> Nothing
  CostComponent.TapForTotalPower {} -> Nothing
  CostComponent.TapPermanents {} -> Nothing
  CostComponent.ReturnPermanents {} -> Nothing
  CostComponent.ExilePermanents {} -> Nothing
  CostComponent.DiscardCards {} -> Nothing
  CostComponent.DiscardThis _ -> Nothing
  CostComponent.PutCardFromHandOntoBattlefield _ -> Nothing
  CostComponent.PayEnergy _ -> Nothing
  -- Nothing, and this is the LOAD-BEARING arm of the component: CR 606.4's
  -- loyalty symbol is what CR 606.2 reads to call an ability a loyalty ability,
  -- and a Just here would ration Barkhide Troll's ability to once a turn (CR
  -- 606.3), gate it on the sorcery window and feed it to `combineLoyalty` (CR
  -- 606.5). Removing a +1\/+1 counter is none of that. Proven, not a fence:
  -- Parun.CostSpec's Barkhide Troll cases both redden on a Just here.
  CostComponent.RemoveCountersFromThis _ -> Nothing
  -- Nothing, the arm above's reason unchanged by the counters coming off
  -- another permanent: CR 606.4's loyalty symbol is what makes a loyalty
  -- ability, and this is a +1\/+1 counter.
  CostComponent.RemoveCounters {} -> Nothing
  CostComponent.PutCountersOnThis _ -> Nothing
  CostComponent.Blight _ -> Nothing
  CostComponent.Forage -> Nothing
  CostComponent.FlipCoin -> Nothing
  CostComponent.ChooseOpponent _ -> Nothing
  CostComponent.Waterbend _ -> Nothing
  CostComponent.WaterbendInstead _ -> Nothing
  CostComponent.ExileThisFromGraveyard -> Nothing
  CostComponent.ExileThis -> Nothing
  CostComponent.ExileCardsFromGraveyard {} -> Nothing
  CostComponent.ExileMaterials {} -> Nothing
  CostComponent.ExileTopFromGraveyard _ -> Nothing
  CostComponent.CollectEvidence _ -> Nothing
  CostComponent.CollectEvidenceOfTargets -> Nothing
  CostComponent.ExileCardsFromHand {} -> Nothing
  CostComponent.RevealCardFromHand _ -> Nothing
  CostComponent.Behold _ -> Nothing
  CostComponent.BeholdAndExile _ -> Nothing
  CostComponent.MillCards _ -> Nothing
  CostComponent.RevealTopOfLibrary _ -> Nothing
