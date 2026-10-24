module Parun.Codec.AbilityKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AbilityKind as AbilityKind

-- | Nullary tags, Parun.Codec.KeywordFamily's shape and for its reason: the type
-- is payload-free, so `{"type":"ManaAbility"}` is the whole of it, and Arm.enum
-- derives the arm list from the type rather than leaving a new constructor to
-- compile with no arm.
codec :: Codec.Codec AbilityKind.AbilityKind
codec = Arm.enum
