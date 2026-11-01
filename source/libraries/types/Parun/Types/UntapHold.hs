module Parun.Types.UntapHold where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Numeric.Natural as Natural
import qualified Parun.Types.CardType as CardType

-- | CR 502.3: how an untap rule bears on the untap step's untap of the
-- permanents it names -- an effect's "can't" (CR 101.2), the active player's
-- own determination of "which permanents they control will untap", a card type
-- they choose, or an untap in a step that is not their controller's. Never
-- alone reaches past the untap step, to every untap (CR 701.26b).
--
-- Not Parun.Types.Optionality: that names WHO a printed "may" asks, and CR
-- 502.3 has already fixed who determines the untap, so a seat here could only
-- disagree with the rule.
data UntapHold
  = -- | It doesn't untap: "doesn't untap during its controller's untap step"
    -- (CR 101.2, CR 502.3).
    Forbidden
  | -- | Its controller may leave it tapped: "You may choose not to untap this
    -- artifact during your untap step" (CR 502.3).
    Elective
  | -- | No more than this many of them untap, the active player choosing which:
    -- "players can't untap more than two permanents during their untap steps"
    -- (CR 101.2, CR 502.3).
    AtMost Natural.Natural
  | -- | It untaps during each other player's untap step too: "Untap all
    -- permanents you control during each other player's untap step" (Seedborn
    -- Muse; CR 502.3, 613.11).
    DuringOthersSteps
  | -- | Only those of the card type the active player chooses from these untap:
    -- "each player chooses artifact, creature, or land during their untap step.
    -- That player can untap only permanents of the chosen type this step"
    -- (Storage Matrix; CR 101.2, 205.2a, 502.3).
    OfChosenType (NonEmpty.NonEmpty CardType.CardType)
  | -- | It can't become untapped at all (Blossombind; CR 101.2, 614.17, 701.26b).
    Never
  deriving (Eq, Ord, Show)
