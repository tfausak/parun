module Parun.Types.EntryR where

import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.ReplacementEffect's EntryR arm (#1305): which
-- objects entering the battlefield are intercepted, and how their entry is
-- rewritten.
--
-- Parametric in the EFFECT and the ABILITY, passing Parun.Types.EntryRewrite's
-- parameters through for the reason Parun.Types.DamageR gives.
data EntryR ability effect = MkEntryR
  { matching :: Filter.Filter Keyword.Keyword,
    rewrite :: EntryRewrite.EntryRewrite ability effect
  }
  deriving (Eq, Ord, Show)
