module Parun.Codec.TextWord where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TextWord as TextWord

-- | The word alone, tagged as Parun.Codec.Color or Parun.Codec.Subtype would tag
-- it: CR 105.1's colour words and CR 205.3's subtypes share no spelling, so the
-- tag says which family without a wrapper, and a land type written before colour
-- words were swappable decodes unchanged.
codec :: Codec.Codec TextWord.TextWord
codec =
  Arm.taggedWith
    (Common.nullary . tagOf)
    ( fmap (\c -> Arm.nullary (show c) (TextWord.ColorWord c)) [minBound :: Color.Color ..]
        <> fmap (\s -> Arm.nullary (show s) (TextWord.SubtypeWord s)) [minBound :: Subtype.Subtype ..]
    )

tagOf :: TextWord.TextWord -> String
tagOf word = case word of
  TextWord.ColorWord c -> show c
  TextWord.SubtypeWord s -> show s
