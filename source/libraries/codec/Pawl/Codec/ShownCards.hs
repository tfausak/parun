module Pawl.Codec.ShownCards where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ShownCards as ShownCards

codec :: Codec.Codec ShownCards.ShownCards
codec = Arm.enum
