module Parun.Types.PlayersWho where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef

-- | The payload of Parun.Types.ObjectRef's Players arm (CR 120.3a): the
-- players a PlayerRef names, narrowed to those a player Filter matches --
-- Disorder's "each player who controls a white creature". The Filter is read
-- as Scope.OverPlayers reads one, through Parun.Engine.Count.playerMatches, and
-- Nothing narrows by nothing.
data PlayersWho = MkPlayersWho
  { players :: PlayerRef.PlayerRef,
    who :: Maybe (Filter.Filter Keyword.Keyword)
  }
  deriving (Eq, Ord, Show)
