-- CR 115 / 101.2 / 613.11: the continuous effects that FORBID targeting an
-- object with one kind of spell or ability, other than shroud, hexproof and
-- protection, which are keywords the object has (CR 702.18a, 702.11b, 702.16b)
-- and are read off its projection by Parun.Engine.Target.targetable. One of the
-- modules on the axis CR 613.11 reaches past the layer system, alongside
-- Parun.Engine.CrewRestriction and its siblings.
--
-- The reader of a PRINTED Parun.Types.TargetRestriction; a resolved one riding a
-- player effect (Autumn's Veil) is Parun.Engine.PlayerEffect.forbidsTargeting's.
-- Its caller asks whether one object is stopped for one kind of spell or
-- ability, and never learns which card stopped it.
module Parun.Engine.TargetRestriction where

import Data.Map.Strict (Map)
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.Rewrite as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Filter as Filter.Type
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.ProjectedCharacteristics (ProjectedCharacteristics)
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.TargetRestriction as TargetRestriction

-- One prohibition in force: the permanent whose ability states it, the kind of
-- spell or ability it stops, and its affected set and aimers after CR 612.1's
-- word swap.
data Row = MkRow
  { source :: ObjectId,
    kind :: StackObjectKind.StackObjectKind,
    affected :: Affected.Affected,
    aimers :: Filter.Type.Filter Keyword.Keyword
  }

-- Every prohibition in force right now, gathered off the battlefield with
-- Parun.Engine.CrewRestriction.cantCrew's gates: CR 613.1f's ability loss and
-- the CR 305.7 land-type rewrite asked of the SOURCE, CR 612.1's word swap
-- applied to its affected set, and a stored grant's rows (CR 613.1f) taken as
-- given. Empty on almost every board, which is what makes it cheap to ask per
-- candidate: Parun.Engine.Target.Pools holds it as a thunk.
rows :: GameState -> [Row]
rows gs =
  let setEffs = Projection.setLandSubtypeEffects gs
      removed = Projection.abilityRemoval gs
      grantedRules = Projection.grantedRuleAbilities gs
      row src changes restriction =
        let printed = TargetRestriction.affected restriction
            printedAimers = TargetRestriction.aimers restriction
         in MkRow
              { source = src,
                kind = TargetRestriction.kind restriction,
                affected = if null changes then printed else Projection.rewriteAffected changes printed,
                aimers = if null changes then printedAimers else Filter.rewrite changes printedAimers
              }
      fromGrant src = fmap (row src []) (RuleAbilities.targetRestrictions (grantedRules src))
      fromPermanent src = case RuleAbilities.targetRestrictions (Projection.ruleAbilitiesOf src gs) of
        -- Every permanent in almost every game.
        [] -> []
        restrictions ->
          if (null setEffs || Projection.liveAfterLayers setEffs src gs)
            && not (removed src)
            then fmap (row src (Projection.readerTextChanges src gs)) restrictions
            else []
   in concatMap (\src -> fromPermanent src <> fromGrant src) (GameState.battlefield gs)

-- CR 115 with CR 101.2: may a spell or ability of this kind, whose projection
-- is `aimerView`, NOT target the candidate? Asked against the caller's
-- whole-board projection and control grants, for CR 613.11's reason: the
-- affected set is read after every layer.
stops :: Map ObjectId ProjectedCharacteristics -> [Projection.ControlGrant] -> [Row] -> StackObjectKind.StackObjectKind -> Filter.View -> ObjectId -> GameState -> Bool
stops pcs grants rowsInForce aimer aimerView candidate gs =
  any
    ( \r ->
        kind r == aimer
          && Projection.affectsOn pcs grants (source r) candidate (affected r) gs
          && Filter.matches (Projection.sourceContext gs (Projection.controllerOf (source r) gs) (source r)) aimerView (aimers r)
    )
    rowsInForce
