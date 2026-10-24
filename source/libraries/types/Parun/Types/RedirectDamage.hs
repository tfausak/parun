module Parun.Types.RedirectDamage where

import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Uses as Uses

-- | CR 614.9's redirection: for a duration, damage of some kind headed for one
-- recipient is dealt to another instead.

-- 'from' and 'to' are both an ObjectRef and are the two ends of the same
-- rewrite, so they are named rather than positional: a card file that swapped
-- them would redirect damage in the wrong direction and still decode.
data RedirectDamage = MkRedirectDamage
  { duration :: Duration.Duration,
    -- | PRINTED, not assumed -- Turn the Tables says "all COMBAT damage".
    -- Nothing is a redirect naming no kind, and is elided rather than written
    -- null.
    kind :: Maybe DamageKind.DamageKind,
    -- | Harm's Way's "the next 2 damage": the amount the redirection moves before
    -- it is spent, CR 615.7's counted shape on a rule-614 rewrite. Nothing is
    -- Turn the Tables' "all", which only the duration and `uses` end.
    amount :: Maybe Quantity.Quantity,
    -- | The recipients the redirection covers, NAMED -- Carom's "target creature".
    -- Nothing where the card describes them instead, through the two fields
    -- below; Parun.Types.PreventNextDamage's split.
    from :: Maybe ObjectRef.ObjectRef,
    -- | The covered recipients DESCRIBED -- Harm's Way's "permanents you control"
    -- -- read live at each damage event (CR 611.2c), as DamagePattern's
    -- whatRecipient is.
    whatRecipient :: Maybe (Filter.Filter Keyword.Keyword),
    -- | The covered PLAYER, as CR 109.5's relation to the controller -- Harm's
    -- Way's "you"; DamagePattern.whoRecipient's half.
    whoRecipient :: Maybe PlayerRelation.PlayerRelation,
    to :: ObjectRef.ObjectRef,
    -- | CR 609.7a's "by a source of your choice" (Oracle's Attendants), as the
    -- PROPERTIES the chosen source must have, exactly as
    -- Parun.Types.PreventAllDamage carries it on the unbounded shield. Nothing is
    -- a redirection naming no source at all (Turn the Tables), which watches
    -- every source; `Just` makes the effect's controller choose ONE source when
    -- the effect is created, and Parun.Engine.Resolve bakes that id into
    -- Parun.Types.DamagePattern.whichSource.
    --
    -- The Filter is BOTH halves of CR 609.7b: it narrows the candidates offered,
    -- and it is written into DamagePattern.whatSource so the recheck happens at
    -- the damage event rather than at the choice. Oracle's Attendants says only
    -- "a source", so its Filter is the trivial `And []` -- present, not absent,
    -- because "any source of your choice" is still a choice.
    chosenSource :: Maybe (Filter.Filter Keyword.Keyword),
    -- | CR 614.3's use count: Jade Monolith's "the next time" is Once, a
    -- redirection spent by the first damage event it moves, whatever its size;
    -- Unlimited for every other.
    uses :: Uses.Uses,
    -- | CR 609.7b's property-named source, Parun.Types.PreventAllDamage's field of
    -- the same name: Kjeldoran Royal Guard's "by unblocked creatures", rechecked
    -- at each damage event and asking nobody to choose. `And []` for a
    -- redirection that describes no source.
    whatSource :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
