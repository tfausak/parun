{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExilePlayPermission where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ManaSpending as ManaSpending
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PermissionCost as PermissionCost
import qualified Parun.Codec.PermissionVerb as PermissionVerb
import qualified Parun.Codec.PlayBudget as PlayBudget
import qualified Parun.Codec.PlayPermissionOrigin as PlayPermissionOrigin
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExilePlayPermission as ExilePlayPermission

-- | Every axis 'Fields.required', because none of them has a default the rules
-- give: `spending` is CR 118.14's rider, `alternativeCost` is CR 118.9a's,
-- `increase` and `landEnters` are CR 601.2f's and CR 614.1d's, `budget` is
-- CR 601.3's count of plays left, and `origin`
-- is CR 715.3d's own question -- a permission written without any of them
-- would decode as a different permission rather than as an incomplete
-- one. The type's haddock argues each field. Unlike
-- Parun.Codec.GrantPlayFromExile's opcode, which elides its riders at their
-- defaults, this is a whole game state's record of a permission already
-- granted.
codec :: Codec.Codec ExilePlayPermission.ExilePlayPermission
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec ExilePlayPermission.player
  source <- Fields.required "source" ObjectId.codec ExilePlayPermission.source
  expiry <- Fields.required "expiry" Expiry.codec ExilePlayPermission.expiry
  spending <- Fields.required "spending" ManaSpending.codec ExilePlayPermission.spending
  alternativeCost <- Fields.required "alternativeCost" (Common.maybe PermissionCost.codec) ExilePlayPermission.alternativeCost
  condition <- Fields.required "condition" (Common.maybe Condition.codec) ExilePlayPermission.condition
  origin <- Fields.required "origin" PlayPermissionOrigin.codec ExilePlayPermission.origin
  verb <- Fields.required "verb" PermissionVerb.codec ExilePlayPermission.verb
  increase <- Fields.required "increase" Common.natural ExilePlayPermission.increase
  landEnters <- Fields.required "landEnters" TapState.codec ExilePlayPermission.landEnters
  budget <- Fields.required "budget" (Common.maybe PlayBudget.codec) ExilePlayPermission.budget
  pure
    ExilePlayPermission.MkExilePlayPermission
      { ExilePlayPermission.player = player,
        ExilePlayPermission.source = source,
        ExilePlayPermission.expiry = expiry,
        ExilePlayPermission.spending = spending,
        ExilePlayPermission.alternativeCost = alternativeCost,
        ExilePlayPermission.condition = condition,
        ExilePlayPermission.origin = origin,
        ExilePlayPermission.verb = verb,
        ExilePlayPermission.increase = increase,
        ExilePlayPermission.landEnters = landEnters,
        ExilePlayPermission.budget = budget
      }
