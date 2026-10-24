module Parun.Extra.Word64 where

import qualified Data.Word as Word
import qualified Numeric.Natural as Natural
import qualified Parun.Extra.Integer as Integer

-- | Converts a 'Word.Word64' into a 'Natural.Natural'. This is total: every
-- 'Word.Word64' is a natural number.
toNatural :: Word.Word64 -> Natural.Natural
toNatural = Integer.toNaturalSaturating . toInteger
