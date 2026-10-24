-- CR 702.122d / 101.2 / 613.11: the continuous effects that FORBID tapping a
-- creature to pay a crew cost. One of the modules on the axis CR 613.11 reaches
-- past the layer system (alongside Parun.Engine.PlayerEffect,
-- Parun.Engine.BlockRequirement, Parun.Engine.AttackRequirement,
-- Parun.Engine.CombatRestriction, Parun.Engine.AttackCost,
-- Parun.Engine.SacrificeRestriction and Parun.Engine.UntapRestriction). None is a
-- layer, and no layer of Parun.Engine.Projection rewrites them.
--
-- The only reader of Parun.Types.CrewRestriction. Its caller asks for a SET OF
-- IDS and never learns which card produced it.
--
-- ONE place asks, unlike Parun.Engine.SacrificeRestriction's two, and the reason
-- is that CR 702.122d names a COST rather than a game action: a creature is only
-- ever tapped to crew by paying rule 702.122a's cost, and
-- Parun.Engine.Cost.tapCandidates is the single pool that both CR 118.3's
-- payability gate and the payment prompt read. There is no second road for an
-- instruction to tap a creature "to crew" without paying.
module Parun.Engine.CrewRestriction where

import Data.Set (Set)
import qualified Data.Set as Set
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.Rewrite as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Types.CrewRestriction as CrewRestriction
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.RuleAbilities as RuleAbilities

-- CR 702.122d with CR 101.2: which of `candidates` an effect in force right now
-- says CAN'T CREW VEHICLES. Revoke Privileges' third clause is the pool's
-- printing; `crewRestrictions` in data/cards is the carrier, and this answers for
-- every card that fills it.
--
-- Parun.Engine.SacrificeRestriction.cantBeSacrificed's body, gate for gate, and
-- every step of its argument holds here unchanged: the same CR 305.7 and CR
-- 613.1f ability losses are asked of the SOURCE, the same CR 612.1 word swap is
-- applied to its affected set, and CR 613.11 is why the set is read against the
-- FULL projection rather than a layer-bounded one.
cantCrew :: [ObjectId] -> GameState -> Set ObjectId
cantCrew candidates gs =
  let setEffs = Projection.setLandSubtypeEffects gs
      removed = Projection.abilityRemoval gs
      -- One whole-board projection and one grant walk for the whole walk, both
      -- unforced until some permanent actually reaches `named`.
      pcs = Projection.projectAll gs
      grants = Projection.controlGrants gs
      named source affected candidate =
        Projection.affectsOn
          pcs
          grants
          source
          candidate
          affected
          gs
      -- CR 613.1f: what a stored grant gave the permanent, whose gates
      -- Projection.grantedRuleAbilities has asked already, with no CR 612.1
      -- word swap (CR 612.3) -- CombatRestriction.gathered's reading.
      grantedRules = Projection.grantedRuleAbilities gs
      fromGrant source = concatMap (fromRestriction source []) (RuleAbilities.crewRestrictions (grantedRules source))
      fromPermanent source = case RuleAbilities.crewRestrictions (Projection.ruleAbilitiesOf source gs) of
        -- Every permanent in almost every game.
        [] -> []
        restrictions ->
          if (null setEffs || Projection.liveAfterLayers setEffs source gs)
            && not (removed source)
            then concatMap (fromRestriction source (Projection.readerTextChanges source gs)) restrictions
            else []
      fromRestriction source changes restriction =
        let affected = CrewRestriction.affected restriction
         in filter (named source (if null changes then affected else Projection.rewriteAffected changes affected)) candidates
   in Set.fromList (concatMap (\source -> fromPermanent source <> fromGrant source) (Set.toList (GameState.battlefield gs)))
