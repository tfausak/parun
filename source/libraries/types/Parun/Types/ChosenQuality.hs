module Parun.Types.ChosenQuality where

import Numeric.Natural (Natural)

-- | What a choice of a quality has its chooser pick, written to the object it
-- is made for: as it enters (CR 614.1c, EntryRewrite.ChooseQuality), as it
-- becomes attached (CR 607.2d, AttachRewrite.ChooseQuality) or as it resolves
-- (CR 608.2d, Effect.ChooseQuality).
data ChosenQuality
  = -- | CR 105.4: that many different colours, written to Object.chosenColors (Painter's Servant, Persecute).
    Colors Natural
  | -- | CR 305.6: one of the five basic land types, written to Object.chosenSubtype (Convincing Mirage, Mystic Compass).
    BasicLandType
  | -- | CR 205.3m: one creature type, written to Object.chosenSubtype (Pillar of Origins).
    CreatureType
  deriving (Eq, Ord, Show)
