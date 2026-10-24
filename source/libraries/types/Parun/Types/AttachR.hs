module Parun.Types.AttachR where

import qualified Parun.Types.AttachRewrite as AttachRewrite
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | The payload of Parun.Types.ReplacementEffect's AttachR arm: which
-- permanents becoming attached are intercepted, and what is done as they are.
data AttachR ability effect = MkAttachR
  { matching :: Filter.Filter Keyword.Keyword,
    rewrite :: AttachRewrite.AttachRewrite ability effect
  }
  deriving (Eq, Ord, Show)
