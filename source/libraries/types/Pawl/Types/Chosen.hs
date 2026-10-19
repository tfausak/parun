{-# LANGUAGE GADTs #-}

module Pawl.Types.Chosen where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.PlayerChoice as PlayerChoice
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Subtype as Subtype

-- | Which of an object's per-acquisition choices (CR 607.2d / 607.5), indexed
-- by what one acquisition's entry holds: the field Pawl.Engine.Game reads and
-- writes on the live object and on its last known information alike.
data Chosen a where
  -- | CR 105.1: the chosen colours (Object.chosenColors).
  Colors :: Chosen (Set.Set Color.Color)
  -- | CR 205.3: the chosen subtype (Object.chosenSubtype).
  Subtype :: Chosen Subtype.Subtype
  -- | CR 201.4: the chosen card names, by chooser (Object.chosenNames).
  Names :: Chosen (Map.Map PlayerId.PlayerId CardName.CardName)
  -- | CR 614.1c / 702.174a: the chosen players, by choice (Object.chosenPlayers).
  Players :: Chosen (Map.Map PlayerChoice.PlayerChoice PlayerId.PlayerId)
