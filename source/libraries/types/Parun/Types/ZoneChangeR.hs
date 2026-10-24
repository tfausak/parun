module Parun.Types.ZoneChangeR where

import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern

-- | The payload of Parun.Types.ReplacementEffect's ZoneChangeR arm (#1305): the
-- zone change intercepted, the zone the object goes to instead, and the two
-- actions the redirect may perform alongside the move.
--
-- Both riders default to False and are elided rather than written, DamageR's
-- `riders` posture: a redirect that only names a destination is the common
-- shape. `position` defaults to LibraryPosition.defaultValue and `optional` to
-- False the same way.
data ZoneChangeR = MkZoneChangeR
  { matching :: ZoneChangePattern.ZoneChangePattern,
    destination :: Zone.Zone,
    -- | CR 701.20a: show the moving card to all players, as Nexus of Fate's
    -- "reveal Nexus of Fate and shuffle it into its owner's library instead"
    -- does.
    revealing :: Bool,
    -- | CR 701.24a: randomize the moving card's owner's library, which is what
    -- separates "shuffle it into its owner's library" from putting it on the
    -- bottom.
    shuffling :: Bool,
    -- | CR 401.2: the end of the library a redirect into one puts the card on --
    -- Library of Leng's "on top of your library". Ignored for any other
    -- destination.
    position :: LibraryPosition.LibraryPosition,
    -- | CR 614.1a's "you MAY ... instead": the row's controller is asked as it
    -- applies, and declining leaves the event standing.
    optional :: Bool
  }
  deriving (Eq, Ord, Show)
