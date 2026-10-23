module Pawl.Types.RevealCause where

import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ObjectId as ObjectId

-- | CR 701.20a: why a reveal happened. Carried by Pawl.Types.GameEvent's Revealed
-- for Pawl.Types.DiscardCause's reason -- one logged reveal answers both of the
-- questions the rules ask about it, rather than two log entries describing one
-- showing of one card.
--
-- CR 702.94a and CR 607.2h are what make the distinction load-bearing. Miracle's
-- linked triggered ability (CR 603.11) is worded "when you reveal this card THIS
-- WAY", and Rowen's "whenever you reveal a basic land card this way", so neither
-- may fire when the same card is shown by some other effect. A cause
-- on the event is how the trigger condition asks that, and it is the same shape
-- CR 702.29d needed one rule over.
data RevealCause
  = -- | CR 701.20a's plain reveal, whatever asked for it: a search's "reveal it",
    -- an activation cost paid from a hidden zone, a library's top card turned
    -- face up.
    Ordinary
  | -- | CR 702.94a / CR 121.9 / 702.94b: revealed from a hand AS IT WAS DRAWN,
    -- under the miracle ability with this cost, whose linked trigger alone it
    -- fires (CR 607.2h).
    ForMiracle (Cost.Cost Keyword.Keyword)
  | -- | CR 603.11 / 607.2h: revealed from a hand as it was drawn, under the
    -- draw-time reveal (PlayerEffect.RevealsFirstDraw) of this object, whose
    -- linked triggers alone it fires (Rowen).
    AsDrawnUnder ObjectId.ObjectId
  | -- | CR 708.9: a face-down permanent, revealed by its owner as it leaves the
    -- battlefield.
    LeavingFaceDown
  | -- | CR 708.9: a face-down component of a face-up merged permanent, revealed
    -- by its owner as the permanent leaves the battlefield, its owner leaves the
    -- game, or the game ends. Not LeavingFaceDown, since the permanent itself
    -- is face up.
    LeavingFaceDownComponent
  | -- | CR 708.9: a face-down spell, revealed by its owner as it leaves the stack
    -- for anywhere but the battlefield, or as its owner leaves the game.
    FaceDownSpell
  deriving (Eq, Ord, Show)
