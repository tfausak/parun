module Parun.Types.Hotseat where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.PlayerId as PlayerId

-- | What the text client keeps between lines, for seats sharing one screen.
data Hotseat = MkHotseat
  { -- | The seat the screen last showed.
    facing :: Maybe PlayerId.PlayerId,
    -- | Whether the screen shows lines said since a line was last typed.
    unread :: Bool,
    -- | CR 104.3a: the seats that asked to concede.
    conceding :: Set.Set PlayerId.PlayerId,
    -- | Per seat and game of the match (PlayerView.game), the turn and how
    -- many of its witnessed entries the client has read off its views.
    seen :: Map.Map (PlayerId.PlayerId, Natural.Natural) (Natural.Natural, Natural.Natural),
    -- | Per seat, the entries read off its views and not yet shown it, as the
    -- client words them. They outlive the turn they were read in.
    news :: Map.Map PlayerId.PlayerId (Seq.Seq Text.Text),
    -- | The seats the client has asked a question.
    greeted :: Set.Set PlayerId.PlayerId,
    -- | Whether a priority offering only passing and mana abilities is passed
    -- without asking, for the seat the screen faces.
    autoPass :: Bool,
    -- | Each seat that chose auto during the payment now under way, beside
    -- the colors the source auto last tapped is for.
    paying :: Map.Map PlayerId.PlayerId (Set.Set ManaType.ManaType),
    -- | Each seat whose last action chosen casts a spell or activates an
    -- ability, as its next priority words it undone (CR 734.1), beside the
    -- game, turn and count of witnessed entries its view held then.
    attempted :: Map.Map PlayerId.PlayerId ((Natural.Natural, Natural.Natural, Natural.Natural), Text.Text)
  }
  deriving (Eq, Show)

-- | A screen no seat has looked at yet, passing for a seat with nothing
-- else to do.
fresh :: Hotseat
fresh = MkHotseat {facing = Nothing, unread = False, conceding = Set.empty, seen = Map.empty, news = Map.empty, greeted = Set.empty, autoPass = True, paying = Map.empty, attempted = Map.empty}
