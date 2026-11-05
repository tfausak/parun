module Parun.Types.TransformTrigger where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.CardName as CardName

-- | CR 701.27e: which permanent turned over, and the face it turned into.
data TransformTrigger = MkTransformTrigger
  { -- | The bearer (Howlpack Piper) or a permanent the Filter admits (Cult of
    -- the Waxing Moon), the Filter read against the characteristics the event
    -- sampled (Parun.Types.Transformed).
    permanent :: ActingPermanent.ActingPermanent,
    -- | "Transforms into [face]": the name the face it turned into must carry,
    -- which is what tells the turn to a face from the turn away from it.
    -- Nothing is any face.
    into :: Maybe CardName.CardName
  }
  deriving (Eq, Ord, Show)

-- | "Whenever this permanent transforms": the bearer, into any face. The
-- codec's defaults.
defaultValue :: TransformTrigger
defaultValue =
  MkTransformTrigger
    { permanent = ActingPermanent.Self,
      into = Nothing
    }
