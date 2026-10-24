module Parun.Types.PlayerControl where

import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 723: one player being controlled by another -- who decides for them, for
-- how long, and what rule 723.7's restriction says they may do.
--
-- Keyed per controlled player in GameState.control. A record and not a bare
-- Decider because rule 723.2's control is scoped to one resolution while rule
-- 723.1's runs for a turn, and rule 723.3 lets neither assume the controlled
-- player is the active one; see #881.
data PlayerControl = MkPlayerControl
  { decider :: Decider.Decider,
    duration :: ControlDuration.ControlDuration,
    -- | CR 723.7's restriction, in the one form a card prints it: Word of
    -- Command's "the player can activate mana abilities only if they're from
    -- lands that player controls". Read by Parun.Engine.Mana.manaSourcesGiven.
    --
    -- A Bool for Parun.Types.CastOffer's reason -- it is the presence or absence
    -- of one printed clause, and rule 723.7 is open-ended enough that a second
    -- restriction would be a second field rather than another value of this one.
    -- False is rule 723.1's unrestricted control.
    manaFromLandsOnly :: Bool,
    -- | When the controlling effect was created, which is what CR 723.1a's
    -- "the last one to be created is the one that works" orders by -- not when
    -- its row took hold. A static ability's effect is as old as its permanent
    -- (CR 613.7a), so an Opposition Agent already on the battlefield loses to a
    -- Mindslaver activated after it.
    timestamp :: Timestamp.Timestamp
  }
  deriving (Eq, Ord, Show)
