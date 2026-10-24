module Parun.Codec.ShownCards where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ShownCards as ShownCards

codec :: Codec.Codec ShownCards.ShownCards
codec = Arm.enum
