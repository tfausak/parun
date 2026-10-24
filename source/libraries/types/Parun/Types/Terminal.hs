module Parun.Types.Terminal where

import qualified Data.Text as Text

-- | Where a person plays: lines out, lines in.
data Terminal m = MkTerminal
  { say :: Text.Text -> m (),
    -- | The next line typed, or Nothing at the end of input.
    listen :: m (Maybe Text.Text),
    -- | Clears the screen, so the next seat cannot read what the last one saw.
    clear :: m ()
  }
