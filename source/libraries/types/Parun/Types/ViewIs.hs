module Parun.Types.ViewIs where

import qualified Parun.Types.Label as Label
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.Reply as Reply
import qualified Parun.Types.View as View
import qualified Parun.Types.Zone as Zone

-- | A view of the state, rendered as JSON, equal to the expected value.
data ViewIs = MkViewIs
  { view :: View.View,
    player :: Maybe Label.Label,
    object :: Maybe Reference.Reference,
    zone :: Maybe Zone.Zone,
    is :: Reply.Reply
  }
  deriving (Eq, Ord, Show)
