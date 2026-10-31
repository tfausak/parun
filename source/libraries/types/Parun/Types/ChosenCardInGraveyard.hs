module Parun.Types.ChosenCardInGraveyard where

import qualified Parun.Types.Chooser as Chooser
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ZoneScope as ZoneScope

-- | CR 404.1 with a choice: who picks, whose graveyards are looked at, what
-- may be picked, and HOW MANY.

-- The Chooser and the ZoneScope are different questions and are easy to
-- confuse -- "target opponent chooses a card in YOUR graveyard" names two
-- different seats -- so they are named rather than positional.
--
-- The COUNT is per CHOOSER: Fall of the Thran's "each player returns two land
-- cards from their graveyard" is two each, and Liliana, the Necromancer's "up
-- to two creature cards from graveyards" any number up to two. An exact count
-- names DISTINCT cards, so each card picked is dropped from the candidates
-- before the next ask (CR 608.2d), and CR 609.3 covers the shortfall -- a
-- graveyard holding fewer matches than the count gives what it has.
data ChosenCardInGraveyard = MkChosenCardInGraveyard
  { chooser :: Chooser.Chooser,
    players :: ZoneScope.ZoneScope,
    filter :: Filter.Filter Keyword.Keyword,
    count :: HowMany.HowMany
  }
  deriving (Eq, Ord, Show)
