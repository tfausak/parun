module Pawl.Types.Request where

import qualified Data.Text as Text
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.Question as Question

-- | One line to a client: what its seat sees, and what it is asked.
data Request = MkRequest
  { -- | Nothing before the game begins (CR 103.1's play or draw).
    view :: Maybe PlayerView.PlayerView,
    question :: Question.Question,
    -- | Why the previous answer to this question could not be read.
    problem :: Maybe Text.Text
  }
  deriving (Eq, Show)
