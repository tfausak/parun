module Pawl.Types.StickerContent where

import qualified Data.Text as Text
import qualified Pawl.Types.AbilitySticker as AbilitySticker
import qualified Pawl.Types.PowerToughnessSticker as PowerToughnessSticker

-- | CR 123.6-123.9: what one sticker says, by its kind.
data StickerContent
  = -- | CR 123.6: a name sticker's word.
    Name Text.Text
  | -- | CR 123.7.
    Ability AbilitySticker.AbilitySticker
  | -- | CR 123.8.
    PowerToughness PowerToughnessSticker.PowerToughnessSticker
  | -- | CR 123.9: an art sticker carries nothing.
    Art
  deriving (Eq, Ord, Show)
