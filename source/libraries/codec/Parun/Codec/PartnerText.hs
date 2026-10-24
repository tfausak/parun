module Parun.Codec.PartnerText where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PartnerText as PartnerText

-- | Nullary tags, Parun.Codec.AbilityKind's shape: Arm.enum derives the arm
-- list from the type.
codec :: Codec.Codec PartnerText.PartnerText
codec = Arm.enum
