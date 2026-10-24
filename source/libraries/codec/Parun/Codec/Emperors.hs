module Parun.Codec.Emperors where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.TeamId as TeamId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Emperors as Emperors

-- | Keyed by a TeamId, a Natural newtype, so it takes 'Common.naturalMap' --
-- Parun.Codec.Teams' shape with key and value swapped.
codec :: Codec.Codec Emperors.Emperors
codec = Common.wrapper (Common.naturalMap TeamId.codec PlayerId.codec) Emperors.MkEmperors Emperors.unwrap
