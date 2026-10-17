module Pawl.Types.Question where

import qualified Data.Text as Text
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Reply as Reply

-- | CR 723.4: a prompt as the seat answering it is shown it.
data Question = MkQuestion
  { seat :: PlayerId.PlayerId,
    -- | The prompt's constructor name.
    kind :: Text.Text,
    -- | What the prompt offers, in its answer's vocabulary.
    offer :: Reply.Reply
  }
  deriving (Eq, Show)
