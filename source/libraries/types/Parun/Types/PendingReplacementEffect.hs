module Parun.Types.PendingReplacementEffect where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.SlotName as SlotName

-- | CR 614.1a: the effects a replacement ran in an event's place and has not
-- run yet -- Kill-Suit Cultist's "destroy that creature instead"
-- (DamageRewrite.RunEffects), Lich's Mirror's reset (GameLossR) and Forbidden
-- Crypt's loss of the game (DrawRewrite.FromGraveyardOrLose).
-- Parun.Types.PendingEntryEffect's twin one event class over, and queued for the
-- same reason: the module that applies a replacement (Parun.Engine.Event) is
-- below the module that can run a card's effects.
--
-- A program plus the environment it must resolve in, kept together because the
-- environment cannot be re-derived at the drain: the installing spell or ability
-- is long gone (CR 400.7), so neither the slots it named nor CR 109.5's "you"
-- survive on the board. The same posture Parun.Types.PreventionRider takes, and
-- for the same reason.
--
-- `targets` is Parun.Types.ActiveReplacement.slots, which is what makes "that
-- creature" nameable turns later; `controller` is who performs the effects,
-- which is the ROW's controller and not the event's source; `source` is CR
-- 113.7's source of the effect that created the replacement.
data PendingReplacementEffect = MkPendingReplacementEffect
  { effects :: Seq.Seq (Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)),
    targets :: Map.Map SlotName.SlotName (Set.Set Recipient.Recipient),
    controller :: PlayerId.PlayerId,
    source :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
