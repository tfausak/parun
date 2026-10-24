-- CR 502.3 / 101.2 / 613.11: the continuous effects that FORBID CR 502.3's
-- untap, cap how many permanents it untaps, or leave it to the active player.
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

import qualified Data.List as List
import Data.Set (Set)
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Condition as Condition
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Projection.Rewrite as Projection
import qualified Pawl.Engine.Projection.View as Projection
import qualified Pawl.Engine.RestrictedCreatures as RestrictedCreatures
import qualified Pawl.Extra.Natural as Natural
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.Prohibition as Prohibition
import qualified Pawl.Types.RuleAbilities as RuleAbilities
import qualified Pawl.Types.UntapHold as UntapHold
import qualified Pawl.Types.UntapRestriction as UntapRestriction

-- CR 502.3 with CR 101.2: each restriction in force right now over
-- `candidates`, by its `hold`, with the candidates it names:
-- UntapHold.Forbidden is what DOESN'T UNTAP (Tsabo's Web's second sentence,
-- Meekstone's whole text), UntapHold.AtMost what no more than so many of may
-- untap (Static Orb), UntapHold.Elective what its controller MAY leave tapped
-- (Amber Prison's first sentence). `untapRestrictions` in data/cards is the
-- carrier, and this answers for every card that fills it. One entry per
-- restriction rather than a union, because a cap counts its own set (CR 101.2:
-- Static Orb and Winter Orb each hold, neither adding to the other).
--
-- Pawl.Engine.SacrificeRestriction.cantBeSacrificed's body, gate for gate, and
-- every step of its argument holds here unchanged: the same CR 305.7 and CR
-- 613.1f ability losses are asked of the SOURCE, the same CR 612.1 word swap is
-- applied to its affected set, and CR 613.11 is why the set is read against the
-- FULL projection rather than a layer-bounded one. CR 611.3a's "as long as"
-- (`while`) is asked once per restriction, as AttackRequirement's is, with the
-- same word swap.
gathered :: [ObjectId] -> GameState -> [(UntapHold.UntapHold, Set ObjectId)]
gathered candidates gs =
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
      fromGrant source = concatMap (fromRestriction source []) (RuleAbilities.untapRestrictions (grantedRules source))
      fromPermanent source = case RuleAbilities.untapRestrictions (Projection.ruleAbilitiesOf source gs) of
        -- Every permanent in almost every game.
        [] -> []
        restrictions ->
          if (null setEffs || Projection.liveAfterLayers setEffs source gs)
            && not (removed source)
            then concatMap (fromRestriction source (Projection.readerTextChanges source gs)) restrictions
            else []
      inForce source changes restriction = case UntapRestriction.while restriction of
        Nothing -> True
        Just condition ->
          Condition.holds
            (Projection.fullView gs)
            (Projection.sourceContext gs (Projection.controllerOf source gs) source)
            gs
            source
            (if null changes then condition else Projection.rewriteCondition changes condition)
      fromRestriction source changes restriction
        | inForce source changes restriction =
            let affected = UntapRestriction.affected restriction
             in [(UntapRestriction.hold restriction, Set.fromList (filter (named source (if null changes then affected else Projection.rewriteAffected changes affected)) candidates))]
        | otherwise = []
      -- CR 611.2b: a stored row is in force from the moment its window opens
      -- (Expiry.begun) until Expiry's sweep drops it. Every one is a "can't".
      stored = RestrictedCreatures.prohibited Prohibition.Untap candidates gs
   in (UntapHold.Forbidden, stored) : concatMap (\source -> fromPermanent source <> fromGrant source) (Set.toList (GameState.battlefield gs))

-- CR 502.3 / 101.2: which of `offered` untap, given the active player's
-- `chosen` and the caps (UntapHold.AtMost) in force. Every cap holds at once
-- and none adds to another, so two Static Orbs still leave two (its ruling).
-- Two passes in `offered`'s order: what was chosen, kept
-- while every cap still allows it, which is how an answer naming too many is
-- cut back (Game.pickCounted's truncation); then every offered permanent that
-- is not `elective` and that the caps still allow, since CR 502.3 untaps all of
-- a player's permanents but those an effect keeps tapped -- docs/decisions.md,
-- "An untap cap leaves tapped only what it must".
settle :: [(Natural, Set ObjectId)] -> Set ObjectId -> [ObjectId] -> Set ObjectId -> Set ObjectId
settle caps elective offered chosen =
  let fits taken oid = all (\(n, counted) -> not (Set.member oid counted) || Natural.length (Set.intersection counted taken) < n) caps
      add taken oid = if fits taken oid then Set.insert oid taken else taken
      kept = List.foldl' add Set.empty (filter (`Set.member` chosen) offered)
   in List.foldl' add kept (filter (\oid -> not (Set.member oid elective) && not (Set.member oid kept)) offered)
