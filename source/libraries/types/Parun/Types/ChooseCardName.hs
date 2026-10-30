module Parun.Types.ChooseCardName where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's ChooseCardName arm: WHO chooses CR
-- 201.4's name, and CR 201.4a's restriction on what may be chosen.
--
-- A PlayerRef and not CR 109.5's "you", because the chooser is a target slot on
-- Petra Sphinx's "target player chooses a card name" and every player at once on
-- Conundrum Sphinx's. Parun.Types.Search carries two of these for the same
-- reason: whose library is searched is a question the card asks, not a constant.
--
-- Each chooser's name is kept under that player in Object.chosenNames, so "the
-- name THEY chose" reads its own chooser's (Filter.HasChosenName's NameChooser).
--
-- @among@ confines the offer to the names of the cards an earlier effect bound
-- in that slot which the restriction admits (Alhammarret, High Arbiter's "a
-- nonland card revealed this way", CR 201.4a); Nothing offers every name.
data ChooseCardName = MkChooseCardName
  { player :: PlayerRef.PlayerRef,
    restriction :: Filter.Filter Keyword.Keyword,
    among :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
