-- | CR 804: the deploy creatures option.
module Parun.Engine.Deploy where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Engine.Mint as Mint
import Parun.Types.ActivatedAbility (ActivatedAbility)
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Activator as Activator
import Parun.Types.Card (Card)
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetSlot as TargetSlot

-- | CR 804.2: does this permanent have the deploy ability, given whether the
-- game uses the option (GameSettings.deployCreatures)? Every creature does. An
-- ability of the creature like CR 305.6's intrinsic one, so CR 613.1f's "loses
-- all abilities" takes it too (Parun.Engine.Subtype.intrinsicManaAbilityOf's
-- reading).
--
-- Asked of a permanent's characteristics only: CR 804.2's "creature" is a
-- creature on the battlefield (CR 109.2), so no reader asks it of a card or a
-- spell.
grants :: Bool -> PC.ProjectedCharacteristics -> Bool
grants optionOn pc =
  optionOn
    && Set.member CardType.Creature (PC.cardTypes pc)
    && not (PC.lostAllAbilities pc)

-- | CR 804.2: "{T}: Target teammate gains control of this creature. Activate
-- only as a sorcery."
ability :: ActivatedAbility Card (GrantedAbility.GrantedAbility Card)
ability =
  let slot = TargetSlot.required Pool.Players (Just (Filter.IsPlayer PlayerRelation.Teammate))
      effect = Effect.GainControl (GainControl.MkGainControl Duration.Indefinite (ObjectRef.EachMatching Filter.IsSource) (PlayerRef.InSlot teammate))
   in ActivatedAbility.MkActivatedAbility
        { ActivatedAbility.cost = Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis],
          ActivatedAbility.modal =
            Mint.oneModeTargeting (Map.singleton teammate slot) (Seq.singleton effect),
          ActivatedAbility.maximumX = [],
          ActivatedAbility.minimumX = 0,
          ActivatedAbility.definedX = Nothing,
          -- CR 307.5's sorcery timing.
          ActivatedAbility.restrictions = [ActivationRestriction.SorcerySpeed],
          ActivatedAbility.activator = Activator.Controller,
          ActivatedAbility.condition = Nothing,
          ActivatedAbility.name = Nothing,
          ActivatedAbility.keyword = Nothing
        }

-- The slot CR 804.2's one target is chosen into.
teammate :: SlotName.SlotName
teammate = SlotName.MkSlotName (Text.pack "teammate")
