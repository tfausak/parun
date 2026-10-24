-- | CR 701.62, manifest dread: "Look at the top two cards of your library.
-- Manifest one of them, then put the cards you looked at that were not
-- manifested this way into your graveyard", and the whole of the keyword
-- action.
--
-- Parun.Engine.Cloak's sibling, on the same ground: rule 701 is a keyword-action
-- rule, so the procedure lives in the engine, and Parun.Engine.Resolve.Effect's
-- Effect.ManifestDread arm calls in without saying which effect it is.
--
-- An opcode rather than three instructions because CR 701.62b's trigger watches
-- the PROCESS: it fires once, after the whole of it, even when some or all of it
-- was impossible -- which no reader of the moves inside it can see -- and
-- Paranormal Analyst's "a card you put into your graveyard this way" reads that
-- same process back.
module Parun.Engine.ManifestDread where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.FaceDownCharacteristics as FaceDownCharacteristics
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.FaceDownState as FaceDownState
import Parun.Types.Game (Game)
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.ManifestedDread as ManifestedDread
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Zone as Zone

-- | CR 701.40a's face-down 2\/2, the listing being the rule's and never a
-- card's. A settled count rather than a Quantity, Parun.Engine.Cloak.riders'
-- reason: the rule states no counters.
riders :: EntryRiders.EntryRiders Natural ability
riders =
  EntryRiders.defaultValue
    { EntryRiders.faceDown =
        Just
          FaceDownState.MkFaceDownState
            { FaceDownState.reason = FaceDownReason.Manifested,
              FaceDownState.listed = FaceDownCharacteristics.defaultValue,
              FaceDownState.turnsUpBefore = Set.empty
            }
    }

-- | CR 701.62a performed by this player on their own library, on behalf of the
-- object `source`.
--
-- Which card is manifested is the player's choice (CR 608.2d), asked as
-- Prompt.ChooseCardFromAmong through Game.chooseAmong; one card is no choice
-- (the Paranormal Analyst ruling: a one-card library manifests that card) and
-- none is nothing to do. Both cards are looked at first (CR 701.20e), so the
-- choice is made among cards already seen.
--
-- "Not manifested this way" is read off the board after the manifest: a looked-at
-- card still in the library is one the manifest did not take, which is CR
-- 701.40f's refusal (Grafdigger's Cage) as well as the card that was never
-- chosen. A card a CR 614 replacement sent elsewhere has left the library and is
-- put nowhere.
--
-- The event is recorded unconditionally, CR 701.62b, carrying the cards the
-- graveyard move left IN a graveyard -- a replacement that sends one elsewhere
-- (Leyline of the Void) leaves it out, since it was not put there.
manifestDread :: ObjectId -> PlayerId -> Game ()
manifestDread source pid = do
  gs <- State.get
  let looked = take 2 (Game.zoneMembers Zone.Library pid gs)
  Monad.mapM_ (Event.look pid) looked
  chosen <- Game.chooseAmong (\decider asked -> Prompt.ChooseCardFromAmong decider asked source) pid looked
  Monad.forM_ chosen $ \card ->
    Event.simultaneously (Monad.void (Event.changeZoneEntering card Zone.Battlefield LibraryPosition.defaultValue riders (Just pid)))
  after <- State.get
  let stillInLibrary oid = fmap Object.zone (Game.lookupObject oid after) == Just Zone.Library
      rest = filter stillInLibrary looked
  arrived <- if null rest then pure [] else Event.changeZonesTogether (fmap (\oid -> (oid, Zone.Graveyard)) rest)
  landed <- State.get
  let inGraveyard oid = fmap Object.zone (Game.lookupObject oid landed) == Just Zone.Graveyard
      binned = Seq.fromList (concatMap (filter inGraveyard . Foldable.toList) arrived)
  State.modify' (Event.recordEvent (GameEvent.ManifestedDread (ManifestedDread.MkManifestedDread pid binned)))
