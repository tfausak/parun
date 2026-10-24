{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActivateManaAbilities where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActivateManaAbilities as ActivateManaAbilities

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's ActivateManaAbilities arm.
codec :: Codec.Codec ActivateManaAbilities.ActivateManaAbilities
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ActivateManaAbilities.filter
  player <- Fields.required "player" PlayerRef.codec ActivateManaAbilities.player
  pure
    ActivateManaAbilities.MkActivateManaAbilities
      { ActivateManaAbilities.filter = filter_,
        ActivateManaAbilities.player = player
      }
