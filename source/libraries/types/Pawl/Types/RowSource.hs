module Pawl.Types.RowSource where

import qualified Pawl.Types.AbilityName as AbilityName
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.SourceChoices as SourceChoices

-- | CR 113.7: the source of a player-effect row, as
-- Pawl.Engine.PlayerEffect.applying hands it to every consumer.
--
-- Runtime-only and never written: no codec, because nothing stores one.
data RowSource = MkRowSource
  { -- | The object the row came from, Nothing for a row no object printed.
    object :: Maybe ObjectId.ObjectId,
    -- | CR 608.2h: a stored row's choices, baked as it began
    -- (Pawl.Types.ActivePlayerEffect.choices). Nothing for a printed row,
    -- whose choices CR 604.2 reads off the permanent live.
    choices :: Maybe SourceChoices.SourceChoices,
    -- | CR 607.5: the name of the ability a stored row came from
    -- (Pawl.Types.ActivePlayerEffect.ability), which pairs its references to
    -- exiled cards. Nothing for a printed row, a static ability no object
    -- acquires from an exiled card.
    ability :: Maybe AbilityName.AbilityName
  }
  deriving (Eq, Ord, Show)
