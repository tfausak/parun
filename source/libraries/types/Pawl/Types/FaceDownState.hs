module Pawl.Types.FaceDownState where

import qualified Data.Set as Set
import qualified Pawl.Types.FaceDownCharacteristics as FaceDownCharacteristics
import qualified Pawl.Types.FaceDownReason as FaceDownReason
import qualified Pawl.Types.TurnUpEvent as TurnUpEvent

-- | CR 708.2: the whole of what the game knows about a face-down object -- the
-- ability or rules that ALLOWED it to be face down (CR 708.6), and the
-- characteristics that allower LISTED for it, beside the one replacement an
-- allower has scoped to the status (`turnsUpBefore`). Morph, manifest and Backslide
-- list nothing and carry 'FaceDownCharacteristics.defaultValue'; disguise, cloak
-- and an entry rider that lists its own carry something else.
--
-- The reason is first because CR 708.2's own sentence puts it first: the listed
-- characteristics are "those listed by the ability or rules that allowed the
-- spell or permanent to be face down", so the list is the allower's and not the
-- other way round.
data FaceDownState ability = MkFaceDownState
  { reason :: FaceDownReason.FaceDownReason,
    listed :: FaceDownCharacteristics.FaceDownCharacteristics ability,
    -- | CR 614.1a: the events the allower turns this object face up before,
    -- empty for every allower but Illusionary Mask's. On the STATUS because the
    -- effect's own words scope it there -- "the creature that spell becomes"
    -- and "has not been turned face up" -- so turning face up and CR 400.7's
    -- new incarnation both end it, as they end the status, and a later turn
    -- face down (Ixidron) starts a status without it.
    turnsUpBefore :: Set.Set TurnUpEvent.TurnUpEvent
  }
  deriving (Eq, Ord, Show)

-- | CR 708.2a's list, named by the rule that allowed it: what a producer that
-- specifies no characteristics of its own carries. Morph, manifest and
-- Effect.TurnFaceDown's Backslide all take this; the ones that do not are
-- disguise and cloak ('FaceDownCharacteristics.disguisedValue') and an entry
-- that lists its own (Pawl.Types.EntryRiders' faceDown). A hidden agenda's
-- conspiracy lists less still: CR 315.5b gives it no characteristics at all.
defaultFor :: FaceDownReason.FaceDownReason -> FaceDownState ability
defaultFor r = MkFaceDownState {reason = r, listed = listing, turnsUpBefore = Set.empty}
  where
    listing = case r of
      FaceDownReason.HiddenAgenda -> FaceDownCharacteristics.noneValue
      _ -> FaceDownCharacteristics.defaultValue
