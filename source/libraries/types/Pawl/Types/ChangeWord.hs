module Pawl.Types.ChangeWord where

import qualified Pawl.Types.TextWord as TextWord

-- | The payload of Pawl.Types.Modification's ChangeWord arm (#1305): CR 612's
-- text change, one word replaced by another of its family -- Artificial
-- Evolution's creature type, Sleight of Mind's colour word. Also the scenario
-- move answering the swap.
data ChangeWord = MkChangeWord
  { from :: TextWord.TextWord,
    to :: TextWord.TextWord
  }
  deriving (Eq, Ord, Show)
