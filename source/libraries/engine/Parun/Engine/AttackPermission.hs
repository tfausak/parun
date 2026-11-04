-- CR 702.3b / 302.6 / 613.11: the continuous effects that let a creature attack
-- past defender or summoning sickness. One of the modules on the axis CR 613.11 reaches past the layer
-- system, alongside Parun.Engine.BlockPermission and
-- Parun.Engine.CombatRestriction; none is a layer.
--
-- The only reader of Parun.Types.AttackPermission. Parun.Engine.Combat asks for a
-- SET and never learns which card produced it.
module Parun.Engine.AttackPermission where

import Data.Set (Set)
import qualified Data.Set as Set
import qualified Parun.Engine.Condition as Condition
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.Rewrite as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Types.AttackPermission as AttackPermission
import Parun.Types.AttackWaiver (AttackWaiver)
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.RuleAbilities as RuleAbilities

-- CR 702.3b / 302.6: which of `candidates` an effect in force right now lets
-- attack past which rule. Parun.Engine.CrewRestriction.cantCrew's body,
-- gate for gate: the same CR 305.7 and CR 613.1f ability losses asked of the
-- source, the same CR 612.1 word swap over its affected set, read against the
-- FULL projection (CR 613.11).
waivers :: [ObjectId] -> GameState -> Set (ObjectId, AttackWaiver)
waivers candidates gs =
  let setEffs = Projection.setLandSubtypeEffects gs
      removed = Projection.abilityRemoval gs
      -- One whole-board projection and one grant walk for the whole walk, both
      -- unforced until some permanent actually reaches `named`.
      pcs = Projection.projectAll gs
      grants = Projection.controlGrants gs
      named source affected candidate = Projection.affectsOn pcs grants source candidate affected gs
      -- CR 613.1f: what a stored grant gave the permanent (Prison Barricade's
      -- kicked entry), with no CR 612.1 word swap (CR 612.3).
      grantedRules = Projection.grantedRuleAbilities gs
      fromGrant source = concatMap (fromPermission source []) (RuleAbilities.attackPermissions (grantedRules source))
      fromPermanent source = case RuleAbilities.attackPermissions (Projection.ruleAbilitiesOf source gs) of
        -- Every permanent in almost every game.
        [] -> []
        permissions ->
          if (null setEffs || Projection.liveAfterLayers setEffs source gs)
            && not (removed source)
            then concatMap (fromPermission source (Projection.readerTextChanges source gs)) permissions
            else []
      -- CR 604.2's "as long as", BlockPermission's `granted`: asked once per
      -- permission, against the source, since CR 109.5 fixes the "you" inside it.
      granted source changes permission = case AttackPermission.while permission of
        Nothing -> True
        Just condition ->
          Condition.holds
            (Projection.fullView gs)
            (Projection.sourceContext gs (Projection.controllerOf source gs) source)
            gs
            source
            (if null changes then condition else Projection.rewriteCondition changes condition)
      fromPermission source changes permission =
        let affected = AttackPermission.affected permission
         in if granted source changes permission
              then (\candidate -> (candidate, AttackPermission.waives permission)) <$> filter (named source (if null changes then affected else Projection.rewriteAffected changes affected)) candidates
              else []
   in Set.fromList (concatMap (\source -> fromPermanent source <> fromGrant source) (Set.toList (GameState.battlefield gs)))
