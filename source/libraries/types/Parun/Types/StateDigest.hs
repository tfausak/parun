module Parun.Types.StateDigest where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Numeric.Natural as Natural
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.PastActivation as PastActivation

-- | CR 733.3: a game state as Parun.Engine.Fragmented.digest leaves it for
-- comparison, its object ids and timestamps renumbered by rank (CR 400.7).
-- Ordered by a few cheap, id-free fields before the canonical text, so two
-- states that differ in who holds priority, how much is on the stack or the
-- battlefield, or what is in a mana pool -- most pairs a loop compares --
-- never render every object.
data StateDigest = MkStateDigest
  { -- | The state, less what the digest drops, as it stands.
    unwrap :: GameState.GameState,
    -- | `unwrap` rendered with every object id and timestamp replaced by its
    -- rank among those it holds. The only field compared bar the cheap ones,
    -- and lazy, so a comparison the cheap fields settle never renders it.
    canonical :: String,
    -- | The rank `canonical` gives each object id `unwrap` holds, so a
    -- choice made in this state can be compared under the same renaming.
    objectRanks :: Map.Map Natural.Natural Int,
    -- | The dropped GameState.events, carried uncompared so a recurrence can
    -- ask which of them the loop wrote.
    events :: Seq.Seq LoggedEvent.LoggedEvent,
    -- | The dropped GameState.activationsThisTurn, carried the same way.
    activations :: Seq.Seq PastActivation.PastActivation
  }
  deriving (Show)

instance Eq StateDigest where
  a == b = compare a b == EQ

instance Ord StateDigest where
  compare x y =
    compare (cheap (unwrap x)) (cheap (unwrap y)) <> compare (canonical x) (canonical y)
    where
      cheap gs =
        ( ( GameState.priority gs,
            GameState.passed gs,
            length (GameState.stack gs),
            GameState.phase gs
          ),
          ( Map.size (GameState.objects gs),
            length (GameState.battlefield gs),
            GameState.manaPool gs,
            fmap length (GameState.hand gs)
          )
        )
