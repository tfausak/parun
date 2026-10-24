module Parun.Types.EntryOption where

import qualified Data.Set as Set
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Subtype as Subtype

-- | CR 208.2b / 614.1c: one of the shapes an "as this creature enters, it becomes
-- your choice of ..." ability offers. Primal Plasma's three are (3,3,{}),
-- (2,2,{Flying}) and (1,6,{Defender}); Primal Clay's third adds the Wall
-- creature type "in addition to its other types".
--
-- The keywords and subtypes are UNIONED into the object's copiable snapshot,
-- never assigned over it, per Primal Plasma's Gatherer ruling: a Clone of a
-- 2/2-flying Plasma that picks the third option is 1/6 with flying AND
-- defender. P/T is SET instead (CR 707.2).
data EntryOption = MkEntryOption
  { power :: Integer,
    toughness :: Integer,
    keywords :: Set.Set Keyword.Keyword,
    subtypes :: Set.Set Subtype.Subtype
  }
  deriving (Eq, Ord, Show)
