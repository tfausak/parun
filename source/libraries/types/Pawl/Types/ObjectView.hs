module Pawl.Types.ObjectView where

import qualified Data.Map.Strict as Map
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.TapState as TapState

-- | CR 400.2 / 708.2: an object as one seat sees it, its status always, its
-- characteristics only when that seat may see them, and the card behind a
-- face-down object only when that seat may look at it.
data ObjectView = MkObjectView
  { object :: ObjectId.ObjectId,
    owner :: PlayerId.PlayerId,
    controller :: Maybe PlayerId.PlayerId,
    tapped :: TapState.TapState,
    damage :: Natural.Natural,
    counters :: Map.Map (CounterKind.CounterKind Keyword.Keyword) Natural.Natural,
    attachedTo :: Maybe Recipient.Recipient,
    characteristics :: Maybe ProjectedCharacteristics.ProjectedCharacteristics,
    -- | CR 406.3 / 708.5: the card a face-down object is, for a seat that may look at it.
    face :: Maybe ProjectedCharacteristics.ProjectedCharacteristics
  }
  deriving (Eq, Show)
