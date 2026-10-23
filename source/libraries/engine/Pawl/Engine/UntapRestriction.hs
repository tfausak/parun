-- CR 502.3 / 101.2 / 613.11: the continuous effects that FORBID CR 502.3's untap.
-- One of the modules on the axis CR 613.11 reaches past the layer system
-- (alongside Pawl.Engine.PlayerEffect, Pawl.Engine.BlockRequirement,
-- Pawl.Engine.AttackRequirement, Pawl.Engine.CombatRestriction,
-- Pawl.Engine.AttackCost and Pawl.Engine.SacrificeRestriction). None is a layer,
-- and no layer of Pawl.Engine.Projection rewrites them.
--
-- The only reader of Pawl.Types.UntapRestriction. Its caller asks for a SET OF
-- IDS and never learns which card produced it.
--
-- ONE place asks, unlike Pawl.Engine.SacrificeRestriction's two: the sentence
-- names the untap step's turn-based action and nothing else, so an Effect.Untap
-- during the turn (CR 701.26b) is untouched -- which is the printed reading, not
-- a shortcut.
--
-- The printed carrier, and the stored Untap rows beside it: the rows a
-- resolution leaves behind (Pawl.Types.ActiveObjectProhibition, Wall of Stolen
-- Identity's linked trigger), unioned in so the caller never learns which road
-- a prohibition took. The one-shot prohibitions stored on the victim
-- (Object.doesNotUntapFor, written by Effect.DoesNotUntapNext, and
-- Object.exertedBy, written by CR 508.1g's exert payment) are not gathered here
-- and could not be: they are fields on the VICTIM rather than on anything the
-- battlefield walk below would reach. Engine.untapAll subtracts them beside
-- this module's answer.
module Pawl.Engine.UntapRestriction where

import Data.Set (Set)
import qualified Data.Set as Set
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Projection.Rewrite as Projection
import qualified Pawl.Engine.Projection.View as Projection
import qualified Pawl.Engine.RestrictedCreatures as RestrictedCreatures
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.Prohibition as Prohibition
import qualified Pawl.Types.RuleAbilities as RuleAbilities
import qualified Pawl.Types.UntapHold as UntapHold
import qualified Pawl.Types.UntapRestriction as UntapRestriction

-- CR 502.3 with CR 101.2: which of `candidates` an effect in force right now
-- holds back from untapping during its controller's untap step, by `hold`:
-- UntapHold.Forbidden is what DOESN'T UNTAP (Tsabo's Web's second sentence,
-- Meekstone's whole text), UntapHold.Elective what its controller MAY leave
-- tapped (Amber Prison's first sentence). `untapRestrictions` in data/cards is
-- the carrier, and this answers for every card that fills it.
--
-- Pawl.Engine.SacrificeRestriction.cantBeSacrificed's body, gate for gate, and
-- every step of its argument holds here unchanged: the same CR 305.7 and CR
-- 613.1f ability losses are asked of the SOURCE, the same CR 612.1 word swap is
-- applied to its affected set, and CR 613.11 is why the set is read against the
-- FULL projection rather than a layer-bounded one.
restricted :: UntapHold.UntapHold -> [ObjectId] -> GameState -> Set ObjectId
restricted hold candidates gs =
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
      held = filter ((== hold) . UntapRestriction.hold) . RuleAbilities.untapRestrictions
      fromGrant source = concatMap (fromRestriction source []) (held (grantedRules source))
      fromPermanent source = case held (Projection.ruleAbilitiesOf source gs) of
        -- Every permanent in almost every game.
        [] -> []
        restrictions ->
          if (null setEffs || Projection.liveAfterLayers setEffs source gs)
            && not (removed source)
            then concatMap (fromRestriction source (Projection.readerTextChanges source gs)) restrictions
            else []
      fromRestriction source changes restriction =
        let affected = UntapRestriction.affected restriction
         in filter (named source (if null changes then affected else Projection.rewriteAffected changes affected)) candidates
      -- CR 611.2b: a stored row is in force from the moment its window opens
      -- (Expiry.begun) until Expiry's sweep drops it. Every one is a "can't".
      stored = case hold of
        UntapHold.Forbidden -> RestrictedCreatures.prohibited Prohibition.Untap candidates gs
        UntapHold.Elective -> Set.empty
   in stored <> Set.fromList (concatMap (\source -> fromPermanent source <> fromGrant source) (Set.toList (GameState.battlefield gs)))
