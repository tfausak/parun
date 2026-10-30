module Parun.Types.GrantPlayFromExile where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ManaSpending as ManaSpending
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PermissionCost as PermissionCost
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.Zone as Zone

-- | The payload of Parun.Types.Effect's GrantPlayFromExile arm: which objects the
-- permission covers, whose it is, how long it lasts, and how its holder may pay
-- for what they cast under it.
--
-- `spending` is CR 118.14's "and mana of any type can be spent to cast that
-- spell", printed on Dire Fleet Daredevil beside the permission itself. It rides
-- the grant rather than the card being exiled, which is rule 118.14's own
-- scoping: the permission is the granting effect's, so the same card cast under
-- some other permission pays its printed colours.
--
-- `alternativeCost` is CR 118.9's alternative cost, printed in the same
-- sentence as the permission -- Extract Power's "without paying its mana cost",
-- Hama, the Bloodbender's waterbend. It rides the grant for `spending`'s
-- reason; Parun.Types.ExilePlayPermission's field of the same name is where it
-- lands.
--
-- `player` is WHO may play, CR 601.3's "that player" -- Elkin Lair's "THE
-- PLAYER may play that card this turn", the upkeep player the trigger bound,
-- not the Lair's controller. Parun.Types.OfferCast's `caster` is the same field
-- one opcode over, and takes the same default: CR 109.5's "you", the resolving
-- controller. Suspend Aggression's "its owner" is the third spelling, and the
-- one that needs no "you" at all -- CR 108.4a answers the controller of a card
-- already in exile with its owner, so PlayerRef.HolderOfBound says it.
--
-- ONE seat, since Parun.Types.ExilePlayPermission holds one (CR 715.3d: "that
-- card ... that player"). So Parun.Engine.Resolve.Arms.Zones's arm grants nothing for
-- a reference naming nobody, and nothing for one naming several --
-- PlayerRef.InSlot's own collapse. A holder per card is Parun.Types.ForEach's
-- job: Suspend Aggression loops over its one exile's slot.
data GrantPlayFromExile = MkGrantPlayFromExile
  { duration :: Duration.Duration,
    player :: PlayerRef.PlayerRef,
    ref :: ObjectRef.ObjectRef,
    spending :: ManaSpending.ManaSpending,
    alternativeCost :: Maybe PermissionCost.PermissionCost,
    -- | CR 601.3: Hama, the Bloodbender\'s "during your turn", a condition the
    -- permission is open only while; baked as it is granted.
    condition :: Maybe Condition.Condition,
    -- | CR 601.3 / 305.9: Ragavan, Nimble Pilferer\'s "you may CAST that card"
    -- is Cast, which never lets an exiled land be played; Galvanic Relay\'s
    -- "you may PLAY that card" is Play.
    verb :: PermissionVerb.PermissionVerb,
    -- | CR 601.2f: the generic mana each spell cast under it costs more --
    -- Lightstall Inquisitor\'s "each spell cast this way costs {1} more".
    increase :: Natural.Natural,
    -- | CR 400.7i / 614.1d: how a land played under it enters -- Lightstall
    -- Inquisitor\'s "each land played this way enters tapped".
    landEnters :: TapState.TapState,
    -- | CR 601.3: how many of the covered cards may be played under it, all
    -- told -- March of Reckless Joy\'s "you may play up to two of those
    -- cards". Nothing is every one of them.
    upTo :: Maybe Natural.Natural,
    -- | CR 601.3: the zone the covered cards must lie in to be granted --
    -- exile\'s "cards exiled this way", or Jace, Telepath Unbound\'s "from your
    -- graveyard". A card a CR 614 replacement sent elsewhere gets nothing.
    zone :: Zone.Zone
  }
  deriving (Eq, Ord, Show)
