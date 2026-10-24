module Parun.Codec.KeywordFamily where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.KeywordFamily as KeywordFamily

-- | Nullary tags, unlike Parun.Codec.Keyword's tagged pairs: the type is
-- payload-free, so `{"type":"Toxic"}` names the family and
-- `{"type":"Toxic","value":2}` the written instance. The two never collide,
-- because they sit under different Filter tags -- HasKeywordFamily and
-- HasKeyword.
codec :: Codec.Codec KeywordFamily.KeywordFamily
codec = Arm.enum
