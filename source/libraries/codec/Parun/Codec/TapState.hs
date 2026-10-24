module Parun.Codec.TapState where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.TapState as TapState

codec :: Codec.Codec TapState.TapState
codec = Arm.enum

-- | Tapped as true, for a document people write by hand: @"tapped": true@. Not
-- filed in @$defs@, where 'codec' already files this type.
flag :: Codec.Codec TapState.TapState
flag =
  Common.boolean
    { Codec.encode = \x -> Codec.encode Common.boolean (x == TapState.Tapped),
      Codec.decode = \value -> do
        b <- Codec.decode Common.boolean value
        pure (if b then TapState.Tapped else TapState.Untapped)
    }
