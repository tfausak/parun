module Parun.Codec.PrintingId where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.PrintingId as PrintingId

-- | An index into GameState.printings. Encoded as a Natural rather than a bare
-- Integer, so a negative wire value cannot go through a partial fromInteger.
codec :: Codec.Codec PrintingId.PrintingId
codec = Common.wrapper Common.natural PrintingId.MkPrintingId PrintingId.unwrap
