module Pawl.Types.AttachR where

import qualified Pawl.Types.AttachRewrite as AttachRewrite
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | The payload of Pawl.Types.ReplacementEffect's AttachR arm: which
-- permanents becoming attached are intercepted, and what is done as they are.
data AttachR ability effect = MkAttachR
  { matching :: Filter.Filter Keyword.Keyword,
    rewrite :: AttachRewrite.AttachRewrite ability effect
  }
  deriving (Eq, Ord, Show)
