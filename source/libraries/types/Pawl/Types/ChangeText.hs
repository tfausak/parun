module Pawl.Types.ChangeText where

import qualified Data.Set as Set
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.TextWord as TextWord
import qualified Pawl.Types.WordFamily as WordFamily

-- | The payload of Pawl.Types.Effect's ChangeText arm (#1305): CR 612's text
-- change over the slot's object, replacing one word of any of these families
-- with another word of the same family -- Mind Bend's "one color word with
-- another or one basic land type with another" names two.
--
-- The forbidden set is what the chooser may NOT pick, which is why it is a set
-- of words rather than a second family.
data ChangeText = MkChangeText
  { families :: Set.Set WordFamily.WordFamily,
    forbidden :: Set.Set TextWord.TextWord,
    slot :: SlotName.SlotName,
    -- | CR 611.2a's Indefinite unless the card states one (Crystal Spray's
    -- "until end of turn").
    duration :: Duration.Duration
  }
  deriving (Eq, Ord, Show)
