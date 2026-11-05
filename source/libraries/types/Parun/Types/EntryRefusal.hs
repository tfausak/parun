module Parun.Types.EntryRefusal where

import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.Zone as Zone

-- | Why a permanent that was materialized for its entry loop did not enter
-- after all; each caller of Parun.Engine.Event.runEntry unmakes the entry and
-- then puts the object where the refusing rule says, except a minted Diverted
-- one, which runEntry has put there.
data EntryRefusal
  = -- | CR 614.1a: an EntryRewrite.SacrificeToEnter went unpaid, so "put it into its owner's graveyard instead".
    Unpaid
  | -- | CR 303.4g: it became an Aura as it entered and has nothing legal to enchant.
    Unhosted
  | -- | CR 614.17d: an entry prohibition names it as it would exist on the battlefield.
    Prohibited
  | -- | CR 614.6: a zone-change redirect sends it to this zone and end instead.
    Diverted Zone.Zone LibraryPosition.LibraryPosition
  deriving (Eq, Ord, Show)
