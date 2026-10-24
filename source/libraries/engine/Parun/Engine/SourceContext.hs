-- CR 607.2d / 109.5: the Filter.Context a source's OWN ability is matched in,
-- with every answer the board gives about that source filled in one place --
-- its host (CR 303.4b), its owner (CR 108.3), what it put onto the battlefield
-- (CR 400.7), what it exiled (CR 607.2a) and every choice it made as it entered (CR 614.1c) or while
-- resolving (CR 608.2c) -- so no position can fill one and forget another.
--
-- Not the source's power, toughness, mana value, colours or names: those are
-- projected characteristics, and this module sits below Parun.Engine.Projection,
-- whose layer fold (CR 613) builds its own contexts here.
-- Parun.Engine.Projection.sourceContext, framedBy and framedWith add them, and
-- every caller outside the fold goes through those instead.
module Parun.Engine.SourceContext where

import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.Chosen as Chosen
import qualified Parun.Types.ExileLink as ExileLink
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SourceChoices as SourceChoices

-- | Filter.contextFor framed by `source`, with every source-derived field
-- filled (framedBy).
sourceContext :: GameState.GameState -> Maybe PlayerId.PlayerId -> ObjectId.ObjectId -> Filter.Context
sourceContext gs perspective source =
  framedBy source gs (Filter.contextIn gs perspective (Just source))

-- | `context` with every source-derived field of `source` filled, its choices
-- read live through CR 608.2h's last known information (choicesOf), for the
-- abilities it has now (Game.acquisitionOf). Leaves
-- `Filter.source` alone, so a caller whose IsSource names nothing keeps that.
framedBy :: ObjectId.ObjectId -> GameState.GameState -> Filter.Context -> Filter.Context
framedBy source gs = framedWith (choicesOf (Game.acquisitionOf source gs) source gs) source gs

-- | framedBy with the choices supplied: what a stored effect baked as it began
-- (CR 608.2h), in place of the source's current ones. Every other field is
-- still read off the board. All are thunks: a filter that names none of their
-- atoms forces none of them.
framedWith :: SourceChoices.SourceChoices -> ObjectId.ObjectId -> GameState.GameState -> Filter.Context -> Filter.Context
framedWith choices source gs context =
  (withChoices choices context)
    { -- CR 608.2h / 113.7a: a source that has left still names the host it
      -- had as it left.
      Filter.sourceAttachedTo = Game.hostWithLastKnown source gs,
      -- CR 108.3 fixes an owner when the game starts, so a live read; a source
      -- the state no longer holds answers Nothing.
      Filter.sourceOwner = fmap Object.owner (Game.lookupObject source gs),
      Filter.sourceEntrants = Map.keysSet (Map.filter (== source) (GameState.enteredWith gs)),
      -- CR 607.2a: the cards in exile now (CR 400.7) linked to the source.
      Filter.sourceExiled = Map.filter ((== source) . ExileLink.source) (Map.restrictKeys (GameState.exiledWith gs) (GameState.exile gs))
    }

-- | The choices `source`'s abilities acquired as `acquisition` have made so
-- far (CR 607.5), through CR 608.2h's last known information; what a stored
-- effect bakes as it begins.
choicesOf :: Acquisition.Acquisition -> ObjectId.ObjectId -> GameState.GameState -> SourceChoices.SourceChoices
choicesOf acquisition source gs =
  SourceChoices.MkSourceChoices
    { SourceChoices.names = Maybe.fromMaybe Map.empty (Game.choiceWithLastKnown Chosen.Names acquisition source gs),
      SourceChoices.colors = Maybe.fromMaybe Set.empty (Game.choiceWithLastKnown Chosen.Colors acquisition source gs),
      SourceChoices.subtype = Game.choiceWithLastKnown Chosen.Subtype acquisition source gs
    }

-- | `context` with these choices as the source's: CR 105.2's colours, CR
-- 205.3's subtype and CR 201.4's names.
withChoices :: SourceChoices.SourceChoices -> Filter.Context -> Filter.Context
withChoices choices context =
  context
    { Filter.sourceChosenColors = SourceChoices.colors choices,
      Filter.sourceChosenSubtype = SourceChoices.subtype choices,
      Filter.sourceChosenNames = SourceChoices.names choices
    }
