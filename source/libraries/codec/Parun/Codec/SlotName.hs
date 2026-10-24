module Parun.Codec.SlotName where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.SlotName as SlotName

-- | Named in @$defs@ through 'Common.wrapper', a slot name being a domain type
-- a card author sees rather than a structural wrapper.
codec :: Codec.Codec SlotName.SlotName
codec = Common.wrapper Common.text SlotName.MkSlotName SlotName.unwrap
