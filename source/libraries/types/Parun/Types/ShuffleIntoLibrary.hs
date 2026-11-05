module Parun.Types.ShuffleIntoLibrary where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | CR 701.24: shuffle the objects the ObjectRef names into a library, and
-- shuffle that library whether or not the objects arrived.
--
-- `ref` is mandatory, and CR 701.24a on its own -- a "then shuffle" that moves
-- nothing -- is Parun.Types.Effect's Shuffle arm rather than an absent one here.
data ShuffleIntoLibrary = MkShuffleIntoLibrary
  { -- | NAMES the library, which CR 701.24c needs: an owner read off the objects
    -- disappears with them. Absent when the card's own words derive it instead,
    -- as Riftsweeper's "its owner" does, so the key is elided in that case.
    library :: Maybe PlayerRef.PlayerRef,
    -- | What the one instruction shuffles in, moved as one event and shuffled
    -- once (CR 608.2f); Timetwister's "their hand and graveyard" is an AllOf.
    ref :: ObjectRef.ObjectRef,
    -- | CR 400.7: where the incarnations the move minted are bound, for a later
    -- instruction's count -- Winds of Change's "draws that many".
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
